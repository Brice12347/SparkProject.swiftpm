import SwiftUI

enum SparkTheme {
    // MARK: - Primary Palette

    static let teal = Color(hex: "2BBFB3")
    static let tealDark = Color(hex: "229E94")
    static let tealLight = Color(hex: "5CD6CB")

    static let canvasWhite = Color(hex: "FAF8F4")
    static let charcoal = Color(hex: "1E1E2E")
    static let darkSurface = Color(hex: "0D1A19")

    // MARK: - AI Annotation Colors

    static let aiGuidance = Color(hex: "2BBFB3")
    static let aiCorrection = Color(hex: "5B8AF5")
    static let aiError = Color(hex: "E05C5C")

    // MARK: - Concept Tag Colors

    static let strengthGreen = Color(hex: "4CAF7D")
    static let practiceAmber = Color(hex: "E8A838")
    static let struggleRed = Color(hex: "E05C5C")

    // MARK: - Neutral Palette

    static let gray50 = Color(hex: "FAFAFA")
    static let gray100 = Color(hex: "F5F5F5")
    static let gray200 = Color(hex: "EEEEEE")
    static let gray300 = Color(hex: "E0E0E0")
    static let gray400 = Color(hex: "BDBDBD")
    static let gray500 = Color(hex: "9E9E9E")
    static let gray600 = Color(hex: "757575")
    static let gray700 = Color(hex: "616161")
    static let gray800 = Color(hex: "424242")
    static let gray900 = Color(hex: "212121")

    // MARK: - Gradients

    static let profileGradient = LinearGradient(
        colors: [Color(hex: "EAF8F7"), Color(hex: "EDE8F8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let profileGradientDark = LinearGradient(
        colors: [Color(hex: "0D2B29"), Color(hex: "1A1530")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FFF8F0"), Color(hex: "FAF8F4")],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Subject Colors

    static func subjectColor(_ subject: Subject) -> Color {
        switch subject {
        case .math: return Color(hex: "5B8AF5")
        case .reading: return Color(hex: "E8A838")
        case .writing: return Color(hex: "9B6BF2")
        case .science: return Color(hex: "4CAF7D")
        case .history: return Color(hex: "E07C5C")
        case .foreignLanguage: return Color(hex: "E05C8C")
        case .other: return gray500
        }
    }

    // MARK: - Semantic Colors

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? charcoal : canvasWhite
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "2A2A3C") : .white
    }

    static func surfaceSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "232336") : gray100
    }

    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : charcoal
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? gray400 : gray600
    }

    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "3A3A4C") : gray200
    }

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radii

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 24

    // MARK: - Shadows

    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.3)
            : Color(hex: "1E1E2E").opacity(0.08)
    }
    
    // MARK: - Button Backgrounds
    
    static var glassButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                SparkTheme.teal.opacity(0.96),
                SparkTheme.teal.opacity(0.82),
                SparkTheme.teal.opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
