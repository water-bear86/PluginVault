import SwiftUI
import Combine

struct PluginListView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @Binding var selectedPlugin: Plugin?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("").frame(width: 44)
                Text("Plugin Name").frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
                Text("Type").frame(width: 50)
                Text("Tags").frame(width: 150, alignment: .leading)
                Text("").frame(width: 65)
            }
            .font(ClassicFonts.bodyFallback)
            .fontWeight(.bold)
            .foregroundColor(ClassicMac.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ClassicMac.black)
            
            // List
            if pluginManager.isLoading {
                ClassicLoadingView()
            } else if pluginManager.filteredPlugins.isEmpty {
                ClassicEmptyView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(pluginManager.filteredPlugins) { plugin in
                            ClassicPluginRow(
                                plugin: plugin,
                                isSelected: selectedPlugin?.originalPath == plugin.originalPath,
                                onSelect: { selectedPlugin = plugin },
                                onToggleVault: { pluginManager.toggleVault(plugin) }
                            )
                        }
                    }
                }
                .background(ClassicMac.white)
            }
        }
        .background(ClassicMac.white)
        .classicInsetBorder()
    }
}

// ============================================
// MARK: - Plugin Row
// ============================================
struct ClassicPluginRow: View {
    let plugin: Plugin
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVault: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Text(plugin.statusIcon)
                .font(.system(size: 14))
                .frame(width: 44)
            
            Text(plugin.displayName)
                .font(ClassicFonts.bodyFallback)
                .fontWeight(.medium)
                .strikethrough(plugin.isVaulted)
                .lineLimit(1)
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
            
            ClassicTypeBadge(type: plugin.pluginType)
                .frame(width: 50)
            
            HStack(spacing: 3) {
                ForEach(plugin.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(ClassicFonts.captionFallback)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(ClassicMac.lightGray)
                        .overlay(Rectangle().stroke(ClassicMac.mediumGray, lineWidth: 1))
                        .lineLimit(1)
                }
                if plugin.tags.count > 2 {
                    Text("+\(plugin.tags.count - 2)")
                        .font(ClassicFonts.captionFallback)
                        .foregroundColor(ClassicMac.darkGray)
                }
            }
            .frame(width: 150, alignment: .leading)
            
            HStack(spacing: 6) {
                Button(action: onToggleVault) {
                    Text(plugin.isVaulted ? "☑" : "☒")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help(plugin.isVaulted ? "Restore" : "Vault")
                
                Button(action: onSelect) {
                    Text("ℹ")
                        .font(.system(size: 14, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Details")
            }
            .frame(width: 65)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            isSelected ? ClassicMac.black :
            (plugin.isVaulted ? ClassicMac.lightGray.opacity(0.5) : Color.clear)
        )
        .foregroundColor(isSelected ? ClassicMac.white : ClassicMac.black)
        .opacity(plugin.isVaulted ? 0.65 : 1.0)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(ClassicMac.lightGray),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onSelect() }
        .onTapGesture { }
    }
}

// ============================================
// MARK: - Type Badge
// ============================================
struct ClassicTypeBadge: View {
    let type: PluginType
    
    var body: some View {
        Text(type.rawValue)
            .font(ClassicFonts.captionFallback)
            .fontWeight(.bold)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(ClassicMac.white)
            .overlay(Rectangle().stroke(ClassicMac.black, lineWidth: 1))
    }
}

// ============================================
// MARK: - Loading View
// ============================================
struct ClassicLoadingView: View {
    @State private var frame = 0
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    let frames = ["◐", "◓", "◑", "◒"]
    
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Text(frames[frame % frames.count])
                .font(.system(size: 36))
            Text("Scanning plugins...")
                .font(ClassicFonts.bodyFallback)
                .foregroundColor(ClassicMac.darkGray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClassicMac.white)
        .onReceive(timer) { _ in frame += 1 }
    }
}

// ============================================
// MARK: - Empty View
// ============================================
struct ClassicEmptyView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("♫")
                .font(.system(size: 40))
            Text("No plugins found")
                .font(ClassicFonts.bodyFallback)
                .foregroundColor(ClassicMac.darkGray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClassicMac.white)
    }
}
