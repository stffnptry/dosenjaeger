import SwiftUI

/// Stilisierte Dose: schwarzer Körper, heller Deckel, farbiges Band.
struct CanView: View {
    var color: Color
    var height: CGFloat = 60

    var body: some View {
        let width = height * 0.46
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: width * 0.12)
                .fill(Color(white: 0.72))
                .frame(width: width * 0.84, height: max(2, height * 0.05))
            ZStack {
                RoundedRectangle(cornerRadius: width * 0.16)
                    .fill(Color(white: 0.05))
                Rectangle()
                    .fill(color)
                    .frame(height: height * 0.28)
                    .offset(y: height * 0.08)
                RoundedRectangle(cornerRadius: width * 0.16)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: width * 0.16))
            .frame(width: width, height: height * 0.95)
        }
        .accessibilityHidden(true)
    }
}

/// Kleine grüne Überzeile in Versalien.
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.accent

    var body: some View {
        Text(text.uppercased())
            .font(.ui(11, .semibold))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

/// Kopf eines Hauptscreens: Überzeile + große Überschrift.
struct ScreenHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            Eyebrow(text: eyebrow)
            Text(title.uppercased())
                .font(.display(40))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let subtitle {
                Text(subtitle)
                    .font(.ui(13))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

/// Länderkürzel als umrandeter Chip ("DE", "US –", "AT ●").
struct CountryChip: View {
    let code: String
    var available: Bool = true
    var highlighted: Bool = false
    var showDot: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Text(code)
            if !available {
                Text("–")
            } else if showDot {
                Circle().frame(width: 6, height: 6)
            }
        }
        .font(.ui(11, .bold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(border, lineWidth: 1)
        )
    }

    private var foreground: Color {
        if !available { return Theme.tertiary }
        return highlighted ? Theme.accent : .white
    }

    private var border: Color {
        if !available { return Color.white.opacity(0.15) }
        return highlighted ? Theme.accent : Color.white.opacity(0.4)
    }
}

/// Zweiteiliger Umschalter in Pillenform ("Foto | Barcode", "Meine Länder | Weltweit").
struct PillToggle<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let selected = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                    Haptics.tap()
                } label: {
                    Text(option.label)
                        .font(.ui(compact ? 13 : 14, .semibold))
                        .foregroundStyle(selected ? Color.white : Theme.secondary)
                        .frame(maxWidth: compact ? nil : .infinity)
                        .padding(.horizontal, compact ? 18 : 12)
                        .padding(.vertical, compact ? 8 : 10)
                        .background(Capsule().fill(selected ? Theme.accentDark : Color.clear))
                        .overlay(Capsule().stroke(selected ? Theme.accent.opacity(0.6) : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().stroke(Theme.line, lineWidth: 1))
    }
}

/// Großer grüner Hauptbutton ("ZUR SAMMLUNG HINZUFÜGEN").
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(15, .heavy))
            .tracking(0.6)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.accentDark))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.accent.opacity(0.5), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Umrandeter Nebenbutton ("TAUSCHEN").
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(14, .heavy))
            .tracking(0.6)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.5), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// Abschnittsüberschrift in kondensierter Schrift ("MEINE EXEMPLARE").
struct SectionTitle: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased())
                .font(.display(22))
                .foregroundStyle(.white)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.ui(12))
                    .foregroundStyle(Theme.secondary)
            }
        }
    }
}

/// Minus/Zahl/Plus-Steuerung für die Anzahl.
struct QuantityStepper: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...99

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if value > range.lowerBound { value -= 1; Haptics.tap() }
            } label: {
                Image(systemName: "minus").frame(width: 40, height: 36)
            }
            Text("\(value)")
                .font(.display(22))
                .frame(minWidth: 32)
            Button {
                if value < range.upperBound { value += 1; Haptics.tap() }
            } label: {
                Image(systemName: "plus").frame(width: 40, height: 36)
            }
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
    }
}

/// Foto eines Exemplars oder Platzhalter.
struct PhotoThumb: View {
    let data: Data?
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(white: 0.12)
                    Text("[Foto]")
                        .font(.ui(10))
                        .foregroundStyle(Theme.tertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
    }
}

extension View {
    /// Dunkelgrüner Hintergrund aller Hauptscreens.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Schwarze Karte mit feinem Rand.
    func cardStyle(padding: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1))
    }
}
