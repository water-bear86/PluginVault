import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        // Defer window access until the view is in a window
        DispatchQueue.main.async {
            if let window = view.window {
                // Hide the title and make the title bar area transparent
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                // Allow dragging the window by clicking/dragging the background
                window.isMovableByWindowBackground = true
                // Hide standard traffic light buttons
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // No-op
    }
}
