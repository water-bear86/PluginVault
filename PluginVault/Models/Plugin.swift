import Foundation

enum PluginType: String, Codable, CaseIterable {
    case au = "AU"
    case vst = "VST"
    case vst3 = "VST3"
    case aax = "AAX"
    case unknown = "???"
    
    var icon: String {
        switch self {
        case .au: return "◆"
        case .vst: return "●"
        case .vst3: return "■"
        case .aax: return "▲"
        case .unknown: return "○"
        }
    }
}

struct Plugin: Identifiable, Codable, Hashable {
    var id: String { originalPath }
    let name: String
    var path: String
    let pluginType: PluginType
    var isVaulted: Bool
    var tags: [String]
    let dateAdded: Date
    
    static let vaultSuffix = ".vaulted"
    
    var originalPath: String {
        if path.hasSuffix(Self.vaultSuffix) {
            return String(path.dropLast(Self.vaultSuffix.count))
        }
        return path
    }
    
    var vaultedPath: String {
        if path.hasSuffix(Self.vaultSuffix) {
            return path
        }
        return path + Self.vaultSuffix
    }
    
    var displayName: String { name }
    
    var statusIcon: String {
        isVaulted ? "☒" : "☑"
    }
    
    var statusText: String {
        isVaulted ? "Vaulted" : "Active"
    }
    
    init(name: String, path: String, pluginType: PluginType, isVaulted: Bool = false, tags: [String] = [], dateAdded: Date = Date()) {
        self.name = name
        self.path = path
        self.pluginType = pluginType
        self.isVaulted = isVaulted
        self.tags = tags
        self.dateAdded = dateAdded
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(originalPath)
    }
    
    static func == (lhs: Plugin, rhs: Plugin) -> Bool {
        lhs.originalPath == rhs.originalPath
    }
}

enum PluginFilter: Hashable {
    case all
    case active
    case vaulted
    case tag(String)
    case collection(String)
    
    var displayName: String {
        switch self {
        case .all: return "All Plugins"
        case .active: return "Active"
        case .vaulted: return "Vaulted"
        case .tag(let name): return name
        case .collection(let name): return name
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "♫"
        case .active: return "☑"
        case .vaulted: return "☒"
        case .tag: return "⌘"
        case .collection: return "◆"
        }
    }
}
