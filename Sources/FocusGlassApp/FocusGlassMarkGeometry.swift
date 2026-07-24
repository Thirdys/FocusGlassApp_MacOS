import CoreGraphics

enum FocusGlassMarkGeometry {
    static let tileInset: CGFloat = 0.065
    static let tileCornerRadius: CGFloat = 0.225
    static let faceInset: CGFloat = 0.196
    static let faceStrokeInset: CGFloat = 0.206
    static let progressRadius: CGFloat = 0.343
    static let progressStartAngle: CGFloat = 135
    static let progressEndAngle: CGFloat = -48
    static let progressLineWidth: CGFloat = 0.072
    static let handLineWidth: CGFloat = 0.034
    static let centerDotOrigin: CGFloat = 0.466
    static let centerDotSize: CGFloat = 0.068
    static let focusDotX: CGFloat = 0.708
    static let focusDotY: CGFloat = 0.708
    static let focusDotSize: CGFloat = 0.082
    static let focusHaloOrigin: CGFloat = 0.691
    static let focusHaloSize: CGFloat = 0.116

    static let minuteHandEnd = CGPoint(x: 0.5, y: 0.684)
    static let hourHandEnd = CGPoint(x: 0.648, y: 0.425)

    static func appKitRect(
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        size: CGFloat
    ) -> CGRect {
        CGRect(x: x * size, y: y * size, width: width * size, height: height * size)
    }

    static func swiftUIRect(
        x: CGFloat,
        appKitY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        size: CGFloat
    ) -> CGRect {
        CGRect(
            x: x * size,
            y: (1 - appKitY - height) * size,
            width: width * size,
            height: height * size
        )
    }
}
