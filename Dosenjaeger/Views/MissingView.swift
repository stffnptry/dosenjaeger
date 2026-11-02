import SwiftUI
import SwiftData

/// Screen 5: FEHLEND – Wunschliste.
struct MissingView: View {
    enum Scope: Hashable { case mine, world }

    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue
    @State private var scope: Scope = .mine
    @State private var scanTarget: ScanTarget?

    struct ScanTarget: Identifiable { let id = UUID() }

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }

    private var missing: [Flavor] {
        switch scope {
        case .mine: return flavors.filter { !$0.isOwned && $0.isAvailable(inAnyOf: tracked) }
        case .world: return flavors.filter { !$0.isOwned }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(eyebrow: "Wunschliste", title: "Fehlend")
                PillToggle(selection: $scope, options: [(value: Scope.mine, label: "Meine Länder"),
                                                        (value: Scope.world, label: "Weltweit")])
                summary
                if missing.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").font(.ui(34)).foregroundStyle(Theme.accent)
                        Text("Alles da!").font(.display(26))
                        Text("Dir fehlt keine Sorte in dieser Auswahl.")
                            .font(.ui(13)).foregroundStyle(Theme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(missing) { flavor in
                            row(flavor)
                            Rectangle().fill(Theme.line).frame(height: 1)
                        }
                    }
                }
            }
            .padding(16)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .appDestinations()
        .fullScreenCover(item: $scanTarget) { _ in
            ScanFlowView()
        }
    }

    private var summary: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(missing.count)")
                .font(.display(46))
                .foregroundStyle(Theme.accent)
            Text(summaryText)
                .font(.ui(13))
                .foregroundStyle(Theme.secondary)
        }
        .padding(.vertical, 6)
        .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1).offset(y: -6) }
    }

    private var summaryText: String {
        let noun = missing.count == 1 ? "Sorte fehlt" : "Sorten fehlen"
        switch scope {
        case .mine:
            return tracked.isEmpty
                ? "Wähle unter „Länder“ aus, welche Länder du verfolgst."
                : "\(noun) dir, die in \(Country.spokenList(tracked)) erhältlich sind. Grün = in deinen Ländern."
        case .world:
            return "\(noun) dir insgesamt im Katalog. Grün = in deinen Ländern."
        }
    }

    private func row(_ flavor: Flavor) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: flavor) {
                HStack(spacing: 12) {
                    CanView(color: Color(hexString: flavor.colorHex), height: 48)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(flavor.name).font(.ui(15, .semibold)).foregroundStyle(.white)
                        FlowChips(codes: Country.sorted(flavor.countries), tracked: tracked)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                scanTarget = ScanTarget()
            } label: {
                Image(systemName: "camera")
                    .font(.ui(15))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(flavor.name) scannen")
        }
        .padding(.vertical, 10)
    }
}

/// Länderchips in einer Zeile; grün, wenn das Land verfolgt wird.
struct FlowChips: View {
    let codes: [String]
    let tracked: [String]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(codes, id: \.self) { code in
                CountryChip(code: code, highlighted: tracked.contains(code))
            }
        }
    }
}
