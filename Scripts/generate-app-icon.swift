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

    let glassFace = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.196, dy: size * 0.196))
    NSGradient(colors: [
        highlight.withAlphaComponent(0.26),
        elevated.withAlphaComponent(0.70),
        surface.withAlphaComponent(0.88)
    ])?.draw(in: glassFace, angle: -42)

    let faceStroke = NSBezierPath(ovalIn: rect.insetBy(dx: size * 0.206, dy: size * 0.206))
    highlight.withAlphaComponent(0.32).setStroke()
    faceStroke.lineWidth = max(1.4, size * 0.017)
    faceStroke.stroke()

    let center = NSPoint(x: size * 0.5, y: size * 0.5)
    let progress = NSBezierPath()
    progress.appendArc(withCenter: center, radius: size * 0.343, startAngle: 135, endAngle: -48, clockwise: true)
    accent.setStroke()
    progress.lineCapStyle = .round
    progress.lineWidth = max(4, size * 0.072)
    progress.stroke()

    let hands = NSBezierPath()
    hands.move(to: center)
    hands.line(to: NSPoint(x: size * 0.5, y: size * 0.684))
    hands.move(to: center)
    hands.line(to: NSPoint(x: size * 0.648, y: size * 0.425))
    text.withAlphaComponent(0.94).setStroke()
    hands.lineCapStyle = .round
    hands.lineWidth = max(2.2, size * 0.034)
    hands.stroke()

    let centerDot = NSBezierPath(ovalIn: NSRect(x: size * 0.466, y: size * 0.466, width: size * 0.068, height: size * 0.068))
    text.withAlphaComponent(0.98).setFill()
    centerDot.fill()

    let focusDot = NSBezierPath(ovalIn: NSRect(x: size * 0.708, y: size * 0.708, width: size * 0.082, height: size * 0.082))
    accent.withAlphaComponent(0.92).setFill()
    focusDot.fill()

    let shine = NSBezierPath()
    shine.move(to: NSPoint(x: size * 0.305, y: size * 0.690))
    shine.curve(
        to: NSPoint(x: size * 0.565, y: size * 0.755),
        controlPoint1: NSPoint(x: size * 0.365, y: size * 0.765),
        controlPoint2: NSPoint(x: size * 0.482, y: size * 0.790)
    )
    shine.lineCapStyle = .round
    shine.lineWidth = max(2, size * 0.030)
    highlight.withAlphaComponent(0.30).setStroke()
    shine.stroke()

    let lensGlint = NSBezierPath(ovalIn: NSRect(x: size * 0.278, y: size * 0.644, width: size * 0.052, height: size * 0.052))
    highlight.withAlphaComponent(0.18).setFill()
    lensGlint.fill()

    let focusDotHalo = NSBezierPath(ovalIn: NSRect(x: size * 0.691, y: size * 0.691, width: size * 0.116, height: size * 0.116))
    accent.withAlphaComponent(0.18).setStroke()
    focusDotHalo.lineWidth = max(1, size * 0.012)
    focusDotHalo.stroke()

    let edgeGlow = NSBezierPath(roundedRect: tileRect.insetBy(dx: size * 0.014, dy: size * 0.014), xRadius: tileRadius, yRadius: tileRadius)
    accent.withAlphaComponent(0.10).setFill()
    edgeGlow.fill()

    let edge = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
    highlight.withAlphaComponent(0.24).setStroke()
    edge.lineWidth = max(1, size * 0.012)
    edge.stroke()

    let accentEdge = NSBezierPath(roundedRect: tileRect.insetBy(dx: size * 0.012, dy: size * 0.012), xRadius: tileRadius, yRadius: tileRadius)
    accent.withAlphaComponent(0.18).setStroke()
    accentEdge.lineWidth = max(1, size * 0.010)
    accentEdge.stroke()

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
