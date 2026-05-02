import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetRoot = root.appendingPathComponent("BridgeFlow/Assets.xcassets", isDirectory: true)
let appIconRoot = assetRoot.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let imageSetRoot = assetRoot.appendingPathComponent("BridgeFlowIcon.imageset", isDirectory: true)
let sourceURL = root.appendingPathComponent("bridgeflow-logo.jpeg")

try FileManager.default.createDirectory(at: appIconRoot, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: imageSetRoot, withIntermediateDirectories: true)

func sourceImage(size: CGFloat) -> NSImage {
    if let image = NSImage(contentsOf: sourceURL) {
        image.size = NSSize(width: size, height: size)
        return image
    }
    return drawBridgeFlowIcon(size: size)
}

func drawBridgeFlowIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor(red: 0.027, green: 0.031, blue: 0.039, alpha: 1).setFill()
    rect.fill()

    let backgroundPath = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.08, dy: size * 0.08), xRadius: size * 0.18, yRadius: size * 0.18)
    NSGradient(colors: [
        NSColor(red: 0.05, green: 0.08, blue: 0.13, alpha: 1),
        NSColor(red: 0.09, green: 0.07, blue: 0.15, alpha: 1)
    ])?.draw(in: backgroundPath, angle: -35)

    NSColor(red: 0.55, green: 0.72, blue: 1, alpha: 0.18).setStroke()
    backgroundPath.lineWidth = max(1.4, size * 0.004)
    backgroundPath.stroke()

    let panelSize = NSSize(width: size * 0.29, height: size * 0.34)
    let leftPanel = NSRect(x: size * 0.16, y: size * 0.32, width: panelSize.width, height: panelSize.height)
    let rightPanel = NSRect(x: size * 0.55, y: size * 0.32, width: panelSize.width, height: panelSize.height)

    drawPanel(leftPanel, radius: size * 0.045, colour: NSColor(red: 0.08, green: 0.48, blue: 1, alpha: 0.24))
    drawPanel(rightPanel, radius: size * 0.045, colour: NSColor(red: 0.58, green: 0.35, blue: 1, alpha: 0.24))

    drawArc(size: size, startAngle: 22, endAngle: 158, colour: NSColor(red: 0.1, green: 0.82, blue: 0.98, alpha: 1))
    drawArc(size: size, startAngle: 22, endAngle: 88, colour: NSColor(red: 0.58, green: 0.35, blue: 1, alpha: 1))

    drawEndpoint(x: size * 0.27, y: size * 0.53, colour: NSColor(red: 0.1, green: 0.82, blue: 0.98, alpha: 1), size: size)
    drawEndpoint(x: size * 0.73, y: size * 0.53, colour: NSColor(red: 0.58, green: 0.35, blue: 1, alpha: 1), size: size)
    drawCursor(size: size)

    return image
}

func drawPanel(_ rect: NSRect, radius: CGFloat, colour: NSColor) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    colour.withAlphaComponent(0.18).setFill()
    path.fill()
    colour.setStroke()
    path.lineWidth = max(1.2, rect.width * 0.01)
    path.stroke()
}

func drawArc(size: CGFloat, startAngle: CGFloat, endAngle: CGFloat, colour: NSColor) {
    let shadow = NSShadow()
    shadow.shadowColor = colour.withAlphaComponent(0.72)
    shadow.shadowBlurRadius = size * 0.05
    shadow.set()

    let path = NSBezierPath()
    path.appendArc(
        withCenter: NSPoint(x: size * 0.5, y: size * 0.22),
        radius: size * 0.42,
        startAngle: startAngle,
        endAngle: endAngle
    )
    path.lineWidth = max(4, size * 0.065)
    path.lineCapStyle = .round
    colour.setStroke()
    path.stroke()
    NSShadow().set()
}

func drawEndpoint(x: CGFloat, y: CGFloat, colour: NSColor, size: CGFloat) {
    let shadow = NSShadow()
    shadow.shadowColor = colour.withAlphaComponent(0.8)
    shadow.shadowBlurRadius = size * 0.045
    shadow.set()

    let rect = NSRect(x: x - size * 0.028, y: y - size * 0.028, width: size * 0.056, height: size * 0.056)
    let path = NSBezierPath(ovalIn: rect)
    colour.setFill()
    path.fill()
    NSColor.white.withAlphaComponent(0.78).setStroke()
    path.lineWidth = max(1, size * 0.006)
    path.stroke()
    NSShadow().set()
}

func drawCursor(size: CGFloat) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: size * 0.47, y: size * 0.61))
    path.line(to: NSPoint(x: size * 0.57, y: size * 0.51))
    path.line(to: NSPoint(x: size * 0.52, y: size * 0.49))
    path.line(to: NSPoint(x: size * 0.56, y: size * 0.42))
    path.line(to: NSPoint(x: size * 0.52, y: size * 0.40))
    path.line(to: NSPoint(x: size * 0.48, y: size * 0.48))
    path.line(to: NSPoint(x: size * 0.45, y: size * 0.45))
    path.close()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.white.withAlphaComponent(0.6)
    shadow.shadowBlurRadius = size * 0.025
    shadow.set()
    NSColor.white.withAlphaComponent(0.95).setFill()
    path.fill()
    NSColor(red: 0.12, green: 0.45, blue: 1, alpha: 0.8).setStroke()
    path.lineWidth = max(1.1, size * 0.007)
    path.stroke()
    NSShadow().set()
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "BridgeFlowAssetGeneration", code: 1)
    }
    try data.write(to: url)
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let image = sourceImage(size: CGFloat(size))
    try writePNG(image, to: appIconRoot.appendingPathComponent("icon_\(size)x\(size).png"))
}

try writePNG(sourceImage(size: 256), to: imageSetRoot.appendingPathComponent("bridgeflow-icon.png"))
try writePNG(sourceImage(size: 512), to: imageSetRoot.appendingPathComponent("bridgeflow-icon@2x.png"))
try writePNG(sourceImage(size: 1024), to: imageSetRoot.appendingPathComponent("bridgeflow-icon@3x.png"))

let appIconContents = """
{
  "images": [
    { "filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16" },
    { "filename": "icon_32x32.png", "idiom": "mac", "scale": "2x", "size": "16x16" },
    { "filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32" },
    { "filename": "icon_64x64.png", "idiom": "mac", "scale": "2x", "size": "32x32" },
    { "filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "filename": "icon_256x256.png", "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "filename": "icon_512x512.png", "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "filename": "icon_1024x1024.png", "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
"""

let imageSetContents = """
{
  "images": [
    { "filename": "bridgeflow-icon.png", "idiom": "universal", "scale": "1x" },
    { "filename": "bridgeflow-icon@2x.png", "idiom": "universal", "scale": "2x" },
    { "filename": "bridgeflow-icon@3x.png", "idiom": "universal", "scale": "3x" }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
"""

try appIconContents.write(to: appIconRoot.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
try imageSetContents.write(to: imageSetRoot.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
