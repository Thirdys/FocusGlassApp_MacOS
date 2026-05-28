import AppKit
import Foundation

let outputDirectory = CommandLine.arguments.dropFirst().first.map(URL.init(fileURLWithPath:))
    ?? URL(fileURLWithPath: "Resources/AppIcon.iconset")

let fileManager = FileManager.default
try? fileManager.removeItem(at: outputDirectory)
try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let sizes: [(name: String, size: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let backgroundTop = NSColor(hex: "#09090d")
let backgroundMid = NSColor(hex: "#151018")
let backgroundBottom = NSColor(hex: "#030305")
let surface = NSColor(hex: "#151217")
let elevated = NSColor(hex: "#21191f")
let accent = NSColor(hex: "#ff4d57")
let secondary = NSColor(hex: "#7c86ff")
let text = NSColor(hex: "#f6f8ff")
let highlight = NSColor.white

func drawIconData(size: CGFloat) -> Data? {
    let pixelSize = Int(size)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return nil
    }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let tileRect = rect.insetBy(dx: size * 0.065, dy: size * 0.065)
    let tileRadius = size * 0.225
    let tile = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
    NSGradient(colors: [backgroundTop, backgroundMid, backgroundBottom])?.draw(in: tile, angle: -42)

    let innerTile = tileRect.insetBy(dx: size * 0.045, dy: size * 0.045)
    let glassPanel = NSBezierPath(roundedRect: innerTile, xRadius: size * 0.185, yRadius: size * 0.185)
    NSGradient(colors: [
        highlight.withAlphaComponent(0.18),
        elevated.withAlphaComponent(0.62),
        surface.withAlphaComponent(0.74)
    ])?.draw(in: glassPanel, angle: -38)

    let dialRect = rect.insetBy(dx: size * 0.245, dy: size * 0.245)
    let dial = NSBezierPath(ovalIn: dialRect)
    NSGradient(colors: [
        highlight.withAlphaComponent(0.34),
        surface.withAlphaComponent(0.56),
        backgroundBottom.withAlphaComponent(0.28)
    ])?.draw(in: dial, angle: -45)

    let dialStroke = NSBezierPath(ovalIn: dialRect.insetBy(dx: size * 0.01, dy: size * 0.01))
    highlight.withAlphaComponent(0.30).setStroke()
    dialStroke.lineWidth = max(1.2, size * 0.016)
    dialStroke.stroke()

    let center = NSPoint(x: size * 0.5, y: size * 0.5)
    let progress = NSBezierPath()
    progress.appendArc(withCenter: center, radius: size * 0.272, startAngle: 126, endAngle: -42, clockwise: true)
    accent.setStroke()
    progress.lineCapStyle = .round
    progress.lineWidth = max(4, size * 0.060)
    progress.stroke()

    let restArc = NSBezierPath()
    restArc.appendArc(withCenter: center, radius: size * 0.272, startAngle: -52, endAngle: 112, clockwise: true)
    secondary.withAlphaComponent(0.34).setStroke()
    restArc.lineCapStyle = .round
    restArc.lineWidth = max(2, size * 0.032)
    restArc.stroke()

    let hands = NSBezierPath()
    hands.move(to: center)
    hands.line(to: NSPoint(x: size * 0.5, y: size * 0.64))
    hands.move(to: center)
    hands.line(to: NSPoint(x: size * 0.61, y: size * 0.455))
    text.withAlphaComponent(0.94).setStroke()
    hands.lineCapStyle = .round
    hands.lineWidth = max(2, size * 0.028)
    hands.stroke()

    let centerDot = NSBezierPath(ovalIn: NSRect(x: size * 0.466, y: size * 0.466, width: size * 0.068, height: size * 0.068))
    text.withAlphaComponent(0.98).setFill()
    centerDot.fill()

    let focusDot = NSBezierPath(ovalIn: NSRect(x: size * 0.704, y: size * 0.704, width: size * 0.060, height: size * 0.060))
    accent.withAlphaComponent(0.92).setFill()
    focusDot.fill()

    let shine = NSBezierPath(roundedRect: NSRect(x: size * 0.285, y: size * 0.735, width: size * 0.30, height: size * 0.036), xRadius: size * 0.018, yRadius: size * 0.018)
    highlight.withAlphaComponent(0.34).setFill()
    shine.fill()

    let edge = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
    highlight.withAlphaComponent(0.24).setStroke()
    edge.lineWidth = max(1, size * 0.012)
    edge.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

for item in sizes {
    guard let data = drawIconData(size: item.size) else {
        continue
    }
    try data.write(to: outputDirectory.appendingPathComponent(item.name))
}

extension NSColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xff) / 255
        let g = CGFloat((value >> 8) & 0xff) / 255
        let b = CGFloat(value & 0xff) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
