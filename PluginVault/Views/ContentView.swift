import SwiftUI

struct ContentView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @State private var showingCreateCollection = false
    @State private var selectedPlugin: Plugin?
    @State private var showingDetail = false

    var body: some View {
        ZStack {
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

            if showingDetail, let plugin = selectedPlugin {
                ClassicModalOverlay {
                    DetailView(plugin: plugin, isPresented: $showingDetail)
                        .environmentObject(pluginManager)
                }
            }

            if showingCreateCollection {
                ClassicModalOverlay {
                    CreateCollectionView(isPresented: $showingCreateCollection)
                        .environmentObject(pluginManager)
                }
            }

            if pluginManager.showAlert {
                ClassicModalOverlay {
                    ClassicAlertDialog(
                        title: "Plugin Vault",
                        message: pluginManager.alertMessage
                    ) {
                        pluginManager.showAlert = false
                    }
                }
            }
        }
        .onChange(of: selectedPlugin) { newValue in
            if newValue != nil { showingDetail = true }
        }
        .onChange(of: showingDetail) { newValue in
            if !newValue { selectedPlugin = nil }
        }
    }
}

struct ClassicModalOverlay<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(50)
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
