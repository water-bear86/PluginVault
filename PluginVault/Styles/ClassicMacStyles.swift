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
    static let bodyMediumFallback = Font.system(size: 11, weight: .medium, design: .monospaced)
    static let bodyBoldFallback = Font.system(size: 11, weight: .bold, design: .monospaced)
    static let captionFallback = Font.system(size: 9, weight: .regular, design: .monospaced)
    static let captionBoldFallback = Font.system(size: 9, weight: .bold, design: .monospaced)
}

// ============================================
// MARK: - Desktop Pattern
// ============================================
struct DesktopPattern: View {
    var body: some View {
        Color(white: 0.7)
            .overlay(DitherPatternShape().fill(Color(white: 0.55)))
    }
}

struct DitherPatternShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 0
        while y < rect.height {
            var x: CGFloat = y.truncatingRemainder(dividingBy: 4) == 0 ? 0 : 1
            while x < rect.width {
                path.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                x += 2
            }
            y += 2
        }
        return path
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
            content
                .foregroundColor(ClassicMac.black)
                .background(ClassicMac.windowBackground)
        }
        .foregroundColor(ClassicMac.black)
        .background(ClassicMac.windowBackground)
        .overlay(ClassicOutsetBorderShape())
        .background(
            Rectangle()
                .fill(ClassicMac.black)
                .offset(x: 2, y: 2)
        )
        .padding(.trailing, 2)
        .padding(.bottom, 2)
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
        ClassicMac.white
            .overlay(HorizontalStripeShape().fill(ClassicMac.black))
    }
}

struct HorizontalStripeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 0
        while y < rect.height {
            path.addRect(CGRect(x: 0, y: y, width: rect.width, height: 1))
            y += 2
        }
        return path
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
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(ClassicMac.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(isPressed ? ClassicMac.mediumGray : ClassicMac.windowBackground)
            .overlay(ClassicButtonBorder(isPressed: isPressed))
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: false)
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
                .font(ClassicFonts.bodyMediumFallback)
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
// MARK: - Classic Alert Dialog
// ============================================
struct ClassicAlertDialog: View {
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    init(
        title: String,
        message: String,
        primaryTitle: String = "OK",
        secondaryTitle: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .ignoresSafeArea()

            ClassicWindow(title: title, onClose: secondaryAction ?? primaryAction) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(message)
                        .font(ClassicFonts.bodyFallback)
                        .foregroundColor(ClassicMac.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ClassicSeparator()

                    HStack(spacing: 10) {
                        Spacer()

                        if let secondaryTitle, let secondaryAction {
                            ClassicButton(secondaryTitle, action: secondaryAction)
                        }

                        ClassicDefaultButton(title: primaryTitle, action: primaryAction)
                    }
                }
                .padding(16)
                .background(ClassicMac.windowBackground)
            }
            .frame(width: 360)
        }
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
            .foregroundColor(ClassicMac.black)
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
                    .font(ClassicFonts.bodyBoldFallback)
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
                .font(ClassicFonts.bodyBoldFallback)
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
                ClassicCheckboxIndicator(isOn: isOn)
                
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
// MARK: - Classic Checkbox Indicator
// ============================================
struct ClassicCheckboxIndicator: View {
    let isOn: Bool
    
    var body: some View {
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
            HStack(spacing: 0) {
                Text(label ?? optionTitle(selection))
                    .font(ClassicFonts.bodyFallback)
                    .lineLimit(1)
                    .foregroundColor(options.isEmpty ? ClassicMac.darkGray : ClassicMac.black)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClassicMac.white)
                
                ZStack {
                    Rectangle()
                        .fill(options.isEmpty ? ClassicMac.lightGray : ClassicMac.windowBackground)
                    
                    Text(isExpanded ? "▲" : "▼")
                        .font(ClassicFonts.captionFallback)
                        .foregroundColor(options.isEmpty ? ClassicMac.darkGray : ClassicMac.black)
                }
                .frame(width: 20)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(ClassicMac.black),
                    alignment: .leading
                )
            }
            .frame(height: 24)
            .frame(width: width, alignment: .leading)
            .background(ClassicMac.white)
            .overlay(ClassicPopupBorder(isPressed: isExpanded))
        }
        .buttonStyle(.plain)
        .disabled(options.isEmpty)
        .overlay(Group {
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
                .overlay(ClassicPopupBorder(isPressed: false))
                .offset(y: 24)
                .zIndex(20)
            }
        }, alignment: .topLeading)
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
// MARK: - Classic Pop-Up Border
// ============================================
struct ClassicPopupBorder: View {
    let isPressed: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            
            Rectangle()
                .stroke(ClassicMac.black, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: 1))
            }
            .stroke(isPressed ? ClassicMac.black : ClassicMac.darkGray, lineWidth: 1)
            
            Path { path in
                path.move(to: CGPoint(x: w - 1, y: 1))
                path.addLine(to: CGPoint(x: w - 1, y: h - 1))
                path.addLine(to: CGPoint(x: 1, y: h - 1))
            }
            .stroke(isPressed ? ClassicMac.darkGray : ClassicMac.white, lineWidth: 1)
        }
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
                        .font(ClassicFonts.bodyBoldFallback)
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
struct FlowLayout<Content: View>: View {
    var spacing: CGFloat = 4
    let content: Content
    
    init(spacing: CGFloat = 4, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 70), spacing: spacing, alignment: .leading)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
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
