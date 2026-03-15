import SwiftUI
@MainActor
enum SparkTypography {

    enum TextSize: String, CaseIterable {
        case small, `default`, large, extraLarge

        var scale: CGFloat {
            switch self {
            case .small: return 0.85
            case .default: return 1.0
            case .large: return 1.15
            case .extraLarge: return 1.3
            }
        }
    }

    @MainActor static var useDyslexicFont: Bool = false
    @MainActor static var textSize: TextSize = .default

    private static var headingFamily: String {
        useDyslexicFont ? "OpenDyslexic" : "Nunito-ExtraBold"
    }

    private static var bodyFamily: String {
        useDyslexicFont ? "OpenDyslexic" : "Nunito-Regular"
    }

    private static func scaled(_ base: CGFloat) -> CGFloat {
        base * textSize.scale
    }

    // We fall back to system rounded if Nunito is not bundled
    private static func font(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: scaled(size), weight: weight, design: useDyslexicFont ? .monospaced : .rounded)
    }

    // MARK: - Display

    static var displayXL: Font { font(size: 48, weight: .heavy) }
    static var display: Font { font(size: 36, weight: .bold) }

    // MARK: - Headings

    static var heading1: Font { font(size: 28, weight: .bold) }
    static var heading2: Font { font(size: 22, weight: .bold) }
    static var heading3: Font { font(size: 18, weight: .semibold) }

    // MARK: - Body

    static var bodyLarge: Font { font(size: 17, weight: .regular) }
    static var body: Font { font(size: 15, weight: .regular) }
    static var bodyMedium: Font { font(size: 15, weight: .medium) }

    // MARK: - Caption / Label

    static var caption: Font { font(size: 13, weight: .regular) }
    static var captionBold: Font { font(size: 13, weight: .semibold) }
    static var label: Font { font(size: 11, weight: .medium) }
}
