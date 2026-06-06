import AppKit

public enum MenuBarIcon {
    private static let canvasSize = NSSize(width: 18, height: 18)

    public static let image: NSImage = {
        let image = NSImage(size: canvasSize)
        let representation = NSCustomImageRep(size: canvasSize, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else {
                return false
            }

            context.saveGState()
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.translateBy(x: rect.minX, y: rect.minY)
            context.scaleBy(
                x: rect.width / canvasSize.width,
                y: rect.height / canvasSize.height
            )
            drawIcon()
            context.restoreGState()

            return true
        }

        image.addRepresentation(representation)
        image.isTemplate = true
        return image
    }()

    private static func drawIcon() {
        let backWindow = NSBezierPath(roundedRect: NSRect(x: 5.0, y: 5.7, width: 9.5, height: 8.4), xRadius: 2.1, yRadius: 2.1)
        backWindow.lineWidth = 1.35
        backWindow.lineJoinStyle = .round
        backWindow.lineCapStyle = .round
        NSColor.black.withAlphaComponent(0.42).setStroke()
        backWindow.stroke()

        let folderPath = NSBezierPath()
        folderPath.lineWidth = 1.65
        folderPath.lineJoinStyle = .round
        folderPath.lineCapStyle = .round

        folderPath.move(to: NSPoint(x: 3.0, y: 5.2))
        folderPath.line(to: NSPoint(x: 3.0, y: 10.9))
        folderPath.curve(to: NSPoint(x: 4.0, y: 11.9), controlPoint1: NSPoint(x: 3.0, y: 11.5), controlPoint2: NSPoint(x: 3.4, y: 11.9))
        folderPath.line(to: NSPoint(x: 6.0, y: 11.9))
        folderPath.curve(to: NSPoint(x: 7.1, y: 12.9), controlPoint1: NSPoint(x: 6.5, y: 11.9), controlPoint2: NSPoint(x: 6.6, y: 12.9))
        folderPath.line(to: NSPoint(x: 10.0, y: 12.9))
        folderPath.curve(to: NSPoint(x: 11.1, y: 11.9), controlPoint1: NSPoint(x: 10.6, y: 12.9), controlPoint2: NSPoint(x: 10.6, y: 11.9))
        folderPath.line(to: NSPoint(x: 14.2, y: 11.9))
        folderPath.curve(to: NSPoint(x: 15.0, y: 11.1), controlPoint1: NSPoint(x: 14.7, y: 11.9), controlPoint2: NSPoint(x: 15.0, y: 11.6))
        folderPath.line(to: NSPoint(x: 15.0, y: 5.2))
        folderPath.curve(to: NSPoint(x: 14.0, y: 4.2), controlPoint1: NSPoint(x: 15.0, y: 4.6), controlPoint2: NSPoint(x: 14.6, y: 4.2))
        folderPath.line(to: NSPoint(x: 4.0, y: 4.2))
        folderPath.curve(to: NSPoint(x: 3.0, y: 5.2), controlPoint1: NSPoint(x: 3.4, y: 4.2), controlPoint2: NSPoint(x: 3.0, y: 4.6))
        folderPath.close()
        NSColor.black.setStroke()
        folderPath.stroke()

        let historyLines = NSBezierPath()
        historyLines.lineWidth = 1.45
        historyLines.lineCapStyle = .round
        for y in [7.2, 9.0] {
            historyLines.move(to: NSPoint(x: 5.5, y: y))
            historyLines.line(to: NSPoint(x: 12.5, y: y))
        }
        historyLines.stroke()
    }
}
