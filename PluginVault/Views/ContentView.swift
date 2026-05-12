import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @State private var showingCreateCollection = false
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
                ClassicToolbar {
                    showingCreateCollection = true
                }
                
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
        .overlay {
            if pluginManager.showAlert {
                ClassicAlertDialog(
                    title: "Plugin Vault",
                    message: pluginManager.alertMessage
                ) {
                    pluginManager.showAlert = false
                }
            }
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
        .onChange(of: showingDetail) { _, newValue in
            if !newValue { selectedPlugin = nil }
        }
    }
}

// ============================================
// MARK: - Classic Toolbar
// ============================================
struct ClassicToolbar: View {
    @EnvironmentObject var pluginManager: PluginManager
    let createCollectionAction: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            ClassicButton("Scan", icon: "⟳", action: { pluginManager.scanPlugins() })
            ClassicButton("Create Collection", icon: "◆", action: createCollectionAction)
            ClassicButton("Vault Untagged", icon: "☒", action: { pluginManager.vaultUntagged() })
            ClassicButton("Unvault All", icon: "☑", action: { pluginManager.unvaultAll() })
            
            Spacer()
            
            ClassicTextField(placeholder: "Search...", text: $pluginManager.searchQuery)
                .frame(width: 170)
            
            ClassicStatusIndicator(
                isLoading: pluginManager.isLoading,
                message: pluginManager.statusMessage
            )
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
