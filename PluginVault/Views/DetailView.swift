import SwiftUI

struct DetailView: View {
    @EnvironmentObject var pm: PluginManager
    @Environment(\.dismiss) var dismiss
    let plugin: Plugin
    @State private var newTag = ""
    
    var current: Plugin {
        pm.plugins.first { $0.originalPath == plugin.originalPath } ?? plugin
    }
    
    var body: some View {
        ClassicWindow(title: current.name, onClose: { dismiss() }) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Plugin Info")
                        .font(ClassicFonts.bodyFallback)
                        .fontWeight(.bold)
                    ClassicSeparator()
                    InfoRow("Name:",   current.name)
                    InfoRow("Type:",   current.pluginType.rawValue)
                    InfoRow("Status:", "\(current.statusIcon) \(current.isVaulted ? "Vaulted" : "Active")")
                    Text("Path:")
                        .font(ClassicFonts.bodyFallback)
                        .fontWeight(.bold)
                    Text(current.path)
                        .font(ClassicFonts.captionFallback)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(10)
                .background(.background)
                .overlay(InsetBorder())
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tags")
                        .font(ClassicFonts.bodyFallback)
                        .fontWeight(.bold)
                    ClassicSeparator()
                    if current.tags.isEmpty {
                        Text("No tags")
                            .font(ClassicFonts.bodyFallback)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        TagFlowLayout(spacing: 4) {
                            ForEach(current.tags, id: \.self) { tag in
                                TagBadge(tag: tag) { pm.removeTag(tag, from: current) }
                            }
                        }
                    }
                    ClassicSeparator()
                    HStack(spacing: 8) {
                        TextField("New tag...", text: $newTag)
                        Button("Add", action: addTag)
                        // Add from existing tags
                        Menu {
                            let available = pm.allTags.filter { !current.tags.contains($0) }
                            if available.isEmpty {
                                Text("No available tags").foregroundColor(.secondary)
                            } else {
                                ForEach(available, id: \.self) { tag in
                                    Button(tag) {
                                        pm.addTag(tag, to: current)
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("＋")
                                Text("Add Existing Tag")
                            }
                        }
                        .disabled(pm.allTags.filter { !current.tags.contains($0) }.isEmpty)
                    }
                }
                .padding(10)
                .background(.background)
                .overlay(InsetBorder())
                
                ClassicSeparator()
                HStack {
                    Button(action: { pm.toggleVault(current) }) {
                        HStack(spacing: 6) {
                            Text(current.isVaulted ? "●" : "○")
                            Text(current.isVaulted ? "Restore" : "Vault")
                        }
                    }
                    Button(action: { pm.revealInFinder(current) }) {
                        HStack(spacing: 6) {
                            Text("⌘")
                            Text("Reveal in Finder")
                        }
                    }
                    Spacer()
                    Button("Done") { dismiss() }
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

struct InsetBorder: View {
    var cornerRadius: CGFloat = 6
    var lineWidth: CGFloat = 1
    var color: Color = .secondary.opacity(0.3)
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .inset(by: lineWidth / 2)
            .stroke(color, lineWidth: lineWidth)
    }
}

private struct TagFlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                // move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + (currentX == 0 ? 0 : spacing)
        }
        return CGSize(width: currentX, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                // wrap to next line
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + (x == 0 ? 0 : spacing)
            lineHeight = max(lineHeight, size.height)
        }
    }
}
