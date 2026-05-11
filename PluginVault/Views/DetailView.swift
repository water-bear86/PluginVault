import SwiftUI

struct DetailView: View {
    @EnvironmentObject var pm: PluginManager
    @Environment(\.dismiss) var dismiss
    let plugin: Plugin
    @State private var newTag = ""
    @State private var existingTagSelection = ""
    
    var current: Plugin {
        pm.plugins.first { $0.originalPath == plugin.originalPath } ?? plugin
    }
    
    var availableExistingTags: [String] {
        pm.allTags.filter { !current.tags.contains($0) }
    }
    
    var body: some View {
        ClassicWindow(title: current.name, onClose: { dismiss() }) {
            VStack(alignment: .leading, spacing: 12) {
                ClassicGroupBox(title: "Plugin Info") {
                    VStack(alignment: .leading, spacing: 6) {
                        InfoRow("Name:", current.name)
                        InfoRow("Type:", current.pluginType.rawValue)
                        InfoRow("Status:", "\(current.statusIcon) \(current.isVaulted ? "Vaulted" : "Active")")
                        
                        ClassicSeparator()
                            .padding(.vertical, 2)
                        
                        Text("Path:")
                            .font(ClassicFonts.bodyFallback)
                            .fontWeight(.bold)
                        Text(current.path)
                            .font(ClassicFonts.captionFallback)
                            .foregroundColor(ClassicMac.darkGray)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                }
                
                ClassicGroupBox(title: "Tags") {
                    VStack(alignment: .leading, spacing: 8) {
                        if current.tags.isEmpty {
                            Text("No tags")
                                .font(ClassicFonts.bodyFallback)
                                .foregroundColor(ClassicMac.darkGray)
                                .italic()
                        } else {
                            FlowLayout(spacing: 4) {
                                ForEach(current.tags, id: \.self) { tag in
                                    ClassicTagBadge(tag: tag, isRemovable: true, style: .plain) {
                                        pm.removeTag(tag, from: current)
                                    }
                                }
                            }
                        }
                        
                        ClassicSeparator()
                        
                        HStack(spacing: 8) {
                            ClassicTextField(placeholder: "New tag...", text: $newTag)
                                .frame(width: 150)
                            
                            ClassicButton("Add", action: addTag)
                            
                            ClassicPopupButton(
                                selection: $existingTagSelection,
                                options: availableExistingTags,
                                width: 145,
                                label: availableExistingTags.isEmpty ? "No Tags" : "Add Existing",
                                optionTitle: { $0 },
                                onSelect: addExistingTag
                            )
                        }
                    }
                }
                
                ClassicSeparator()
                
                HStack(spacing: 8) {
                    ClassicButton(
                        current.isVaulted ? "Restore" : "Vault",
                        icon: current.isVaulted ? "☑" : "☒",
                        action: { pm.toggleVault(current) }
                    )
                    
                    ClassicButton("Reveal in Finder", icon: "⌘") {
                        pm.revealInFinder(current)
                    }
                    
                    Spacer()
                    
                    ClassicButton("Done") { dismiss() }
                }
            }
            .padding(16)
        }
        .frame(width: 460, height: 400)
    }
    
    func addTag() {
        let t = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        pm.addTag(t, to: current)
        newTag = ""
    }
    
    func addExistingTag(_ tag: String) {
        guard !tag.isEmpty else { return }
        pm.addTag(tag, to: current)
        existingTagSelection = ""
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    init(_ l: String, _ v: String) { label = l; value = v }
    var body: some View {
        HStack {
            Text(label)
                .font(ClassicFonts.bodyFallback)
                .fontWeight(.bold)
                .frame(width: 55, alignment: .leading)
            Text(value)
                .font(ClassicFonts.bodyFallback)
            Spacer()
        }
    }
}
