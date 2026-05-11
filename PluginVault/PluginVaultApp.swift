import SwiftUI

@main
struct PluginVaultApp: App {
    @StateObject private var pluginManager = PluginManager()
    @State private var showingCreateCollection = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(showingCreateCollection: $showingCreateCollection)
                .environmentObject(pluginManager)
                .frame(minWidth: 950, minHeight: 650)
                .background(WindowConfigurator())
                .ignoresSafeArea(edges: .top)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Collections") {
                Button("Create Collection...") {
                    showingCreateCollection = true
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
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
                            Picker("", selection: Binding(
                                get: { pluginManager.highlightColor },
                                set: { pluginManager.setHighlightColor($0) }
                            )) {
                                Text("Black").tag("black")
                                Text("Blue").tag("blue")
                                Text("Red").tag("red")
                                Text("Green").tag("green")
                                Text("Purple").tag("purple")
                                Text("Teal").tag("teal")
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }
                        HStack {
                            Text("Text Size:")
                                .font(ClassicFonts.bodyFallback)
                            Picker("", selection: Binding(
                                get: { pluginManager.textScale },
                                set: { pluginManager.setTextScale($0) }
                            )) {
                                Text("Small").tag(0.85)
                                Text("Medium").tag(1.0)
                                Text("Large").tag(1.15)
                            }
                            .labelsHidden()
                            .frame(width: 120)
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
}
