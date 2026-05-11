import SwiftUI

// ============================================
// MARK: - Classic Mac OS Colors
// ============================================
struct ClassicMac {
    static let windowBackground = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let white = Color.white
    static let black = Color.black
    static let darkGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let mediumGray = Color(red: 0.6, green: 0.6, blue: 0.6)
    static let lightGray = Color(red: 0.87, green: 0.87, blue: 0.87)
    static let highlight = Color.black
    static let highlightText = Color.white
}

// ============================================
// MARK: - Classic Mac Fonts
// ============================================
struct ClassicFonts {
    static let title = Font.custom("Geneva", size: 12).weight(.bold)
    static let body = Font.custom("Geneva", size: 11)
    static let caption = Font.custom("Geneva", size: 9)
    static let menu = Font.custom("Chicago", size: 12)
    
    // Fallbacks
    static let titleFallback = Font.system(size: 12, weight: .bold, design: .monospaced)
    static let bodyFallback = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let captionFallback = Font.system(size: 9, weight: .regular, design: .monospaced)
}

// ============================================
// MARK: - Desktop Pattern
// ============================================
struct DesktopPattern: View {
    var body: some View {
        Canvas { context, size in
            // Classic Mac dither pattern
            for y in stride(from: 0, to: size.height, by: 2) {
                for x in stride(from: Int(y.truncatingRemainder(dividingBy: 4) == 0 ? 0 : 1), to: Int(size.width), by: 2) {
                    let rect = CGRect(x: CGFloat(x), y: y, width: 1, height: 1)
                    context.fill(Path(rect), with: .color(Color(white: 0.55)))
                }
            }
        }
        .background(Color(white: 0.7))
    }
}

// ============================================
// MARK: - Classic Window
// ============================================
struct ClassicWindow<Content: View>: View {
    let title: String
    let onClose: (() -> Void)?
    let content: Content
    
    init(title: String, onClose: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ClassicTitleBar(title: title, onClose: onClose)
            content.background(ClassicMac.windowBackground)
        }
        .background(ClassicMac.windowBackground)
        .overlay(ClassicOutsetBorderShape())
        .shadow(color: .black.opacity(0.6), radius: 0, x: 2, y: 2)
    }
}

// ============================================
// MARK: - Classic Title Bar with Stripes
// ============================================
struct ClassicTitleBar: View {
    let title: String
    let onClose: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Striped background
            StripedBackground()
                .frame(height: 20)
            
            HStack {
                // Close box
                if let onClose = onClose {
                    ClassicCloseBox(action: onClose)
                        .padding(.leading, 8)
                } else {
                    Rectangle().fill(Color.clear).frame(width: 20)
                }
                
                Spacer()
                
                // Title in white box
                Text(title)
                    .font(ClassicFonts.titleFallback)
                    .foregroundColor(ClassicMac.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(ClassicMac.white)
                
                Spacer()
                
                Rectangle().fill(Color.clear).frame(width: 20).padding(.trailing, 8)
            }
        }
        .frame(height: 20)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(ClassicMac.black),
            alignment: .bottom
        )
    }
}

// ============================================
// MARK: - Striped Background
// ============================================
struct StripedBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 2) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(ClassicMac.black))
                }
            }
            .background(ClassicMac.white)
        }
    }
}

// ============================================
// MARK: - Classic Close Box
// ============================================
struct ClassicCloseBox: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isPressed ? ClassicMac.black : ClassicMac.white)
                    .frame(width: 13, height: 13)
                
                Rectangle()
                    .stroke(ClassicMac.black, lineWidth: 1)
                    .frame(width: 13, height: 13)
                
                Rectangle()
                    .stroke(ClassicMac.darkGray, lineWidth: 1)
                    .frame(width: 9, height: 9)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// ============================================
// MARK: - Classic Button
// ============================================
struct ClassicButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                }
                Text(title)
                    .font(ClassicFonts.bodyFallback)
            }
            .foregroundColor(ClassicMac.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(isPressed ? ClassicMac.mediumGray : ClassicMac.windowBackground)
            .overlay(ClassicButtonBorder(isPressed: isPressed))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// ============================================
// MARK: - Classic Default Button (with thick border)
// ============================================
struct ClassicDefaultButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ClassicFonts.bodyFallback)
                .fontWeight(.medium)
                .foregroundColor(ClassicMac.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 5)
                .background(isPressed ? ClassicMac.mediumGray : ClassicMac.windowBackground)
                .overlay(ClassicButtonBorder(isPressed: isPressed))
        }
        .buttonStyle(.plain)
        .padding(3)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(ClassicMac.black, lineWidth: 3)
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// ============================================
// MARK: - Classic Button Border (3D Bevel)
// ============================================
struct ClassicButtonBorder: View {
    let isPressed: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            // Outer black border
            Rectangle().stroke(ClassicMac.black, lineWidth: 1)
            
            // Top-left highlight
            Path { path in
                path.move(to: CGPoint(x: 1, y: h - 2))
                path.addLine(to: CGPoint(x: 1, y: 1))
                path.addLine(to: CGPoint(x: w - 2, y: 1))
            }
            .stroke(isPressed ? ClassicMac.darkGray : ClassicMac.white, lineWidth: 1)
            
            // Bottom-right shadow
            Path { path in
                path.move(to: CGPoint(x: w - 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: h - 1))
            }
            .stroke(isPressed ? ClassicMac.white : ClassicMac.darkGray, lineWidth: 1)
            
            // Inner top-left
            Path { path in
                path.move(to: CGPoint(x: 2, y: h - 3))
                path.addLine(to: CGPoint(x: 2, y: 2))
                path.addLine(to: CGPoint(x: w - 3, y: 2))
            }
            .stroke(isPressed ? ClassicMac.mediumGray : ClassicMac.lightGray, lineWidth: 1)
            
            // Inner bottom-right
            Path { path in
                path.move(to: CGPoint(x: w - 2, y: 2))
                path.addLine(to: CGPoint(x: w - 2, y: h - 2))
                path.addLine(to: CGPoint(x: 2, y: h - 2))
            }
            .stroke(isPressed ? ClassicMac.lightGray : ClassicMac.mediumGray, lineWidth: 1)
        }
    }
}

// ============================================
// MARK: - Classic Outset Border Shape
// ============================================
struct ClassicOutsetBorderShape: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            Rectangle().stroke(ClassicMac.black, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: 1))
            }
            .stroke(ClassicMac.white, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: w - 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: h - 1))
            }
            .stroke(ClassicMac.darkGray, lineWidth: 1)
        }
    }
}

// ============================================
// MARK: - Classic Inset Border
// ============================================
struct ClassicInsetBorder: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            Rectangle().stroke(ClassicMac.black, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: 1))
            }
            .stroke(ClassicMac.darkGray, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: w - 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: h - 1))
            }
            .stroke(ClassicMac.white, lineWidth: 1)
        }
    }
}

// ============================================
// MARK: - Classic Text Field
// ============================================
struct ClassicTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .font(ClassicFonts.bodyFallback)
            .textFieldStyle(.plain)
            .padding(5)
            .background(ClassicMac.white)
            .overlay(ClassicInsetBorder())
    }
}

// ============================================
// MARK: - Classic Group Box
// ============================================
struct ClassicGroupBox<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(ClassicFonts.bodyFallback)
                    .fontWeight(.bold)
                    .padding(.leading, 4)
                    .padding(.bottom, 4)
            }
            
            content
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClassicMac.windowBackground)
                .overlay(
                    GeometryReader { geometry in
                        let w = geometry.size.width
                        let h = geometry.size.height
                        
                        // Etched border (dark on top-left, light on bottom-right)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: h))
                            path.addLine(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: w, y: 0))
                        }
                        .stroke(ClassicMac.darkGray, lineWidth: 1)
                        
                        Path { path in
                            path.move(to: CGPoint(x: w, y: 0))
                            path.addLine(to: CGPoint(x: w, y: h))
                            path.addLine(to: CGPoint(x: 0, y: h))
                        }
                        .stroke(ClassicMac.white, lineWidth: 1)
                    }
                )
        }
    }
}

// ============================================
// MARK: - Classic Separator
// ============================================
struct ClassicSeparator: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(ClassicMac.darkGray).frame(height: 1)
            Rectangle().fill(ClassicMac.white).frame(height: 1)
        }
    }
}

// ============================================
// MARK: - Classic Menu Bar
// ============================================
struct ClassicMenuBar: View {
    let appName: String
    let menuItems: [String]
    var scanAction: (() -> Void)?
    var vaultUntaggedAction: (() -> Void)?
    var unvaultAllAction: (() -> Void)?
    
    init(appName: String, menuItems: [String], scanAction: (() -> Void)? = nil, vaultUntaggedAction: (() -> Void)? = nil, unvaultAllAction: (() -> Void)? = nil) {
        self.appName = appName
        self.menuItems = menuItems
        self.scanAction = scanAction
        self.vaultUntaggedAction = vaultUntaggedAction
        self.unvaultAllAction = unvaultAllAction
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Apple logo
            Text("⌘")
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 14)
            
            // App name (bold)
            Text(appName)
                .font(ClassicFonts.bodyFallback)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
            
            // Menu items
            ForEach(menuItems, id: \.self) { item in
                if item == "Plugins" && scanAction != nil {
                    Menu {
                        Button("Scan Plugins") { scanAction?() }
                        Divider()
                        Button("Vault Untagged") { vaultUntaggedAction?() }
                        Button("Unvault All") { unvaultAllAction?() }
                    } label: {
                        Text(item)
                            .font(ClassicFonts.bodyFallback)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                } else {
                    Text(item)
                        .font(ClassicFonts.bodyFallback)
                        .padding(.horizontal, 12)
                }
            }
            
            Spacer()
        }
        .frame(height: 22)
        .background(ClassicMac.white)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(ClassicMac.black),
            alignment: .bottom
        )
    }
}

// ============================================
// MARK: - Classic Checkbox
// ============================================
struct ClassicCheckbox: View {
    @Binding var isOn: Bool
    let label: String?
    
    init(isOn: Binding<Bool>, label: String? = nil) {
        self._isOn = isOn
        self.label = label
    }
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 6) {
                ZStack {
                    Rectangle()
                        .fill(ClassicMac.white)
                        .frame(width: 14, height: 14)
                        .overlay(ClassicInsetBorder())
                    
                    if isOn {
                        Path { path in
                            path.move(to: CGPoint(x: 3, y: 7))
                            path.addLine(to: CGPoint(x: 6, y: 11))
                            path.addLine(to: CGPoint(x: 11, y: 3))
                        }
                        .stroke(ClassicMac.black, lineWidth: 2)
                        .frame(width: 14, height: 14)
                    }
                }
                
                if let label = label {
                    Text(label)
                        .font(ClassicFonts.bodyFallback)
                        .foregroundColor(ClassicMac.black)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// ============================================
// MARK: - Classic Pop-Up Button
// ============================================
struct ClassicPopupButton<Option: Hashable>: View {
    @Binding var selection: Option
    let options: [Option]
    let width: CGFloat?
    let label: String?
    let optionTitle: (Option) -> String
    let onSelect: ((Option) -> Void)?
    @State private var isExpanded = false
    
    init(
        selection: Binding<Option>,
        options: [Option],
        width: CGFloat? = nil,
        label: String? = nil,
        optionTitle: @escaping (Option) -> String,
        onSelect: ((Option) -> Void)? = nil
    ) {
        self._selection = selection
        self.options = options
        self.width = width
        self.label = label
        self.optionTitle = optionTitle
        self.onSelect = onSelect
    }
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 6) {
                Text(label ?? optionTitle(selection))
                    .font(ClassicFonts.bodyFallback)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                Text(isExpanded ? "▲" : "▼")
                    .font(ClassicFonts.captionFallback)
            }
            .foregroundColor(options.isEmpty ? ClassicMac.darkGray : ClassicMac.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: width, alignment: .leading)
            .background(options.isEmpty ? ClassicMac.lightGray : ClassicMac.windowBackground)
            .overlay(ClassicButtonBorder(isPressed: isExpanded))
        }
        .buttonStyle(.plain)
        .disabled(options.isEmpty)
        .overlay(alignment: .topLeading) {
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        Button(action: { choose(option) }) {
                            HStack(spacing: 6) {
                                Text(selection == option ? "✓" : "")
                                    .font(ClassicFonts.captionFallback)
                                    .frame(width: 12)
                                
                                Text(optionTitle(option))
                                    .font(ClassicFonts.bodyFallback)
                                    .lineLimit(1)
                                
                                Spacer(minLength: 8)
                            }
                            .foregroundColor(selection == option ? ClassicMac.white : ClassicMac.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .frame(width: width, alignment: .leading)
                            .background(selection == option ? ClassicMac.black : ClassicMac.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(ClassicMac.white)
                .overlay(ClassicInsetBorder())
                .offset(y: 24)
                .zIndex(20)
            }
        }
        .zIndex(isExpanded ? 20 : 0)
    }
    
    private func toggle() {
        guard !options.isEmpty else { return }
        isExpanded.toggle()
    }
    
    private func choose(_ option: Option) {
        selection = option
        isExpanded = false
        onSelect?(option)
    }
}

// ============================================
// MARK: - Classic Tag Badge
// ============================================
enum ClassicTagBadgeStyle {
    case plain
    case selected
}

struct ClassicTagBadge: View {
    let tag: String
    let isRemovable: Bool
    let style: ClassicTagBadgeStyle
    let onRemove: (() -> Void)?
    
    init(
        tag: String,
        isRemovable: Bool = false,
        style: ClassicTagBadgeStyle = .plain,
        onRemove: (() -> Void)? = nil
    ) {
        self.tag = tag
        self.isRemovable = isRemovable
        self.style = style
        self.onRemove = onRemove
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(ClassicFonts.captionFallback)
                .lineLimit(1)
            
            if isRemovable, let onRemove {
                Button(action: onRemove) {
                    Text("×")
                        .font(ClassicFonts.bodyFallback)
                        .fontWeight(.bold)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .overlay(Rectangle().stroke(ClassicMac.black, lineWidth: 1))
    }
    
    private var backgroundColor: Color {
        style == .selected ? ClassicMac.black : ClassicMac.lightGray
    }
    
    private var foregroundColor: Color {
        style == .selected ? ClassicMac.white : ClassicMac.black
    }
}

// ============================================
// MARK: - Classic Status Indicator
// ============================================
struct ClassicStatusIndicator: View {
    let isLoading: Bool
    let message: String
    
    var body: some View {
        HStack(spacing: 5) {
            Text(isLoading ? "◐" : "✓")
                .font(ClassicFonts.captionFallback)
                .frame(width: 14)
            
            Text(message)
                .font(ClassicFonts.captionFallback)
                .lineLimit(1)
        }
        .foregroundColor(ClassicMac.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: 130, alignment: .leading)
        .background(ClassicMac.white)
        .overlay(ClassicInsetBorder())
    }
}

// ============================================
// MARK: - Flow Layout
// ============================================
struct FlowLayout: Layout {
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + lineHeight
        }
    }
}

// ============================================
// MARK: - View Extensions
// ============================================
extension View {
    func classicOutsetBorder() -> some View {
        self.overlay(ClassicOutsetBorderShape())
    }
    
    func classicInsetBorder() -> some View {
        self.overlay(ClassicInsetBorder())
    }
}
