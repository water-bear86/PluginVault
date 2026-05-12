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
                
                ClassicGroupBox(title: "About") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Vaulted plugins have '.vaulted' appended")
                        Text("• Tags sync with macOS Finder tags")
                        Text("• Run without sandbox for full access")
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
        .frame(width: 450, height: 480)
        .background(DesktopPattern())
        .alert("Reset and Uninstall?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                pluginManager.resetAndUninstall()
            }
        } message: {
            Text("This will unvault all plugins, delete all data, and reset settings. This cannot be undone.")
        }
    }
    
    private func textScaleName(_ scale: Double) -> String {
        switch scale {
        case 0.85: return "Small"
        case 1.15: return "Large"
        default: return "Medium"
        }
    }
}
