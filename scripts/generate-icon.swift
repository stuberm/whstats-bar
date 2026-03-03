import AppKit
import Foundation

private extension NSBezierPath {
    var cgPathValue: CGPath {
        let path = CGMutablePath()
        var points = [NSPoint](repeating: .zero, count: 3)

        for index in 0 ..< elementCount {
            let type = element(at: index, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }

        return path
    }
}

func createIconPNG(outputPath: String, size: CGFloat = 1024) throws {
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
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap context"])
    }

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "IconGeneration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    defer { NSGraphicsContext.restoreGraphicsState() }

    let context = graphicsContext.cgContext

    let canvas = CGRect(x: 0, y: 0, width: size, height: size)
    context.setFillColor(NSColor.clear.cgColor)
    context.fill(canvas)

    let cardInset = size * 0.06
    let cardRect = canvas.insetBy(dx: cardInset, dy: cardInset)
    let cornerRadius = size * 0.2
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: cornerRadius, yRadius: cornerRadius)

    context.saveGState()
    context.addPath(cardPath.cgPathValue)
    context.clip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.14, blue: 0.24, alpha: 1),
        NSColor(calibratedRed: 0.15, green: 0.21, blue: 0.32, alpha: 1),
    ])
    gradient?.draw(in: cardRect, angle: -35)

    context.restoreGState()

    context.setStrokeColor(NSColor.white.withAlphaComponent(0.14).cgColor)
    context.setLineWidth(size * 0.014)
    context.addPath(cardPath.cgPathValue)
    context.strokePath()

    let center = CGPoint(x: size * 0.5, y: size * 0.58)
    let radius = size * 0.23

    context.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    context.setLineWidth(size * 0.028)
    context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    context.strokePath()

    context.setLineCap(.round)
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
    context.setLineWidth(size * 0.03)
    context.move(to: center)
    context.addLine(to: CGPoint(x: center.x, y: center.y + radius * 0.52))
    context.strokePath()

    context.move(to: center)
    context.addLine(to: CGPoint(x: center.x + radius * 0.42, y: center.y - radius * 0.14))
    context.strokePath()

    context.setFillColor(NSColor.white.cgColor)
    context.addEllipse(in: CGRect(x: center.x - size * 0.03, y: center.y - size * 0.03, width: size * 0.06, height: size * 0.06))
    context.fillPath()

    let barAreaWidth = size * 0.62
    let barX = center.x - barAreaWidth / 2
    let firstBarY = size * 0.2
    let barHeight = size * 0.05
    let barGap = size * 0.024

    let bars: [(CGFloat, NSColor)] = [
        (barAreaWidth * 0.65, NSColor(calibratedRed: 0.16, green: 0.58, blue: 1.0, alpha: 1)),
        (barAreaWidth * 0.88, NSColor(calibratedRed: 0.26, green: 0.84, blue: 0.76, alpha: 1)),
        (barAreaWidth * 1.0, NSColor.white.withAlphaComponent(0.2)),
    ]

    for (index, bar) in bars.enumerated() {
        let y = firstBarY + CGFloat(index) * (barHeight + barGap)
        let rect = CGRect(x: barX, y: y, width: bar.0, height: barHeight)
        let path = NSBezierPath(roundedRect: rect, xRadius: barHeight / 2, yRadius: barHeight / 2)
        bar.1.setFill()
        path.fill()
    }

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGeneration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"])
    }

    let outputURL = URL(fileURLWithPath: outputPath)
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try png.write(to: outputURL)
}

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/AppIcon-1024.png"

do {
    try createIconPNG(outputPath: outputPath)
    print("Icon PNG created at \(outputPath)")
} catch {
    fputs("Icon generation failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
