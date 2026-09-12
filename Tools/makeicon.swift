#!/usr/bin/env swift
import AppKit

// Draws AppIcon.icns: a black rounded square with a white mouse silhouette
// and a bidirectional arrow for the scroll wheel. No binary art is versioned
// in the repository — this runs at build time, same as MacTray's icon.

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    ctx.setShouldAntialias(true)

    let inset = size * 0.055
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.2237
    let body = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSColor(calibratedWhite: 0.05, alpha: 1).setFill()
    body.fill()

    NSColor(white: 1, alpha: 0.12).setStroke()
    body.lineWidth = size * 0.006
    body.stroke()

    // Mouse body: a tall rounded rect.
    let mouseWidth = rect.width * 0.34
    let mouseHeight = rect.height * 0.52
    let mouseRect = NSRect(
        x: rect.midX - mouseWidth / 2,
        y: rect.midY - mouseHeight / 2,
        width: mouseWidth,
        height: mouseHeight
    )
    let mouseBody = NSBezierPath(roundedRect: mouseRect, xRadius: mouseWidth * 0.45, yRadius: mouseWidth * 0.45)
    NSColor.white.setStroke()
    mouseBody.lineWidth = size * 0.028
    mouseBody.stroke()

    // Scroll wheel notch.
    let wheelWidth = mouseWidth * 0.16
    let wheelHeight = mouseHeight * 0.16
    let wheelRect = NSRect(
        x: rect.midX - wheelWidth / 2,
        y: mouseRect.maxY - mouseHeight * 0.22 - wheelHeight / 2,
        width: wheelWidth,
        height: wheelHeight
    )
    NSBezierPath(roundedRect: wheelRect, xRadius: wheelWidth / 2, yRadius: wheelWidth / 2).fill()

    // Bidirectional arrow below the mouse: the reversed-scroll cue.
    let arm = rect.width * 0.1
    let lineWidth = rect.width * 0.055
    let arrowCenterY = mouseRect.minY - rect.height * 0.14
    NSColor.white.setStroke()
    let up = NSBezierPath()
    up.lineWidth = lineWidth
    up.lineCapStyle = .round
    up.lineJoinStyle = .round
    up.move(to: NSPoint(x: rect.midX - arm * 0.6, y: arrowCenterY - arm * 0.3))
    up.line(to: NSPoint(x: rect.midX, y: arrowCenterY + arm * 0.7))
    up.line(to: NSPoint(x: rect.midX + arm * 0.6, y: arrowCenterY - arm * 0.3))
    up.stroke()

    image.unlockFocus()
    return image
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

let variants: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in variants {
    let image = drawIcon(size: size)
    guard let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else { continue }
    try? png.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}
print("iconset at \(out)")
