import SwiftUI
import SwiftData

/// Screen 1: MEINE SAMMLUNG
struct CollectionView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "Alle", original = "Original", ultra = "Ultra", juice = "Juice", more = "Weitere"
        var id: String { rawValue }

        func matches(_ flavor: Flavor) -> Bool {
            switch self {
            case .all: return true
            case .original: return flavor.line == .original
            case .ultra: return flavor.line == .ultra
            case .juice: return flavor.line == .juice
            case .more: return ![.original, .ultra, .juice].contains(flavor.line)
            }
        }
    }

    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue
    @State private var search = ""
    @State private var filter: Filter = .all
    @State private var showScanner = false

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }

    private var owned: [Flavor] {
        flavors
            .filter { $0.isOwned && filter.matches($0) && matchesSearch($0) }
            .sorted { ($0.firstAdded ?? .distantPast) > ($1.firstAdded ?? .distantPast) }
    }

    var body: some View {
        let stats = CollectionStats(flavors: flavors, tracked: tracked)
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    ScreenHeader(eyebrow: "Dosenjäger", title: "Meine Sammlung")
                    statsRow(stats)
                    progress(stats)
                    searchField
                    filterChips
                    grid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
            .scrollDismissesKeyboard(.interactively)

            Button {
                showScanner = true
            } label: {
                Label("DOSE SCANNEN", systemImage: "camera")
                    .font(.ui(15, .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(Theme.accentDark))
                    .overlay(Capsule().stroke(Theme.accent, lineWidth: 1))
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
            }
            .padding(.bottom, 12)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .appDestinations()
        .fullScreenCover(isPresented: $showScanner) {
            ScanFlowView()
        }
    }

    // MARK: Teile

    private func statsRow(_ stats: CollectionStats) -> some View {
        HStack(spacing: 0) {
            statCell(value: stats.totalCans, label: "Gesammelt")
            Divider().overlay(Theme.line)
            statCell(value: stats.missing.count, label: "Fehlend")
            Divider().overlay(Theme.line)
            NavigationLink(value: TradeRoute()) {
                statCell(value: stats.duplicates, label: "Doppelt ›", highlight: false)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 70)
        .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
    }

    private func statCell(value: Int, label: String, highlight: Bool = true) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.display(30))
                .foregroundStyle(highlight && label == "Gesammelt" ? Theme.accent : .white)
            Text(label)
                .font(.ui(11))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func progress(_ stats: CollectionStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Fortschritt in deinen \(stats.tracked.count) Ländern")
                Spacer()
                Text("\(Int((stats.progress * 100).rounded())) %").fontWeight(.semibold)
            }
            .font(.ui(12))
            .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(Theme.accent)
                        .frame(width: geo.size.width * stats.progress)
                }
            }
            .frame(height: 3)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.tertiary)
            TextField("", text: $search, prompt: Text("Sorte, Land oder Barcode suchen").foregroundStyle(Theme.tertiary))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.tertiary)
                }
            }
        }
        .font(.ui(15))
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.black.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { item in
                    let selected = item == filter
                    Button {
                        filter = item
                        Haptics.tap()
                    } label: {
                        Text(item.rawValue)
                            .font(.ui(13, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(selected ? Theme.accentDark : Color.clear))
                            .overlay(Capsule().stroke(selected ? Theme.accent.opacity(0.6) : Theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var grid: some View {
        if owned.isEmpty {
            VStack(spacing: 12) {
                CanView(color: Theme.accent, height: 70)
                Text(flavors.contains(where: \.isOwned) ? "Nichts gefunden." : "Noch keine Dosen in deiner Sammlung.")
                    .font(.ui(15, .semibold))
                Text(flavors.contains(where: \.isOwned) ? "Probier eine andere Suche oder einen anderen Filter." : "Tippe auf „Dose scannen“ und fotografiere deine erste Dose.")
                    .font(.ui(13))
                    .foregroundStyle(Theme.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(owned) { flavor in
                    NavigationLink(value: flavor) {
                        CanCard(flavor: flavor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func matchesSearch(_ flavor: Flavor) -> Bool {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        let fields = [flavor.name, flavor.subtitle, flavor.line.rawValue]
            + flavor.barcodes
            + flavor.items.compactMap(\.barcode)
            + flavor.boughtCountries.flatMap { [$0, Country.name(for: $0)] }
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

/// Kachel im Sammlungsraster.
struct CanCard: View {
    let flavor: Flavor

    var body: some View {
        VStack(spacing: 6) {
            CanView(color: Color(hexString: flavor.colorHex), height: 64)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .overlay(alignment: .topTrailing) {
                    if flavor.ownedCount > 1 {
                        Text("\(flavor.ownedCount)×")
                            .font(.ui(11, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                }
            Text(flavor.name)
                .font(.ui(12, .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 32)
            Text("\(origin) · \(flavor.sizeML) ml")
                .font(.ui(10))
                .foregroundStyle(Theme.secondary)
        }
        .cardStyle(padding: 8)
    }

    private var origin: String {
        let codes = Country.sorted(flavor.boughtCountries)
        return codes.first ?? "–"
    }
}
