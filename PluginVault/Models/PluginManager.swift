import Foundation
import SwiftUI
import Combine

class PluginManager: ObservableObject {
    @Published var plugins: [Plugin] = []
    @Published var allTags: [String] = []
    @Published var activeTags: Set<String> = []
    @Published var currentFilter: PluginFilter = .all
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // Request flag to open the Collection Inspector from menu/toolbar
    @Published var requestOpenCollectionInspector: Bool = false
    
    // Collections
    @Published var collections: [Collection] = []
    
    // Settings
    @Published var highlightColor: String = "black"
    @Published var textScale: Double = 1.0
    
    static let defaultPluginDirs: [String] = [
        "/Library/Audio/Plug-Ins/Components",
        "/Library/Audio/Plug-Ins/VST",
        "/Library/Audio/Plug-Ins/VST3",
        "/Library/Audio/Plug-Ins/AAX",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/Components",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/VST",
        NSHomeDirectory() + "/Library/Audio/Plug-Ins/VST3",
    ]
    
    private let pluginExtensions = [".component", ".vst", ".vst3", ".aaxplugin"]
    private let dbPath: URL
    private let collectionsPath: URL
    
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
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("PluginVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        self.dbPath = appFolder.appendingPathComponent("database.json")
        self.collectionsPath = appFolder.appendingPathComponent("collections.json")
        loadSettings()
        loadDatabase()
        loadCollections()
        scanPlugins()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        highlightColor = defaults.string(forKey: "highlightColor") ?? "black"
        textScale = defaults.double(forKey: "textScale") == 0 ? 1.0 : defaults.double(forKey: "textScale")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(highlightColor, forKey: "highlightColor")
        defaults.set(textScale, forKey: "textScale")
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
                        let isVaulted = itemLower.hasSuffix(Plugin.vaultSuffix.lowercased())
                        let nameToCheck = isVaulted ? String(itemLower.dropLast(Plugin.vaultSuffix.count)) : itemLower
                        
                        guard self.pluginExtensions.contains(where: { nameToCheck.hasSuffix($0) }) else { continue }
                        
                        let pluginType = self.getPluginType(from: itemPath)
                        var displayName = item
                        
                        if isVaulted {
                            displayName = String(displayName.dropLast(Plugin.vaultSuffix.count))
                        }
                        
                        for ext in self.pluginExtensions {
                            if displayName.lowercased().hasSuffix(ext) {
                                displayName = String(displayName.dropLast(ext.count))
                                break
                            }
                        }
                        
                        let originalPath = isVaulted 
                            ? String(itemPath.dropLast(Plugin.vaultSuffix.count)) 
                            : itemPath
                        
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
                    print("Error scanning \(dir): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.plugins = foundPlugins
                self.updateAllTags()
                self.saveDatabase()
                self.isLoading = false
                self.statusMessage = "\(foundPlugins.count) plugins"
            }
        }
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
        let url = URL(fileURLWithPath: path)
        do {
            var resourceValues = URLResourceValues()
            resourceValues.tagNames = tags
            var mutableURL = url
            try mutableURL.setResourceValues(resourceValues)
            return true
        } catch {
            print("Failed to set Finder tags: \(error)")
            return false
        }
    }
    
    func vaultPlugin(_ plugin: Plugin) {
        guard !plugin.isVaulted else {
            showAlertMessage("Plugin is already vaulted")
            return
        }
        let currentPath = plugin.originalPath
        let newPath = plugin.vaultedPath
        do {
            try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
            if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                plugins[index].path = newPath
                plugins[index].isVaulted = true
                saveDatabase()
                statusMessage = "Vaulted: \(plugin.name)"
            }
        } catch {
            showAlertMessage("Failed to vault: \(error.localizedDescription)")
        }
    }
    
    func unvaultPlugin(_ plugin: Plugin) {
        guard plugin.isVaulted else {
            showAlertMessage("Plugin is not vaulted")
            return
        }
        let currentPath = plugin.vaultedPath
        let newPath = plugin.originalPath
        do {
            try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
            if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                plugins[index].path = newPath
                plugins[index].isVaulted = false
                saveDatabase()
                statusMessage = "Restored: \(plugin.name)"
            }
        } catch {
            showAlertMessage("Failed to unvault: \(error.localizedDescription)")
        }
    }
    
    func toggleVault(_ plugin: Plugin) {
        if plugin.isVaulted {
            unvaultPlugin(plugin)
        } else {
            vaultPlugin(plugin)
        }
    }
    
    func vaultUntagged() {
        let untagged = plugins.filter { $0.tags.isEmpty && !$0.isVaulted }
        guard !untagged.isEmpty else {
            showAlertMessage("No untagged plugins to vault")
            return
        }
        var vaultedCount = 0
        for plugin in untagged {
            let currentPath = plugin.originalPath
            let newPath = plugin.vaultedPath
            do {
                try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
                if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                    plugins[index].path = newPath
                    plugins[index].isVaulted = true
                    vaultedCount += 1
                }
            } catch {
                print("Failed to vault \(plugin.name): \(error)")
            }
        }
        saveDatabase()
        showAlertMessage("Vaulted \(vaultedCount) untagged plugins")
    }
    
    func unvaultAll() {
        let vaulted = plugins.filter { $0.isVaulted }
        guard !vaulted.isEmpty else {
            showAlertMessage("No vaulted plugins to restore")
            return
        }
        var unvaultedCount = 0
        for plugin in vaulted {
            let currentPath = plugin.vaultedPath
            let newPath = plugin.originalPath
            do {
                try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
                if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                    plugins[index].path = newPath
                    plugins[index].isVaulted = false
                    unvaultedCount += 1
                }
            } catch {
                print("Failed to unvault \(plugin.name): \(error)")
            }
        }
        saveDatabase()
        showAlertMessage("Restored \(unvaultedCount) plugins")
    }
    
    func applyActiveTagFilter() {
        guard !activeTags.isEmpty else {
            showAlertMessage("No tags selected - will unvault all")
            unvaultAll()
            return
        }
        var vaultedCount = 0
        var unvaultedCount = 0
        
        for plugin in plugins {
            let hasActiveTag = !Set(plugin.tags).isDisjoint(with: activeTags)
            
            if hasActiveTag && plugin.isVaulted {
                let currentPath = plugin.vaultedPath
                let newPath = plugin.originalPath
                do {
                    try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
                    if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                        plugins[index].path = newPath
                        plugins[index].isVaulted = false
                        unvaultedCount += 1
                    }
                } catch {}
            } else if !hasActiveTag && !plugin.isVaulted {
                let currentPath = plugin.originalPath
                let newPath = plugin.vaultedPath
                do {
                    try FileManager.default.moveItem(atPath: currentPath, toPath: newPath)
                    if let index = plugins.firstIndex(where: { $0.originalPath == plugin.originalPath }) {
                        plugins[index].path = newPath
                        plugins[index].isVaulted = true
                        vaultedCount += 1
                    }
                } catch {}
            }
        }
        saveDatabase()
        showAlertMessage("Vaulted \(vaultedCount), restored \(unvaultedCount)")
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
        // MARK: - Convenience wrappers
        func toggle(plugin: Plugin) {
            toggleVault(plugin)
        }
        func reveal(_ plugin: Plugin) {
            revealInFinder(plugin)
        }
        let path = plugin.isVaulted ? plugin.vaultedPath : plugin.originalPath
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
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
        unvaultAll()
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
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "highlightColor")
        defaults.removeObject(forKey: "textScale")
        statusMessage = "Reset complete"
        showAlertMessage("All data has been cleared. You may now quit the application.")
    }
}
