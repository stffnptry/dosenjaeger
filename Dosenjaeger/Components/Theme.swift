import SwiftUI
import UIKit

/// Farben und Schriften aus dem Design-Entwurf.
enum Theme {
    static let background = Color(hex: 0x17271D)
    static let card = Color.black
    static let accent = Color(hex: 0x6BD31A)
    static let accentDark = Color(hex: 0x3B5E00)
    static let warning = Color(hex: 0xF2A33A)
    static let line = Color.white.opacity(0.14)
    static let secondary = Color.white.opacity(0.62)
    static let tertiary = Color.white.opacity(0.35)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    init(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        self.init(hex: UInt32(cleaned, radix: 16) ?? 0x6BD31A)
    }

    /// Hex-Darstellung, z. B. "#6BD31A" (für den Farbwähler beim Anlegen eigener Sorten).
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let clamp: (CGFloat) -> Int = { max(0, min(255, Int(($0 * 255).rounded()))) }
        return String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }
}

extension Font {
    /// Kondensierte, sehr fette Überschrift wie im Entwurf.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black).width(.compressed)
    }

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

@MainActor
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
