import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @Binding var showingCreateCollection: Bool
    @State private var selectedPlugin: Plugin?
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Classic Menu Bar
            ClassicMenuBar(
                appName: "Plugin Vault",
                menuItems: ["File", "Edit", "Collections", "Plugins", "View", "Special"],
                scanAction: { pluginManager.scanPlugins() },
                vaultUntaggedAction: { pluginManager.vaultUntagged() },
                unvaultAllAction: { pluginManager.unvaultAll() }
            )
            
            // Window Content
            VStack(spacing: 0) {
                ClassicTitleBar(title: "Plugin Vault - DAW Plugin Manager", onClose: nil)
                ClassicToolbar()
                
                HSplitView {
                    SidebarView()
                        .frame(minWidth: 220, maxWidth: 300)
                        .background(ClassicMac.windowBackground)
                    
                    PluginListView(selectedPlugin: $selectedPlugin)
                }
            }
            .background(ClassicMac.windowBackground)
            .classicOutsetBorder()
        }
        .background(DesktopPattern())
        .alert("Plugin Vault", isPresented: $pluginManager.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pluginManager.alertMessage)
        }
        .sheet(isPresented: $showingDetail) {
            if let plugin = selectedPlugin {
                DetailView(plugin: plugin)
                    .background(DesktopPattern())
            }
        }
        .sheet(isPresented: $showingCreateCollection) {
            CreateCollectionView(isPresented: $showingCreateCollection)
                .environmentObject(pluginManager)
                .background(DesktopPattern())
        }
        .onChange(of: selectedPlugin) {
            if selectedPlugin != nil { showingDetail = true }
        }
        .onChange(of: showingDetail) { newValue in
            if !newValue { selectedPlugin = nil }
        }
    }
}

// ============================================
// MARK: - Classic Toolbar
// ============================================
struct ClassicToolbar: View {
    @EnvironmentObject var pluginManager: PluginManager
    
    var body: some View {
        HStack(spacing: 10) {
            ClassicButton("Scan", icon: "⟳", action: { pluginManager.scanPlugins() })
            ClassicButton("Vault Untagged", icon: "☒", action: { pluginManager.vaultUntagged() })
            ClassicButton("Unvault All", icon: "☑", action: { pluginManager.unvaultAll() })
            
            Spacer()
            
            ClassicTextField(placeholder: "Search...", text: $pluginManager.searchQuery)
                .frame(width: 170)
            
            // Status indicator
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(pluginManager.isLoading ? Color.yellow : Color.green)
                        .frame(width: 10, height: 10)
                    Circle()
                        .stroke(ClassicMac.black, lineWidth: 1)
                        .frame(width: 10, height: 10)
                }
                Text(pluginManager.statusMessage)
                    .font(ClassicFonts.captionFallback)
                    .lineLimit(1)
            }
            .frame(width: 130, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ClassicMac.windowBackground)
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                ClassicSeparator()
            }
        )
    }
}
