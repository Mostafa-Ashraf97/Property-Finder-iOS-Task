import SwiftUI
import UIKit
import XCTest

/// Renders a SwiftUI component at `width` and compares it with its reference PNG.
///
/// `ImageRenderer` draws plain SwiftUI only. Screens backed by UIKit, such as `List`, text fields and navigation bars,
/// go through `assertSnapshot(of:named:size:)` with a view controller instead.
@MainActor
func assertSnapshot(
    of view: some View,
    named name: String,
    width: CGFloat = 390,
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try XCTSkipUnless(isReferenceSystem, "Snapshots are recorded on iOS 26.2")

    let renderer = ImageRenderer(content: view
        .frame(width: width)
        .environment(\.locale, Locale(identifier: "en_AE"))
        .environment(\.dynamicTypeSize, .large))
    renderer.scale = 2
    let actual = try XCTUnwrap(renderer.uiImage?.pngData(), "The view could not be rendered", file: file, line: line)
    try compare(actual, withReferenceNamed: name, file: file, line: line)
}

/// Shows `viewController` full screen in an iPhone 17-sized window, in light mode at the default text size, and compares
/// it with its reference PNG.
///
/// SwiftUI only draws inside a window. Package tests have no window scene, so the window comes from `init(frame:)`,
/// which iOS 26 deprecates in favour of `init(windowScene:)`. The layers are drawn with `render(in:)`, which skips
/// layer filters such as the vibrant navigation bar title, so screens are snapshotted without system navigation bars.
@MainActor
func assertSnapshot(
    of viewController: UIViewController,
    named name: String,
    size: CGSize = CGSize(width: 402, height: 874),
    file: StaticString = #filePath,
    line: UInt = #line
) throws {
    try XCTSkipUnless(isReferenceSystem, "Snapshots are recorded on iOS 26.2")

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.overrideUserInterfaceStyle = .light
    window.rootViewController = viewController
    viewController.traitOverrides.preferredContentSizeCategory = .large
    window.isHidden = false
    window.layoutIfNeeded()
    defer { window.isHidden = true }

    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { context in
        window.layer.render(in: context.cgContext)
    }
    let actual = try XCTUnwrap(image.pngData(), "The screen could not be rendered", file: file, line: line)
    try compare(actual, withReferenceNamed: name, file: file, line: line)
}

/// References are rendered on iOS 26.2, the CI simulator. Other versions draw text slightly differently, so they skip.
private var isReferenceSystem: Bool {
    let system = ProcessInfo.processInfo.operatingSystemVersion
    return system.majorVersion == 26 && system.minorVersion == 2
}

/// Compares `actual` with the reference beside the test file, in `__Snapshots__/<test file name>/<name>.png`.
///
/// A missing reference is recorded and the test fails once, so every new reference is reviewed before it is trusted.
/// Delete a PNG to re-record it. On a mismatch both images are attached to the test result.
@MainActor
private func compare(_ actual: Data, withReferenceNamed name: String, file: StaticString, line: UInt) throws {
    let testFile = URL(fileURLWithPath: "\(file)")
    let reference = testFile.deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(testFile.deletingPathExtension().lastPathComponent)
        .appendingPathComponent("\(name).png")

    guard let expected = try? Data(contentsOf: reference) else {
        try FileManager.default.createDirectory(at: reference.deletingLastPathComponent(), withIntermediateDirectories: true)
        try actual.write(to: reference)
        XCTFail("Recorded a new reference at \(reference.path). Review it, then run the test again.", file: file, line: line)
        return
    }

    guard !imagesMatch(expected, actual) else { return }
    XCTContext.runActivity(named: "Snapshot mismatch: \(name)") { activity in
        for (label, data) in [("reference", expected), ("actual", actual)] {
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
            attachment.name = "\(name) \(label)"
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }
    XCTFail("\(name) doesn't match its reference; the reference and actual images are attached.", file: file, line: line)
}

/// Compares decoded pixels rather than PNG bytes, allowing tiny anti-aliasing differences in at most 0.1% of channels.
private func imagesMatch(_ lhs: Data, _ rhs: Data) -> Bool {
    guard let left = UIImage(data: lhs)?.cgImage,
          let right = UIImage(data: rhs)?.cgImage,
          left.width == right.width,
          left.height == right.height,
          let leftPixels = rgbaPixels(of: left),
          let rightPixels = rgbaPixels(of: right)
    else { return false }

    let differingChannels = zip(leftPixels, rightPixels).count { abs(Int($0) - Int($1)) > 2 }
    return Double(differingChannels) <= Double(leftPixels.count) * 0.001
}

private func rgbaPixels(of image: CGImage) -> [UInt8]? {
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let drawn = pixels.withUnsafeMutableBytes { buffer in
        guard let context = CGContext(
            data: buffer.baseAddress,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return true
    }
    return drawn ? pixels : nil
}
