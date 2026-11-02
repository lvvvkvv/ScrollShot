import CoreGraphics
public enum CaptureGeometry {
    /// AppKit's bottom-left screen coordinates -> ScreenCaptureKit's top-left display points.
    public static func sourceRect(selection: CGRect, screen: CGRect) -> CGRect? {
        guard selection.width >= 40, selection.height >= 40,
              screen.contains(selection) else { return nil }
        return CGRect(x: selection.minX - screen.minX, y: screen.maxY - selection.maxY,
                      width: selection.width, height: selection.height)
    }
}
