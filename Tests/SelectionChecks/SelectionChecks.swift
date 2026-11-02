import AppKit

// Native regression checks exercise the actual selector, not a cursor mock.
@main enum SelectionChecks {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()
        app.activate(ignoringOtherApps: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            var failures = 0
            var lines: [String] = []
            func check(_ condition: Bool, _ message: String) {
                if condition { lines.append("PASS: \(message)") }
                else { failures += 1; lines.append("FAIL: \(message)") }
            }
            let selector = RegionSelector()
            NSCursor.arrow.set()
            selector.show()
            check(NSCursor.current === NSCursor.crosshair, "enter selection shows crosshair before any click or mouse move")
            let overlays = app.windows.filter { $0.isVisible && $0.contentView is SelectionView }
            check(!overlays.isEmpty, "selection overlays exist")
            let pointer = NSEvent.mouseLocation
            if let expected = overlays.first(where: { $0.frame.contains(pointer) }) {
                // Background-launched test apps may not become active until a user gesture.
                // The pointed display must already route that first gesture to its selection view.
                check(expected.firstResponder === expected.contentView, "screen under the pointer is ready to receive the first drag")
            }
            for window in overlays {
                guard let view = window.contentView as? SelectionView else { continue }
                check(view.acceptsFirstMouse(for: nil), "first press is delivered without an activation click")
                // An AppKit tracking event must restore the crosshair on a non-key overlay too.
                NSCursor.arrow.set()
                if let event = NSEvent.mouseEvent(with: .mouseMoved, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 0, pressure: 0) {
                    view.mouseMoved(with: event)
                    check(NSCursor.current === NSCursor.crosshair, "moving within any screen keeps the selection cursor")
                }
            }
            NSCursor.crosshair.set()
            selector.dismiss()
            check(NSCursor.current === NSCursor.arrow, "dismissal restores the normal pointer")
            check(!app.windows.contains { $0.isVisible && $0.contentView is SelectionView }, "dismissal removes all selection overlays")
            // Re-entering must be safe, and a queued cursor refresh must not leak past cancellation.
            selector.show(); selector.dismiss()
            DispatchQueue.main.async {
                check(NSCursor.current === NSCursor.arrow, "cancel before the next event loop does not leave a crosshair")
                let defaultOutput = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent(".build/checks/selection-result.txt")
                let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultOutput.path
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: output).deletingLastPathComponent(), withIntermediateDirectories: true)
                let summary = "Selection checks: \(failures) failure(s)\n"
                try? (lines.joined(separator: "\n") + "\n" + summary).write(toFile: output, atomically: true, encoding: .utf8)
                print(summary, terminator: "")
                exit(failures == 0 ? 0 : 1)
            }
        }
        app.run()
    }
}
