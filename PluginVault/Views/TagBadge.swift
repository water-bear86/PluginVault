import SwiftUI

struct TagBadge: View {
    let tag: String
    var onRemove: (() -> Void)?

    init(tag: String, onRemove: (() -> Void)? = nil) {
        self.tag = tag
        self.onRemove = onRemove
    }

    var body: some View {
        ClassicTagBadge(
            tag: tag,
            isRemovable: onRemove != nil,
            style: .plain,
            onRemove: onRemove
        )
    }
}

#Preview("TagBadge") {
    VStack(alignment: .leading, spacing: 8) {
        TagBadge(tag: "example")
        TagBadge(tag: "removable") {}
    }
    .padding()
}
