import SwiftUI
import SwiftData

/// Screen 4: LÄNDER – Länderauswahl und Sorten-Matrix.
struct CountriesView: View {
    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue
    @State private var showNew = false

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }

    var body: some View {
        let stats = CollectionStats(flavors: flavors, tracked: tracked)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(eyebrow: "Verfügbarkeit", title: "Länder",
                             subtitle: "Wähle die Länder, die du verfolgst.")
                countryGrid
                SectionTitle(text: "Sorten-Matrix",
                             trailing: "\(stats.relevant.count) Sorten · \(stats.missing.count) fehlen")
                if tracked.isEmpty {
                    Text("Wähle oben mindestens ein Land.")
                        .font(.ui(13))
                        .foregroundStyle(Theme.secondary)
                } else {
                    matrix(stats.relevant)
                    legend
                }
                Button {
                    showNew = true
                } label: {
                    Label("Sorte anlegen", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(16)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .appDestinations()
        .sheet(isPresented: $showNew) {
            FlavorEditView(flavor: nil)
        }
    }

    private var countryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(Country.all) { country in
                let on = tracked.contains(country.code)
                Button {
                    toggle(country.code)
                } label: {
                    VStack(spacing: 2) {
                        Text(country.code).font(.display(22))
                        Text(country.short).font(.ui(10))
                    }
                    .foregroundStyle(on ? Theme.accent : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 4).fill(on ? Theme.accentDark.opacity(0.7) : Color.black))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(on ? Theme.accent.opacity(0.6) : Theme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(country.name)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private func matrix(_ rows: [Flavor]) -> some View {
        let columnWidth: CGFloat = 34
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Sorte").frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
                    ForEach(tracked, id: \.self) { code in
                        Text(code).frame(width: columnWidth)
                    }
                }
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))

                ForEach(rows) { flavor in
                    NavigationLink(value: flavor) {
                        HStack(spacing: 0) {
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .strokeBorder(flavor.isOwned ? Theme.accent : Theme.warning, lineWidth: 1.5)
                                    .background(Circle().fill(flavor.isOwned ? Theme.accent : .clear))
                                    .frame(width: 9, height: 9)
                                    .padding(.top, 4)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(flavor.name).font(.ui(13, .semibold)).foregroundStyle(.white).lineLimit(1)
                                    Text(flavor.isOwned ? "In Sammlung" : "Fehlt")
                                        .font(.ui(10))
                                        .foregroundStyle(flavor.isOwned ? Theme.accent : Theme.warning)
                                }
                            }
                            .frame(minWidth: 150, maxWidth: .infinity, alignment: .leading)
                            ForEach(tracked, id: \.self) { code in
                                cell(flavor, code).frame(width: columnWidth)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(Theme.line).frame(height: 1)
                }
            }
            .containerRelativeFrame(.horizontal) { length, _ in
                max(length, 150 + 20 + columnWidth * CGFloat(tracked.count))
            }
        }
        .background(Color.black)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private func cell(_ flavor: Flavor, _ code: String) -> some View {
        if !flavor.isAvailable(in: code) {
            Text("–").font(.ui(13)).foregroundStyle(Theme.tertiary)
        } else if flavor.boughtCountries.contains(code) {
            Circle().fill(Theme.accent).frame(width: 9, height: 9)
        } else {
            Circle().fill(Color.white).frame(width: 9, height: 9)
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) { Circle().fill(.white).frame(width: 7, height: 7); Text("erhältlich") }
            HStack(spacing: 4) { Circle().fill(Theme.accent).frame(width: 7, height: 7); Text("dort gekauft") }
            HStack(spacing: 4) { Text("–"); Text("nicht erhältlich") }
        }
        .font(.ui(11))
        .foregroundStyle(Theme.secondary)
    }

    private func toggle(_ code: String) {
        var codes = tracked
        if let index = codes.firstIndex(of: code) {
            codes.remove(at: index)
        } else {
            codes.append(code)
        }
        trackedRaw = TrackedCountries.serialize(codes)
        Haptics.tap()
    }
}
