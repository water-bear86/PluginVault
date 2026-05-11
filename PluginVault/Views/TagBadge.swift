import SwiftUI

struct TagBadge: View {
    let tag: String
    var onRemove: (() -> Void)?

    init(tag: String, onRemove: (() -> Void)? = nil) {
        self.tag = tag
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(ClassicFonts.captionFallback)
                .padding(.vertical, 4)
                .padding(.leading, 8)
            if let onRemove {
                Button(action: onRemove) {
                    Text("×")
                        .font(ClassicFonts.captionFallback)
                        .fontWeight(.bold)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.plain)
                .background(Color.secondary.opacity(0.08))
                .clipShape(Capsule())
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.trailing, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.secondary.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .foregroundStyle(.primary)
    }
}

#Preview("TagBadge") {
    VStack(alignment: .leading, spacing: 8) {
        TagBadge(tag: "example")
        TagBadge(tag: "removable") {}
    }
    .padding()
}
