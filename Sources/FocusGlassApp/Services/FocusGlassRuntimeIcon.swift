import AppKit

enum FocusGlassIconRenderer {
    static func image(theme: ThemeProfile, size: CGFloat = 128) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        defer { image.unlockFocus() }

        drawIcon(theme: theme, size: size)
        return image
    }

    private static func drawIcon(theme: ThemeProfile, size: CGFloat) {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSColor.clear.setFill()
        rect.fill()

        let backgroundTop = NSColor(hex: theme.backgroundTopHex)
        let backgroundMid = NSColor(hex: theme.backgroundMidHex)
        let backgroundBottom = NSColor(hex: theme.backgroundBottomHex)
        let surface = NSColor(hex: theme.surfaceHex)
        let elevated = NSColor(hex: theme.elevatedSurfaceHex)
        let accent = NSColor(hex: theme.primaryHex)
        let secondary = NSColor(hex: theme.secondaryHex)
        let highlight = NSColor(hex: theme.highlightHex)
        let text = NSColor(hex: theme.textHex)

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
        progress.appendArc(
            withCenter: center,
            radius: size * 0.272,
            startAngle: 126,
            endAngle: -42,
            clockwise: true
        )
        accent.setStroke()
        progress.lineCapStyle = .round
        progress.lineWidth = max(4, size * 0.060)
        progress.stroke()

        let restArc = NSBezierPath()
        restArc.appendArc(
            withCenter: center,
            radius: size * 0.272,
            startAngle: -52,
            endAngle: 112,
            clockwise: true
        )
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

        let centerDot = NSBezierPath(ovalIn: NSRect(
            x: size * 0.466,
            y: size * 0.466,
            width: size * 0.068,
            height: size * 0.068
        ))
        text.withAlphaComponent(0.98).setFill()
        centerDot.fill()

        let focusDot = NSBezierPath(ovalIn: NSRect(
            x: size * 0.704,
            y: size * 0.704,
            width: size * 0.060,
            height: size * 0.060
        ))
        accent.withAlphaComponent(0.92).setFill()
        focusDot.fill()

        let shine = NSBezierPath(roundedRect: NSRect(
            x: size * 0.285,
            y: size * 0.735,
            width: size * 0.30,
            height: size * 0.036
        ), xRadius: size * 0.018, yRadius: size * 0.018)
        highlight.withAlphaComponent(0.34).setFill()
        shine.fill()

        let edge = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
        edge.lineWidth = max(1, size * 0.012)
        highlight.withAlphaComponent(0.24).setStroke()
        edge.stroke()
    }
}

enum FocusGlassRuntimeIcon {
    static func image(theme: ThemeProfile, size: CGFloat = 128) -> NSImage {
        FocusGlassIconRenderer.image(theme: theme, size: size)
    }
}
