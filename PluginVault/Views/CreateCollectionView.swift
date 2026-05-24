import SwiftUI

struct CreateCollectionView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @Binding var isPresented: Bool
    @State private var title: String = ""
    @State private var sortOrder: CollectionSortOrder = .byName
    @State private var selectedAvailable: Set<String> = []
    @State private var selectedInCollection: Set<String> = []

    var availablePlugins: [Plugin] {
        switch sortOrder {
        case .byName:
            return pluginManager.plugins.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .byDateAdded:
            return pluginManager.plugins.sorted { $0.dateAdded < $1.dateAdded }
        case .byType:
            return pluginManager.plugins.sorted { $0.pluginType.rawValue < $1.pluginType.rawValue }
        }
    }

    var body: some View {
        ClassicWindow(title: title.isEmpty ? "New Collection" : title, onClose: { isPresented = false }) {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Collection Title:")
                            .font(ClassicFonts.bodyFallback)
                        ClassicTextField(placeholder: "Enter title...", text: $title)
                            .frame(width: 200)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Sort:")
                                .font(ClassicFonts.bodyFallback)
                            ClassicPopupButton(
                                selection: $sortOrder,
                                options: CollectionSortOrder.allCases,
                                width: 110,
                                optionTitle: { $0.rawValue }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                }

                ClassicSeparator()

                // Two-pane layout
                HStack(spacing: 0) {
                    pluginPane(
                        title: "Plugins",
                        plugins: availablePlugins,
                        selected: $selectedAvailable
                    )
                    .frame(minWidth: 250, maxWidth: .infinity)
                    
                    Rectangle()
                        .fill(ClassicMac.black)
                        .frame(width: 1)

                    VStack(spacing: 8) {
                        Spacer()
                        ClassicButton("→", icon: nil) {
                            for id in selectedAvailable {
                                selectedInCollection.insert(id)
                            }
                            selectedAvailable.removeAll()
                        }
                        ClassicButton("←", icon: nil) {
                            for id in selectedInCollection {
                                selectedAvailable.remove(id)
                            }
                            selectedInCollection.removeAll()
                        }
                        Spacer()
                    }
                    .frame(width: 36)
                    .background(ClassicMac.windowBackground)
                    
                    Rectangle()
                        .fill(ClassicMac.black)
                        .frame(width: 1)

                    pluginPane(
                        title: "Collection",
                        plugins: availablePlugins.filter { selectedInCollection.contains($0.originalPath) },
                        selected: $selectedInCollection
                    )
                    .frame(minWidth: 250, maxWidth: .infinity)
                }
                .frame(minHeight: 350)

                ClassicSeparator()

                HStack {
                    Spacer()
                    ClassicButton("Cancel") {
                        isPresented = false
                    }
                    ClassicDefaultButton(title: "Save") {
                        let ids = Array(selectedInCollection)
                        pluginManager.createCollection(title: title.isEmpty ? "Untitled" : title, pluginIDs: ids, sortOrder: sortOrder)
                        isPresented = false
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 640, height: 500)
    }

    func pluginPane(title: String, plugins: [Plugin], selected: Binding<Set<String>>) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(ClassicFonts.bodyBoldFallback)
                .foregroundColor(ClassicMac.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ClassicMac.black)

            Text("\(plugins.count) plugins")
                .font(ClassicFonts.captionFallback)
                .foregroundColor(ClassicMac.darkGray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(ClassicMac.windowBackground)

            Group {
                if plugins.isEmpty {
                    Rectangle()
                        .fill(ClassicMac.windowBackground)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(plugins) { plugin in
                                let sel = selected.wrappedValue.contains(plugin.originalPath)
                                Button(action: {
                                    if sel {
                                        selected.wrappedValue.remove(plugin.originalPath)
                                    } else {
                                        selected.wrappedValue.insert(plugin.originalPath)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        ClassicCheckboxIndicator(isOn: sel)
                                        
                                        Text(plugin.name)
                                            .strikethrough(plugin.isVaulted)
                                            .font(ClassicFonts.bodyFallback)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        ClassicTypeBadge(type: plugin.pluginType)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(sel ? ClassicMac.black : ClassicMac.white)
                                    .foregroundColor(sel ? ClassicMac.white : ClassicMac.black)
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    Rectangle().frame(height: 1).foregroundColor(ClassicMac.lightGray),
                                    alignment: .bottom
                                )
                                .opacity(plugin.isVaulted ? 0.65 : 1.0)
                            }
                        }
                    }
                    .background(ClassicMac.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(plugins.isEmpty ? ClassicMac.windowBackground : ClassicMac.white)
            .classicInsetBorder()
        }
        .background(ClassicMac.windowBackground)
    }
}
