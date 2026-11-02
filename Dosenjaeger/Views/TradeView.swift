import SwiftUI
import SwiftData

/// Screen 7: TAUSCHEN – Doppelte freigeben und Tauschliste teilen.
struct TradeView: View {
    enum Side: Hashable { case offer, want }

    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue
    @State private var side: Side = .offer

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }

    private var owned: [Flavor] {
        flavors.filter(\.isOwned).sorted {
            $0.duplicates != $1.duplicates ? $0.duplicates > $1.duplicates : $0.name < $1.name
        }
    }

    private var offered: [Flavor] { owned.filter { $0.tradeable && $0.duplicates > 0 } }
    private var wanted: [Flavor] { flavors.filter { !$0.isOwned && $0.isAvailable(inAnyOf: tracked) } }
    private var offeredCans: Int { offered.reduce(0) { $0 + $1.duplicates } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(eyebrow: "Duplikate", title: "Tauschen")
                PillToggle(selection: $side, options: [(value: Side.offer, label: "Ich biete"),
                                                       (value: Side.want, label: "Ich suche")])
                Text(side == .offer
                     ? "Schalte frei, welche doppelten Dosen du tauschen willst."
                     : "Diese Sorten fehlen dir in deinen Ländern.")
                    .font(.ui(13))
                    .foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                LazyVStack(spacing: 0) {
                    if side == .offer {
                        if owned.isEmpty { empty("Noch nichts in der Sammlung.") }
                        ForEach(owned) { flavor in offerRow(flavor) }
                    } else {
                        if wanted.isEmpty { empty("Dir fehlt nichts – stark!") }
                        ForEach(wanted) { flavor in wantRow(flavor) }
                    }
                }

                VStack(spacing: 8) {
                    ShareLink(item: shareText, subject: Text("Meine Tauschliste")) {
                        Label("TAUSCHLISTE TEILEN", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if let image = shareImage {
                        ShareLink(item: image, preview: SharePreview("Tauschliste", image: image)) {
                            Text("Als Bild teilen")
                                .font(.ui(13, .semibold))
                                .underline()
                                .foregroundStyle(Theme.accent)
                        }
                    }

                    Text("\(offeredCans) \(offeredCans == 1 ? "Dose" : "Dosen") zum Tausch freigegeben · als Text oder Bild teilen")
                        .font(.ui(11))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func empty(_ text: String) -> some View {
        Text(text)
            .font(.ui(13))
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func offerRow(_ flavor: Flavor) -> some View {
        let canTrade = flavor.duplicates > 0
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                CanView(color: Color(hexString: flavor.colorHex), height: 44)
                    .frame(width: 26)
                    .opacity(canTrade ? 1 : 0.5)
                VStack(alignment: .leading, spacing: 2) {
                    Text(flavor.name).font(.ui(15, .semibold))
                        .foregroundStyle(canTrade ? .white : Theme.secondary)
                    Text(canTrade
                         ? "\(flavor.duplicates) doppelt · \(Country.sorted(flavor.boughtCountries).joined(separator: ", "))"
                         : "Einzelstück · nicht tauschbar")
                        .font(.ui(12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(get: { canTrade && flavor.tradeable },
                                         set: { flavor.tradeable = $0 }))
                    .labelsHidden()
                    .tint(Theme.accent)
                    .disabled(!canTrade)
            }
            .padding(.vertical, 10)
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    private func wantRow(_ flavor: Flavor) -> some View {
        VStack(spacing: 0) {
            NavigationLink(value: flavor) {
                HStack(spacing: 12) {
                    CanView(color: Color(hexString: flavor.colorHex), height: 44)
                        .frame(width: 26)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flavor.name).font(.ui(15, .semibold)).foregroundStyle(.white)
                        FlowChips(codes: Country.sorted(flavor.countries), tracked: tracked)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.ui(12)).foregroundStyle(Theme.secondary)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Rectangle().fill(Theme.line).frame(height: 1)
        }
    }

    // MARK: Teilen

    private var shareText: String {
        var lines = ["🥫 Meine Monster-Tauschliste (Dosenjäger)", ""]
        lines.append("ICH BIETE:")
        if offered.isEmpty {
            lines.append("– noch nichts freigegeben")
        } else {
            for flavor in offered {
                let origin = Country.sorted(flavor.boughtCountries).joined(separator: "/")
                lines.append("• \(flavor.name) – \(flavor.duplicates)× (\(origin))")
            }
        }
        lines.append("")
        lines.append("ICH SUCHE:")
        if wanted.isEmpty {
            lines.append("– nichts")
        } else {
            for flavor in wanted {
                lines.append("• \(flavor.name)")
            }
        }
        return lines.joined(separator: "\n")
    }

    @MainActor
    private var shareImage: Image? {
        let renderer = ImageRenderer(content: TradeCard(offered: offered, wanted: wanted))
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }
}

/// Bild der Tauschliste zum Teilen.
struct TradeCard: View {
    let offered: [Flavor]
    let wanted: [Flavor]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Dosenjäger")
            Text("TAUSCHLISTE").font(.display(36)).foregroundStyle(.white)
            column("Ich biete", offered.map { "\($0.name) · \($0.duplicates)×" })
            column("Ich suche", wanted.prefix(12).map(\.name) + (wanted.count > 12 ? ["… und \(wanted.count - 12) weitere"] : []))
        }
        .padding(24)
        .frame(width: 360, alignment: .leading)
        .background(Theme.background)
    }

    private func column(_ title: String, _ rows: [String]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.display(20)).foregroundStyle(Theme.accent)
            if rows.isEmpty {
                Text("–").font(.ui(14)).foregroundStyle(Theme.secondary)
            }
            ForEach(rows, id: \.self) { row in
                Text(row).font(.ui(14)).foregroundStyle(.white)
            }
        }
    }
}
