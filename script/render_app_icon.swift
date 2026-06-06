#!/usr/bin/env swift

import AppKit
import Foundation

let rootPath = CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
let assetDirectory = rootURL.appendingPathComponent("Assets", isDirectory: true)
let sourceURL = assetDirectory.appendingPathComponent("FinderHistorySource.png")
let icnsURL = assetDirectory.appendingPathComponent("FinderHistory.icns")
let tempIconsetURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    .appendingPathComponent("FinderHistory.iconset", isDirectory: true)

struct IconSize {
    let points: Int
    let scale: Int

    var pixels: Int {
        points * scale
    }

    var fileName: String {
        scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@\(scale)x.png"
    }
}

let iconSizes = [
    IconSize(points: 16, scale: 1),
    IconSize(points: 16, scale: 2),
    IconSize(points: 32, scale: 1),
    IconSize(points: 32, scale: 2),
    IconSize(points: 128, scale: 1),
    IconSize(points: 128, scale: 2),
    IconSize(points: 256, scale: 1),
    IconSize(points: 256, scale: 2),
    IconSize(points: 512, scale: 1),
    IconSize(points: 512, scale: 2)
]

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    FileHandle.standardError.write(Data("Missing source image: \(sourceURL.path)\n".utf8))
    exit(1)
}

try? FileManager.default.removeItem(at: tempIconsetURL)
try FileManager.default.createDirectory(at: tempIconsetURL, withIntermediateDirectories: true)

func renderedPNG(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "FinderHistoryIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap"])
    }

    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "FinderHistoryIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create graphics context"])
    }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    sourceImage.draw(
        in: NSRect(x: 0, y: 0, width: size, height: size),
        from: NSRect(origin: .zero, size: sourceImage.size),
        operation: .sourceOver,
        fraction: 1
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "FinderHistoryIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG"])
    }

    return png
}

for iconSize in iconSizes {
    let png = try renderedPNG(size: iconSize.pixels)
    try png.write(to: tempIconsetURL.appendingPathComponent(iconSize.fileName))
}

try? FileManager.default.removeItem(at: icnsURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempIconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "FinderHistoryIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

try? FileManager.default.removeItem(at: tempIconsetURL)

let xattr = Process()
xattr.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
xattr.arguments = ["-cr", icnsURL.path]
try? xattr.run()
xattr.waitUntilExit()

print("Wrote \(icnsURL.path)")
