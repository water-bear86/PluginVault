import SwiftUI

@main
struct PluginVaultApp: App {
    @StateObject private var pluginManager = PluginManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pluginManager)
                .frame(minWidth: 950, minHeight: 650)
                .background(WindowConfigurator())
                .ignoresSafeArea(edges: .top)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        Settings {
            SettingsView()
                .environmentObject(pluginManager)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var pluginManager: PluginManager
    @State private var showResetConfirm = false
    private let highlightOptions = ["black", "blue", "red", "green", "purple", "teal"]
    private let textScaleOptions = [0.85, 1.0, 1.15]
    
    var body: some View {
        ClassicWindow(title: "Settings", onClose: nil) {
            VStack(alignment: .leading, spacing: 16) {
                ClassicGroupBox(title: "Plugin Directories") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(PluginManager.defaultPluginDirs, id: \.self) { dir in
                            Text(dir)
                                .font(ClassicFonts.caption)
                        }
                    }
                }
                
                ClassicGroupBox(title: "Appearance") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Highlight Colour:")
                                .font(ClassicFonts.bodyFallback)
                            ClassicPopupButton(
                                selection: Binding(
                                get: { pluginManager.highlightColor },
                                set: { pluginManager.setHighlightColor($0) }
                                ),
                                options: highlightOptions,
                                width: 120,
                                optionTitle: { $0.capitalized }
                            )
                        }
                        HStack {
                            Text("Text Size:")
                                .font(ClassicFonts.bodyFallback)
                            ClassicPopupButton(
                                selection: Binding(
                                get: { pluginManager.textScale },
                                set: { pluginManager.setTextScale($0) }
                                ),
                                options: textScaleOptions,
                                width: 120,
                                optionTitle: textScaleName
                            )
                        }
                    }
                }

                ClassicGroupBox(title: "Full Disk Access") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pluginManager.diskAccessStatusMessage)
                            .font(ClassicFonts.bodyFallback)
                        Text("PluginVault cannot show a normal macOS permission prompt for this. Open Full Disk Access, add PluginVault, then quit and reopen the app.")
                            .font(ClassicFonts.captionFallback)
                            .fixedSize(horizontal: false, vertical: true)
                        if !pluginManager.skippedPluginDirs.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(pluginManager.skippedPluginDirs, id: \.self) { dir in
                                    Text(dir)
                                        .font(ClassicFonts.captionFallback)
                                        .lineLimit(1)
                                }
                            }
                        }
                        HStack {
                            ClassicButton("Open Full Disk Access", icon: "⌘") {
                                pluginManager.openFullDiskAccessSettings()
                            }
                            ClassicButton("Scan Again", icon: "⟳") {
                                pluginManager.scanPlugins()
                            }
                        }
                    }
                }
                
                ClassicGroupBox(title: "About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Vaulted plugins have '.vault' appended")
                        Text("• Tags sync with macOS Finder tags")
                        Text("• Run without sandbox; Full Disk Access may still be required")
                    }
                    .font(ClassicFonts.body)
                }
                
                ClassicSeparator()
                
                HStack {
                    Spacer()
                    ClassicButton("Reset & Uninstall", icon: "⚠") {
                        showResetConfirm = true
                    }
                    Spacer()
                }
                
                Spacer()
            }
            .padding(16)
        }
        .frame(width: 500, height: 620)
        .background(DesktopPattern())
        .overlay(Group {
            if pluginManager.showAlert {
                ClassicAlertDialog(
                    title: "Plugin Vault",
                    message: pluginManager.alertMessage
                ) {
                    pluginManager.showAlert = false
                }
            }

            if showResetConfirm {
                ClassicAlertDialog(
                    title: "Reset and Uninstall?",
                    message: "This will unvault all plugins, delete all data, and reset settings. This cannot be undone.",
                    primaryTitle: "Reset Everything",
                    secondaryTitle: "Cancel"
                ) {
                    showResetConfirm = false
                    pluginManager.resetAndUninstall()
                } secondaryAction: {
                    showResetConfirm = false
                }
            }
        })
    }
    
    private func textScaleName(_ scale: Double) -> String {
        switch scale {
        case 0.85: return "Small"
        case 1.15: return "Large"
        default: return "Medium"
        }
    }
}
