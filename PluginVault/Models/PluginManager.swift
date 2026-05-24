import Foundation
import SwiftUI
import Combine
import Darwin

class PluginManager: ObservableObject {
    struct PluginRenameFailure {
        let plugin: Plugin
        let error: Error
    }

    struct PluginRenameSummary {
        var changedCount = 0
        var failures: [PluginRenameFailure] = []
    }

    private enum PluginRenameError: LocalizedError {
        case differentParentFolders
        case invalidVaultRename
        case destinationExists(String)
        case privilegedRenameFailed(String)

        var errorDescription: String? {
            switch self {
            case .differentParentFolders:
                return "PluginVault refused a rename outside the plug-in's current folder."
            case .invalidVaultRename:
                return "PluginVault only adds or removes the .vault suffix."
            case .destinationExists(let path):
                return "Cannot rename because this already exists: \(path)"
            case .privilegedRenameFailed(let details):
                return details.isEmpty ? "The administrator rename did not complete." : details
            }
        }
    }

    @Published var plugins: [Plugin] = []
    @Published var allTags: [String] = []
    @Published var activeTags: Set<String> = []
    @Published var currentFilter: PluginFilter = .all
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var skippedPluginDirs: [String] = []
    @Published var diskAccessStatusMessage: String = "No blocked plug-in folders detected."
    
    // Request flag to open the Collection Inspector from menu/toolbar
    @Published var requestOpenCollectionInspector: Bool = false
    
    // Collections
    @Published var collections: [Collection] = []
    
    // Settings
    @Published var highlightColor: String = "black"
    @Published var textScale: Double = 1.0
    
    private static let builtInPluginDirs: [String] = [
        "/Library/Audio/Plug-Ins/Components",
        "/Library/Audio/Plug-Ins/VST",
        "/Library/Audio/Plug-Ins/VST3",
        "/Library/Audio/Plug-Ins/AAX",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/Components",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/VST",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/VST3",
    ]

    static var defaultPluginDirs: [String] {
        pluginDirectoryOverride ?? builtInPluginDirs
    }
    
    private let pluginExtensions = [".component", ".vst", ".vst3", ".aaxplugin"]
    private let dbPath: URL
    private let collectionsPath: URL
    private let settingsDefaults: UserDefaults
    
    var filteredPlugins: [Plugin] {
        var result = plugins
        
        switch currentFilter {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isVaulted }
        case .vaulted:
            result = result.filter { $0.isVaulted }
        case .tag(let tag):
            result = result.filter { $0.tags.contains(tag) }
        case .collection(let id):
            if let collection = collections.first(where: { $0.id == id }) {
                let ids = Set(collection.pluginIDs)
                result = result.filter { ids.contains($0.originalPath) }
            }
        }
        
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { plugin in
                plugin.name.lowercased().contains(query) ||
                plugin.pluginType.rawValue.lowercased().contains(query) ||
                plugin.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var activeCount: Int { plugins.filter { !$0.isVaulted }.count }
    var vaultedCount: Int { plugins.filter { $0.isVaulted }.count }
    
    init() {
        let appFolder: URL
        let dataDirectoryOverride = Self.dataDirectoryOverride
        if let dataDirectoryOverride {
            appFolder = dataDirectoryOverride
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            appFolder = appSupport.appendingPathComponent("PluginVault", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.dbPath = appFolder.appendingPathComponent("database.json")
        self.collectionsPath = appFolder.appendingPathComponent("collections.json")
        if let dataDirectoryOverride {
            self.settingsDefaults = Self.isolatedSettingsDefaults(for: dataDirectoryOverride)
        } else {
            self.settingsDefaults = .standard
        }
        loadSettings()
        loadDatabase()
        loadCollections()
        scanPlugins()
    }

    private static var pluginDirectoryOverride: [String]? {
        if let value = launchArgumentValue(for: "--plugin-dirs") ??
            ProcessInfo.processInfo.environment["PLUGINVAULT_PLUGIN_DIRS"] {
            let dirs = value
                .split(separator: ":", omittingEmptySubsequences: true)
                .map(String.init)
            return dirs.isEmpty ? nil : dirs
        }
        return nil
    }

    private static var dataDirectoryOverride: URL? {
        if let value = launchArgumentValue(for: "--data-dir") ??
            ProcessInfo.processInfo.environment["PLUGINVAULT_DATA_DIR"] {
            return URL(fileURLWithPath: value, isDirectory: true)
        }
        return nil
    }

    private static func launchArgumentValue(for flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: flag) else { return nil }
        let valueIndex = args.index(after: index)
        guard args.indices.contains(valueIndex) else { return nil }
        return args[valueIndex]
    }

    private static func isolatedSettingsDefaults(for dataDirectory: URL) -> UserDefaults {
        let allowed = CharacterSet.alphanumerics
        let suffix = dataDirectory.path.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "_" }
            .joined()
        return UserDefaults(suiteName: "pluginvault.PluginVault.test.\(suffix)") ?? .standard
    }
    
    private func loadSettings() {
        highlightColor = settingsDefaults.string(forKey: "highlightColor") ?? "black"
        let savedScale = settingsDefaults.double(forKey: "textScale")
        textScale = savedScale == 0 ? 1.0 : savedScale
    }
    
    func saveSettings() {
        settingsDefaults.set(highlightColor, forKey: "highlightColor")
        settingsDefaults.set(textScale, forKey: "textScale")
    }
    
    private func loadDatabase() {
        guard FileManager.default.fileExists(atPath: dbPath.path) else { return }
        do {
            let data = try Data(contentsOf: dbPath)
            let decoded = try JSONDecoder().decode([Plugin].self, from: data)
            var pluginDict: [String: Plugin] = [:]
            for plugin in decoded {
                pluginDict[plugin.originalPath] = plugin
            }
            for i in plugins.indices {
                if let saved = pluginDict[plugins[i].originalPath] {
                    plugins[i].tags = saved.tags
                }
            }
        } catch {
            print("Failed to load database: \(error)")
        }
    }
    
    private func saveDatabase() {
        do {
            let data = try JSONEncoder().encode(plugins)
            try data.write(to: dbPath)
        } catch {
            print("Failed to save database: \(error)")
        }
    }
    
    func scanPlugins() {
        isLoading = true
        statusMessage = "Scanning..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var foundPlugins: [Plugin] = []
            var skippedDirs: [String] = []
            var existingPluginPaths: [String: Plugin] = [:]
            
            for plugin in self.plugins {
                existingPluginPaths[plugin.originalPath] = plugin
            }
            
            for dir in Self.defaultPluginDirs {
                guard FileManager.default.fileExists(atPath: dir) else { continue }
                
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: dir)
                    
                    for item in contents {
                        let itemPath = (dir as NSString).appendingPathComponent(item)
                        var isDir: ObjCBool = false
                        
                        guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir),
                              isDir.boolValue else { continue }
                        
                        let itemLower = item.lowercased()
                        let vaultSuffix = Plugin.recognizedVaultSuffix(in: item)
                        let isVaulted = vaultSuffix != nil
                        let nameToCheck = vaultSuffix.map { String(itemLower.dropLast($0.count)) } ?? itemLower
                        
                        guard self.pluginExtensions.contains(where: { nameToCheck.hasSuffix($0) }) else { continue }
                        
                        let pluginType = self.getPluginType(from: itemPath)
                        var displayName = item
                        
                        if let vaultSuffix {
                            displayName = String(displayName.dropLast(vaultSuffix.count))
                        }
                        
                        for ext in self.pluginExtensions {
                            if displayName.lowercased().hasSuffix(ext) {
                                displayName = String(displayName.dropLast(ext.count))
                                break
                            }
                        }
                        
                        let originalPath = Plugin.removingVaultSuffix(from: itemPath)
                        
                        let finderTags = self.getFinderTags(for: itemPath)
                        
                        if var existing = existingPluginPaths[originalPath] {
                            existing.path = itemPath
                            existing.isVaulted = isVaulted
                            let mergedTags = Array(Set(existing.tags + finderTags))
                            existing.tags = mergedTags
                            foundPlugins.append(existing)
                        } else {
                            let plugin = Plugin(
                                name: displayName,
                                path: itemPath,
                                pluginType: pluginType,
                                isVaulted: isVaulted,
                                tags: finderTags
                            )
                            foundPlugins.append(plugin)
                        }
                    }
                } catch {
                    if self.isPermissionError(error) {
                        skippedDirs.append(dir)
                    } else {
                        print("Error scanning \(dir): \(error)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.plugins = foundPlugins
                self.skippedPluginDirs = skippedDirs
                self.updateAllTags()
                self.saveDatabase()
                self.isLoading = false
                if skippedDirs.isEmpty {
                    self.diskAccessStatusMessage = "No blocked plug-in folders detected."
                    self.statusMessage = "\(foundPlugins.count) plugins"
                } else {
                    let folderWord = skippedDirs.count == 1 ? "folder" : "folders"
                    self.diskAccessStatusMessage = "macOS blocked \(skippedDirs.count) plug-in \(folderWord). Open Full Disk Access, add PluginVault, then scan again."
                    self.showAlertMessage("Some plug-in folders could not be scanned. Open Full Disk Access in System Settings, add PluginVault, then scan again.")
                }
            }
        }
    }

    func openFullDiskAccessSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy"
        ]
        
        for value in urls {
            guard let url = URL(string: value) else { continue }
            if NSWorkspace.shared.open(url) {
                statusMessage = "Opened Full Disk Access settings"
                return
            }
        }
        
        showAlertMessage("Open System Settings > Privacy & Security > Full Disk Access, add PluginVault, then relaunch the app.")
    }

    private func isPermissionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain {
            return nsError.code == NSFileReadNoPermissionError ||
                nsError.code == NSFileWriteNoPermissionError
        }
        
        if nsError.domain == NSPOSIXErrorDomain {
            return nsError.code == Int(EACCES) || nsError.code == Int(EPERM)
        }
        
        return false
    }
    
    private func getPluginType(from path: String) -> PluginType {
        let pathLower = path.lowercased()
        if pathLower.contains(".component") || pathLower.contains("/components") {
            return .au
        } else if pathLower.contains(".vst3") || pathLower.contains("/vst3") {
            return .vst3
        } else if pathLower.contains(".vst") || pathLower.contains("/vst/") {
            return .vst
        } else if pathLower.contains(".aaxplugin") || pathLower.contains("/aax") {
            return .aax
        }
        return .unknown
    }
    
    private func updateAllTags() {
        var tags = Set<String>()
        for plugin in plugins {
            tags.formUnion(plugin.tags)
        }
        allTags = tags.sorted()
    }
    
    private func getFinderTags(for path: String) -> [String] {
        let url = URL(fileURLWithPath: path)
        do {
            let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
            return resourceValues.tagNames ?? []
        } catch {
            return []
        }
    }
    
    private func setFinderTags(_ tags: [String], for path: String) -> Bool {
        let url = NSURL(fileURLWithPath: path)
        do {
            try url.setResourceValue(tags, forKey: .tagNamesKey)
            return true
        } catch {
            print("Failed to set Finder tags: \(error)")
            return false
        }
    }

    private func renamePluginBundle(from sourcePath: String, to destinationPath: String) throws {
        try validateVaultRename(from: sourcePath, to: destinationPath)

        let result = sourcePath.withCString { source in
            destinationPath.withCString { destination in
                Darwin.rename(source, destination)
            }
        }

        if result == 0 {
            return
        }

        let errorNumber = errno
        let message = String(cString: strerror(errorNumber))
        let error = NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(errorNumber),
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        guard isPermissionError(error) else { throw error }
        try renamePluginBundleWithAdministratorPrivileges(from: sourcePath, to: destinationPath)
    }

    private func validateVaultRename(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL
        let destinationURL = URL(fileURLWithPath: destinationPath).standardizedFileURL

        guard sourceURL.deletingLastPathComponent().path == destinationURL.deletingLastPathComponent().path else {
            throw PluginRenameError.differentParentFolders
        }

        let sourceName = sourceURL.lastPathComponent
        let destinationName = destinationURL.lastPathComponent
        let addsVaultSuffix = destinationName == sourceName + Plugin.vaultSuffix
        let removesVaultSuffix = Plugin.recognizedVaultSuffixes.contains { suffix in
            sourceName.lowercased().hasSuffix(suffix.lowercased()) &&
                destinationName == String(sourceName.dropLast(suffix.count))
        }

        guard addsVaultSuffix || removesVaultSuffix else {
            throw PluginRenameError.invalidVaultRename
        }

        if FileManager.default.fileExists(atPath: destinationPath) {
            throw PluginRenameError.destinationExists(destinationPath)
        }
    }

    private func renamePluginBundleWithAdministratorPrivileges(from sourcePath: String, to destinationPath: String) throws {
        let command = "if [ -e \(shellQuoted(destinationPath)) ]; then echo \(shellQuoted("Cannot rename because the destination already exists.")) >&2; exit 73; fi; /bin/mv \(shellQuoted(sourcePath)) \(shellQuoted(destinationPath))"
        let script = "do shell script \(appleScriptStringLiteral(command)) with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let details = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw PluginRenameError.privilegedRenameFailed(details)
        }
    }

    private func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func appleScriptStringLiteral(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        + "\""
    }

    @discardableResult
    private func setPluginVaulted(_ plugin: Plugin, vaulted: Bool) throws -> String {
        let currentPath = plugin.path
        let newPath = vaulted ? plugin.vaultedPath : plugin.originalPath

        try renamePluginBundle(from: currentPath, to: newPath)

        if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
            plugins[index].path = newPath
            plugins[index].isVaulted = vaulted
        }

        return newPath
    }
    
    func vaultPlugin(_ plugin: Plugin) {
        guard !plugin.isVaulted else {
            showAlertMessage("Plugin is already vaulted")
            return
        }
        do {
            try setPluginVaulted(plugin, vaulted: true)
            saveDatabase()
            statusMessage = "Vaulted: \(plugin.name)"
        } catch {
            showAlertMessage(permissionAwareMessage(action: "vault", error: error))
        }
    }
    
    func unvaultPlugin(_ plugin: Plugin) {
        guard plugin.isVaulted else {
            showAlertMessage("Plugin is not vaulted")
            return
        }
        do {
            try setPluginVaulted(plugin, vaulted: false)
            saveDatabase()
            statusMessage = "Restored: \(plugin.name)"
        } catch {
            showAlertMessage(permissionAwareMessage(action: "unvault", error: error))
        }
    }
    
    func toggleVault(_ plugin: Plugin) {
        if plugin.isVaulted {
            unvaultPlugin(plugin)
        } else {
            vaultPlugin(plugin)
        }
    }
    
    @discardableResult
    func vaultUntagged() -> PluginRenameSummary {
        let untagged = plugins.filter { $0.tags.isEmpty && !$0.isVaulted }
        guard !untagged.isEmpty else {
            showAlertMessage("No untagged plugins to vault")
            return PluginRenameSummary()
        }
        var summary = PluginRenameSummary()
        for plugin in untagged {
            do {
                try setPluginVaulted(plugin, vaulted: true)
                summary.changedCount += 1
            } catch {
                summary.failures.append(PluginRenameFailure(plugin: plugin, error: error))
            }
        }
        saveDatabase()
        showAlertMessage(renameSummaryMessage(
            successMessage: "Vaulted \(summary.changedCount) untagged plugins",
            failures: summary.failures
        ))
        return summary
    }
    
    @discardableResult
    func unvaultAll(showAlert: Bool = true) -> PluginRenameSummary {
        let vaulted = plugins.filter { $0.isVaulted }
        guard !vaulted.isEmpty else {
            if showAlert {
                showAlertMessage("No vaulted plugins to restore")
            }
            return PluginRenameSummary()
        }
        var summary = PluginRenameSummary()
        for plugin in vaulted {
            do {
                try setPluginVaulted(plugin, vaulted: false)
                summary.changedCount += 1
            } catch {
                summary.failures.append(PluginRenameFailure(plugin: plugin, error: error))
            }
        }
        saveDatabase()
        if showAlert {
            showAlertMessage(renameSummaryMessage(
                successMessage: "Restored \(summary.changedCount) plugins",
                failures: summary.failures
            ))
        }
        return summary
    }
    
    func applyActiveTagFilter() {
        guard !activeTags.isEmpty else {
            showAlertMessage("No tags selected - will unvault all")
            unvaultAll()
            return
        }
        var vaultedCount = 0
        var unvaultedCount = 0
        var failures: [PluginRenameFailure] = []
        
        for plugin in plugins {
            let hasActiveTag = !Set(plugin.tags).isDisjoint(with: activeTags)
            
            if hasActiveTag && plugin.isVaulted {
                do {
                    try setPluginVaulted(plugin, vaulted: false)
                    unvaultedCount += 1
                } catch {
                    failures.append(PluginRenameFailure(plugin: plugin, error: error))
                }
            } else if !hasActiveTag && !plugin.isVaulted {
                do {
                    try setPluginVaulted(plugin, vaulted: true)
                    vaultedCount += 1
                } catch {
                    failures.append(PluginRenameFailure(plugin: plugin, error: error))
                }
            }
        }
        saveDatabase()
        showAlertMessage(renameSummaryMessage(
            successMessage: "Vaulted \(vaultedCount), restored \(unvaultedCount)",
            failures: failures
        ))
    }
    
    func addTag(_ tag: String, to plugin: Plugin) {
        guard !tag.isEmpty else { return }
        if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
            if !plugins[index].tags.contains(tag) {
                plugins[index].tags.append(tag)
                let actualPath = plugins[index].path
                _ = setFinderTags(plugins[index].tags, for: actualPath)
                updateAllTags()
                saveDatabase()
                statusMessage = "Tagged: \(plugin.name)"
            }
        }
    }
    
    func removeTag(_ tag: String, from plugin: Plugin) {
        if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
            plugins[index].tags.removeAll { $0 == tag }
            let actualPath = plugins[index].path
            _ = setFinderTags(plugins[index].tags, for: actualPath)
            updateAllTags()
            saveDatabase()
            statusMessage = "Untagged: \(plugin.name)"
        }
    }
    
    func toggleActiveTag(_ tag: String) {
        if activeTags.contains(tag) {
            activeTags.remove(tag)
        } else {
            activeTags.insert(tag)
        }
    }
    
    func revealInFinder(_ plugin: Plugin) {
        NSWorkspace.shared.selectFile(plugin.path, inFileViewerRootedAtPath: "")
    }
    
    func pluginCount(for filter: PluginFilter) -> Int {
        switch filter {
        case .all: return plugins.count
        case .active: return activeCount
        case .vaulted: return vaultedCount
        case .tag(let tag): return plugins.filter { $0.tags.contains(tag) }.count
        case .collection(let id): return collections.first { $0.id == id }?.pluginIDs.count ?? 0
        }
    }
    
    private func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
        statusMessage = message
    }

    private func renameSummaryMessage(successMessage: String, failures: [PluginRenameFailure]) -> String {
        guard !failures.isEmpty else { return successMessage }

        let shownFailures = failures.prefix(3)
            .map { "\($0.plugin.name): \($0.error.localizedDescription)" }
            .joined(separator: "\n")
        let remaining = failures.count > 3 ? "\n…and \(failures.count - 3) more." : ""
        return "\(successMessage)\n\nFailed \(failures.count):\n\(shownFailures)\(remaining)"
    }

    private func permissionAwareMessage(action: String, error: Error) -> String {
        if isPermissionError(error) {
            return "macOS blocked access while trying to \(action). Open Full Disk Access in Settings, add PluginVault, then try again. If the plug-in is in /Library, macOS may also ask for an administrator password."
        }
        return "Failed to \(action): \(error.localizedDescription)"
    }
    
    // MARK: - Bulk Tag Operations
    func addTag(_ tag: String, to plugins: [Plugin]) {
        guard !tag.isEmpty else { return }
        var changed: [Int] = []
        for (idx, item) in self.plugins.enumerated() {
            if plugins.contains(where: { $0.originalPath == item.originalPath }) {
                if !self.plugins[idx].tags.contains(tag) {
                    self.plugins[idx].tags.append(tag)
                    changed.append(idx)
                }
            }
        }
        // Persist Finder tags for changed items
        for idx in changed {
            let actualPath = self.plugins[idx].path
            _ = setFinderTags(self.plugins[idx].tags, for: actualPath)
        }
        if !changed.isEmpty {
            updateAllTags()
            saveDatabase()
            statusMessage = "Added tag '\(tag)' to \(changed.count) plugin(s)"
        }
    }
    
    func removeTag(_ tag: String, from plugins: [Plugin]) {
        var changed: [Int] = []
        for (idx, item) in self.plugins.enumerated() {
            if plugins.contains(where: { $0.originalPath == item.originalPath }) {
                let before = self.plugins[idx].tags.count
                self.plugins[idx].tags.removeAll { $0 == tag }
                if self.plugins[idx].tags.count != before {
                    changed.append(idx)
                }
            }
        }
        for idx in changed {
            let actualPath = self.plugins[idx].path
            _ = setFinderTags(self.plugins[idx].tags, for: actualPath)
        }
        if !changed.isEmpty {
            updateAllTags()
            saveDatabase()
            statusMessage = "Removed tag '\(tag)' from \(changed.count) plugin(s)"
        }
    }
    
    func addTags(_ tags: [String], to plugins: [Plugin]) {
        let clean = Array(Set(tags.filter { !$0.isEmpty }))
        guard !clean.isEmpty else { return }
        var changed: [Int] = []
        for (idx, item) in self.plugins.enumerated() {
            if plugins.contains(where: { $0.originalPath == item.originalPath }) {
                let existing = Set(self.plugins[idx].tags)
                let merged = existing.union(clean)
                if merged.count != existing.count {
                    self.plugins[idx].tags = Array(merged).sorted()
                    changed.append(idx)
                }
            }
        }
        for idx in changed {
            let actualPath = self.plugins[idx].path
            _ = setFinderTags(self.plugins[idx].tags, for: actualPath)
        }
        if !changed.isEmpty {
            updateAllTags()
            saveDatabase()
            statusMessage = "Added \(clean.count) tag(s) to \(changed.count) plugin(s)"
        }
    }
    
    func removeTags(_ tags: [String], from plugins: [Plugin]) {
        let clean = Array(Set(tags.filter { !$0.isEmpty }))
        guard !clean.isEmpty else { return }
        var changed: [Int] = []
        for (idx, item) in self.plugins.enumerated() {
            if plugins.contains(where: { $0.originalPath == item.originalPath }) {
                let before = self.plugins[idx].tags.count
                self.plugins[idx].tags.removeAll { clean.contains($0) }
                if self.plugins[idx].tags.count != before {
                    changed.append(idx)
                }
            }
        }
        for idx in changed {
            let actualPath = self.plugins[idx].path
            _ = setFinderTags(self.plugins[idx].tags, for: actualPath)
        }
        if !changed.isEmpty {
            updateAllTags()
            saveDatabase()
            statusMessage = "Removed \(clean.count) tag(s) from \(changed.count) plugin(s)"
        }
    }
    
    // MARK: - Collection Management
    
    private func loadCollections() {
        guard FileManager.default.fileExists(atPath: collectionsPath.path) else { return }
        do {
            let data = try Data(contentsOf: collectionsPath)
            collections = try JSONDecoder().decode([Collection].self, from: data)
        } catch {
            print("Failed to load collections: \(error)")
        }
    }
    
    private func saveCollections() {
        do {
            let data = try JSONEncoder().encode(collections)
            try data.write(to: collectionsPath)
        } catch {
            print("Failed to save collections: \(error)")
        }
    }
    
    func createCollection(title: String, pluginIDs: [String], sortOrder: CollectionSortOrder = .byName) {
        let collection = Collection(title: title, pluginIDs: pluginIDs, sortOrder: sortOrder)
        collections.append(collection)
        saveCollections()
        statusMessage = "Created collection: \(title)"
    }
    
    func deleteCollection(_ collection: Collection) {
        collections.removeAll { $0.id == collection.id }
        if case .collection(let id) = currentFilter, id == collection.id {
            currentFilter = .all
        }
        saveCollections()
        statusMessage = "Deleted collection: \(collection.title)"
    }
    
    func updateCollection(_ collection: Collection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
            saveCollections()
            if case .collection(let id) = currentFilter, id == collection.id {
                objectWillChange.send()
            }
        }
    }
    
    func addPluginToCollection(_ pluginID: String, collection: Collection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            if !collections[index].pluginIDs.contains(pluginID) {
                collections[index].pluginIDs.append(pluginID)
                saveCollections()
            }
        }
    }
    
    func removePluginFromCollection(_ pluginID: String, collection: Collection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index].pluginIDs.removeAll { $0 == pluginID }
            saveCollections()
        }
    }
    
    func collectionPlugins(_ collection: Collection) -> [Plugin] {
        return collection.sortedPlugins(from: plugins)
    }
    
    // MARK: - Settings
    
    var highlightSwiftUIColor: Color {
        switch highlightColor {
        case "blue": return Color(red: 0.0, green: 0.0, blue: 0.55)
        case "red": return Color(red: 0.6, green: 0.0, blue: 0.0)
        case "green": return Color(red: 0.0, green: 0.4, blue: 0.0)
        case "purple": return Color(red: 0.4, green: 0.0, blue: 0.5)
        case "teal": return Color(red: 0.0, green: 0.4, blue: 0.4)
        default: return ClassicMac.black
        }
    }
    
    var highlightTextColor: Color {
        switch highlightColor {
        case "black": return ClassicMac.white
        default: return ClassicMac.white
        }
    }
    
    var displayTextScale: Double { textScale }
    
    func setHighlightColor(_ color: String) {
        highlightColor = color
        saveSettings()
    }
    
    func setTextScale(_ scale: Double) {
        textScale = scale
        saveSettings()
    }
    
    // MARK: - Reset & Uninstall
    
    func resetAndUninstall() {
        statusMessage = "Resetting..."
        let unvaultSummary = unvaultAll(showAlert: false)
        guard unvaultSummary.failures.isEmpty else {
            showAlertMessage(renameSummaryMessage(
                successMessage: "Reset stopped after restoring \(unvaultSummary.changedCount) plugins",
                failures: unvaultSummary.failures
            ))
            return
        }
        clearFinderTagsForLoadedPlugins()
        try? FileManager.default.removeItem(at: dbPath)
        try? FileManager.default.removeItem(at: collectionsPath)
        plugins = []
        allTags = []
        activeTags = []
        collections = []
        currentFilter = .all
        searchQuery = ""
        highlightColor = "black"
        textScale = 1.0
        settingsDefaults.removeObject(forKey: "highlightColor")
        settingsDefaults.removeObject(forKey: "textScale")
        statusMessage = "Reset complete"
        showAlertMessage("All data has been cleared. You may now quit the application.")
    }

    private func clearFinderTagsForLoadedPlugins() {
        for plugin in plugins where !plugin.tags.isEmpty {
            _ = setFinderTags([], for: plugin.path)
        }
    }
}
