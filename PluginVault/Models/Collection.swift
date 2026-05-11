import Foundation

enum CollectionSortOrder: String, Codable, CaseIterable, Hashable {
    case byName = "Name"
    case byDateAdded = "Date Added"
    case byType = "Type"
}

struct Collection: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var pluginIDs: [String]
    var sortOrder: CollectionSortOrder
    var dateCreated: Date

    init(title: String, pluginIDs: [String] = [], sortOrder: CollectionSortOrder = .byName) {
        self.id = UUID().uuidString
        self.title = title
        self.pluginIDs = pluginIDs
        self.sortOrder = sortOrder
        self.dateCreated = Date()
    }

    func sortedPlugins(from allPlugins: [Plugin]) -> [Plugin] {
        let filtered = allPlugins.filter { pluginIDs.contains($0.originalPath) }
        switch sortOrder {
        case .byName:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .byDateAdded:
            return filtered.sorted { $0.dateAdded < $1.dateAdded }
        case .byType:
            return filtered.sorted { $0.pluginType.rawValue < $1.pluginType.rawValue }
        }
    }
}
