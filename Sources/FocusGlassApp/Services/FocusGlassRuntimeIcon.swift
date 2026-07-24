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
        let highlight = NSColor(hex: theme.highlightHex)
        let text = NSColor(hex: theme.textHex)

        let tileRect = rect.insetBy(
            dx: size * FocusGlassMarkGeometry.tileInset,
            dy: size * FocusGlassMarkGeometry.tileInset
        )
        let tileRadius = size * FocusGlassMarkGeometry.tileCornerRadius
        let tile = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
        NSGradient(colors: [backgroundTop, backgroundMid, backgroundBottom])?.draw(in: tile, angle: -42)

        let glassFace = NSBezierPath(ovalIn: rect.insetBy(
            dx: size * FocusGlassMarkGeometry.faceInset,
            dy: size * FocusGlassMarkGeometry.faceInset
        ))
        NSGradient(colors: [
            highlight.withAlphaComponent(0.26),
            elevated.withAlphaComponent(0.70),
            surface.withAlphaComponent(0.88)
        ])?.draw(in: glassFace, angle: -42)

        let faceStroke = NSBezierPath(ovalIn: rect.insetBy(
            dx: size * FocusGlassMarkGeometry.faceStrokeInset,
            dy: size * FocusGlassMarkGeometry.faceStrokeInset
        ))
        highlight.withAlphaComponent(0.32).setStroke()
        faceStroke.lineWidth = max(1.4, size * 0.017)
        faceStroke.stroke()

        let center = NSPoint(x: size * 0.5, y: size * 0.5)
        let progress = NSBezierPath()
        progress.appendArc(
            withCenter: center,
            radius: size * FocusGlassMarkGeometry.progressRadius,
            startAngle: FocusGlassMarkGeometry.progressStartAngle,
            endAngle: FocusGlassMarkGeometry.progressEndAngle,
            clockwise: true
        )
        accent.setStroke()
        progress.lineCapStyle = .round
        progress.lineWidth = max(4, size * FocusGlassMarkGeometry.progressLineWidth)
        progress.stroke()

        let hands = NSBezierPath()
        hands.move(to: center)
        hands.line(to: NSPoint(
            x: size * FocusGlassMarkGeometry.minuteHandEnd.x,
            y: size * FocusGlassMarkGeometry.minuteHandEnd.y
        ))
        hands.move(to: center)
        hands.line(to: NSPoint(
            x: size * FocusGlassMarkGeometry.hourHandEnd.x,
            y: size * FocusGlassMarkGeometry.hourHandEnd.y
        ))
        text.withAlphaComponent(0.94).setStroke()
        hands.lineCapStyle = .round
        hands.lineWidth = max(2.2, size * FocusGlassMarkGeometry.handLineWidth)
        hands.stroke()

        let centerDot = NSBezierPath(ovalIn: FocusGlassMarkGeometry.appKitRect(
            x: FocusGlassMarkGeometry.centerDotOrigin,
            y: FocusGlassMarkGeometry.centerDotOrigin,
            width: FocusGlassMarkGeometry.centerDotSize,
            height: FocusGlassMarkGeometry.centerDotSize,
            size: size
        ))
        text.withAlphaComponent(0.98).setFill()
        centerDot.fill()

        let focusDot = NSBezierPath(ovalIn: FocusGlassMarkGeometry.appKitRect(
            x: FocusGlassMarkGeometry.focusDotX,
            y: FocusGlassMarkGeometry.focusDotY,
            width: FocusGlassMarkGeometry.focusDotSize,
            height: FocusGlassMarkGeometry.focusDotSize,
            size: size
        ))
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

        let lensGlint = NSBezierPath(ovalIn: NSRect(
            x: size * 0.278,
            y: size * 0.644,
            width: size * 0.052,
            height: size * 0.052
        ))
        highlight.withAlphaComponent(0.18).setFill()
        lensGlint.fill()

        let focusDotHalo = NSBezierPath(ovalIn: NSRect(
            x: size * 0.691,
            y: size * 0.691,
            width: size * 0.116,
            height: size * 0.116
        ))
        accent.withAlphaComponent(0.18).setStroke()
        focusDotHalo.lineWidth = max(1, size * 0.012)
        focusDotHalo.stroke()

        let edgeGlow = NSBezierPath(roundedRect: tileRect.insetBy(dx: size * 0.014, dy: size * 0.014), xRadius: tileRadius, yRadius: tileRadius)
        accent.withAlphaComponent(0.10).setFill()
        edgeGlow.fill()

        let edge = NSBezierPath(roundedRect: tileRect, xRadius: tileRadius, yRadius: tileRadius)
        edge.lineWidth = max(1, size * 0.012)
        highlight.withAlphaComponent(0.24).setStroke()
        edge.stroke()

        let accentEdge = NSBezierPath(roundedRect: tileRect.insetBy(dx: size * 0.012, dy: size * 0.012), xRadius: tileRadius, yRadius: tileRadius)
        accentEdge.lineWidth = max(1, size * 0.010)
        accent.withAlphaComponent(0.18).setStroke()
        accentEdge.stroke()
    }
}

enum FocusGlassRuntimeIcon {
    static func image(theme: ThemeProfile, size: CGFloat = 128) -> NSImage {
        FocusGlassIconRenderer.image(theme: theme, size: size)
    }
}
