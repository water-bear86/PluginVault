import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var pluginManager: PluginManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Collections
            ClassicSidebarSection(title: "♫ Collections") {
                VStack(spacing: 0) {
                    ClassicFilterRow(icon: "♫", title: "All Plugins", count: pluginManager.plugins.count, isSelected: pluginManager.currentFilter == .all) {
                        pluginManager.currentFilter = .all
                    }
                    ClassicFilterRow(icon: "☑", title: "Active", count: pluginManager.activeCount, isSelected: pluginManager.currentFilter == .active) {
                        pluginManager.currentFilter = .active
                    }
                    ClassicFilterRow(icon: "☒", title: "Vaulted", count: pluginManager.vaultedCount, isSelected: pluginManager.currentFilter == .vaulted) {
                        pluginManager.currentFilter = .vaulted
                    }
                    
                    if !pluginManager.allTags.isEmpty {
                        ClassicSeparator().padding(.vertical, 6)
                        
                        ForEach(pluginManager.allTags, id: \.self) { tag in
                            ClassicTagRow(tag: tag, count: pluginManager.pluginCount(for: .tag(tag)), isSelected: pluginManager.currentFilter == .tag(tag), isActive: pluginManager.activeTags.contains(tag))
                        }
                    }
                    
                    if !pluginManager.collections.isEmpty {
                        ClassicSeparator().padding(.vertical, 6)
                        
                        ForEach(pluginManager.collections, id: \.id) { collection in
                            ClassicCollectionRow(
                                collection: collection,
                                count: collection.pluginIDs.count,
                                isSelected: pluginManager.currentFilter == .collection(collection.id)
                            )
                        }
                    }
                }
            }
            
            ClassicSeparator()
            
            // Active Tag Filters
            ClassicSidebarSection(title: "⌘ Active Filters") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable tags to filter plugins")
                        .font(ClassicFonts.captionFallback)
                        .foregroundColor(ClassicMac.darkGray)
                    
                    if pluginManager.activeTags.isEmpty {
                        Text("No active filters")
                            .font(ClassicFonts.captionFallback)
                            .foregroundColor(ClassicMac.darkGray)
                            .italic()
                    } else {
                        FlowLayout(spacing: 4) {
                            ForEach(Array(pluginManager.activeTags).sorted(), id: \.self) { tag in
                                ClassicTagBadge(tag: tag, isRemovable: true, style: .selected) {
                                    pluginManager.toggleActiveTag(tag)
                                }
                            }
                        }
                    }
                    
                    ClassicButton("Apply Filter", icon: "⚡") {
                        pluginManager.applyActiveTagFilter()
                    }
                    .padding(.top, 4)
                }
                .padding(8)
            }
            
            Spacer()
        }
        .overlay(
            Rectangle().frame(width: 1).foregroundColor(ClassicMac.black),
            alignment: .trailing
        )
    }
}

// ============================================
// MARK: - Sidebar Section
// ============================================
struct ClassicSidebarSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(ClassicFonts.bodyBoldFallback)
                .foregroundColor(ClassicMac.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ClassicMac.black)
            
            content
        }
    }
}

// ============================================
// MARK: - Filter Row
// ============================================
struct ClassicFilterRow: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon).frame(width: 22)
                Text(title).font(ClassicFonts.bodyFallback)
                Spacer()
                
                Text("\(count)")
                    .font(ClassicFonts.captionFallback)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? ClassicMac.darkGray : ClassicMac.lightGray)
                    .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
                    .overlay(Rectangle().stroke(ClassicMac.black, lineWidth: 1))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? ClassicMac.black : Color.clear)
            .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
        }
        .buttonStyle(.plain)
    }
}

// ============================================
// MARK: - Tag Row
// ============================================
struct ClassicTagRow: View {
    @EnvironmentObject var pluginManager: PluginManager
    let tag: String
    let count: Int
    let isSelected: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { pluginManager.currentFilter = .tag(tag) }) {
                HStack {
                    Text("⌘").frame(width: 22)
                    Text(tag).font(ClassicFonts.bodyFallback).lineLimit(1)
                    Spacer()
                    Text("\(count)")
                        .font(ClassicFonts.captionFallback)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(ClassicMac.lightGray)
                        .overlay(Rectangle().stroke(ClassicMac.black, lineWidth: 1))
                }
                .padding(.leading, 10)
                .padding(.vertical, 5)
                .background(isSelected ? ClassicMac.black : Color.clear)
                .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
            }
            .buttonStyle(.plain)
            
            // Active toggle
            ClassicCheckbox(isOn: Binding(
                get: { isActive },
                set: { _ in pluginManager.toggleActiveTag(tag) }
            ))
            .padding(.horizontal, 10)
        }
    }
}

// ============================================
// MARK: - Collection Row
// ============================================
struct ClassicCollectionRow: View {
    @EnvironmentObject var pluginManager: PluginManager
    let collection: Collection
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { pluginManager.currentFilter = .collection(collection.id) }) {
                HStack {
                    Text("◆").frame(width: 22)
                    Text(collection.title).font(ClassicFonts.bodyFallback).lineLimit(1)
                    Spacer()
                    Text("\(count)")
                        .font(ClassicFonts.captionFallback)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(isSelected ? ClassicMac.darkGray : ClassicMac.lightGray)
                        .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
                        .overlay(Rectangle().stroke(ClassicMac.black, lineWidth: 1))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? ClassicMac.black : Color.clear)
                .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
            }
            .buttonStyle(.plain)
            
            Button(action: { pluginManager.deleteCollection(collection) }) {
                Text("×")
                    .font(ClassicFonts.bodyBoldFallback)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)
        }
    }
}
