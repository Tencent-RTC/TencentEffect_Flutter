// swift-tools-version: 5.9
import PackageDescription
import Foundation

private let kAllowedSubSpecs: [String] = [
    "A1-00", "A1-01", "A1-02", "A1-03", "A1-04", "A1-05", "A1-06",
    "S1-00", "S1-01", "S1-02", "S1-03", "S1-04", "S1-05", "S1-06", "S1-07",
    "X1-01", "X1-02", "All",
]

private let kDefaultSubSpec = "S1-07"
private let kBasicSubSpecs = ["A1-00", "A1-01", "S1-00"]

private func parseTeSubSpec(fromYAML yaml: String) -> String? {
    var inSection = false
    for rawLine in yaml.components(separatedBy: .newlines) {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty || line.hasPrefix("#") { continue }
        if line.hasPrefix("TencentEffect:") {
            inSection = true
            continue
        }
        if inSection {
            if let range = line.range(of: "te_sub_spec:") {
                return String(line[range.upperBound...])
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
            if !rawLine.hasPrefix(" ") && !rawLine.hasPrefix("\t") {
                inSection = false
            }
        }
    }
    return nil
}

private func normalizedSubSpec(_ raw: String?) -> String? {
    guard let raw, kAllowedSubSpecs.contains(raw) else { return nil }
    return raw
}

private func resolveSubSpec() -> String {
    var candidates: [String] = []
    let env = ProcessInfo.processInfo.environment
    for key in ["FLUTTER_APPLICATION_PATH", "SRCROOT"] {
        if let root = env[key], !root.isEmpty {
            candidates.append(root + "/pubspec.yaml")
        }
    }
    var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    for _ in 0..<8 {
        candidates.append(dir.appendingPathComponent("pubspec.yaml").path)
        dir = dir.deletingLastPathComponent()
    }

    for path in candidates {
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
        if let v = normalizedSubSpec(parseTeSubSpec(fromYAML: text)) {
            return v
        }
    }
    return kDefaultSubSpec
}

let subSpec = resolveSubSpec()

let tePackageName = kBasicSubSpecs.contains(subSpec)
    ? "TencentEffect_Basic_SwiftPM"
    : "TencentEffect_SwiftPM"

let package = Package(
    name: "tencent_effect_flutter",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "tencent-effect-flutter", targets: ["tencent_effect_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/Tencent-RTC/\(tePackageName).git", from: "4.4.0"),
        .package(
            name: "TXCustomBeautyProcesserPlugin",
            url: "https://github.com/Tencent-RTC/TXCustomBeautyProcesserPlugin_SwiftPM.git",
            from: "1.0.2"
        )
    ],
    targets: [
        .target(
            name: "tencent_effect_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "TXCustomBeautyProcesserPlugin", package: "TXCustomBeautyProcesserPlugin"),
                .product(name: "TencentEffect_\(subSpec)", package: tePackageName)
            ],
            path: "Sources/tencent_effect_flutter",
            cSettings: [
                .headerSearchPath("include/tencent_effect_flutter")
            ]
        )
    ]
)
