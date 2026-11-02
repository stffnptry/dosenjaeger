import SwiftUI
import SwiftData
import PhotosUI

/// Screen 3: Erkannte Dose bestätigen und zur Sammlung hinzufügen.
struct ScanResultView: View {
    let result: ScanResult
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue

    @State private var selectedKey: String?
    @State private var manuallyChosen = false
    @State private var boughtIn = ""
    @State private var condition: CanCondition = .full
    @State private var quantity = 1
    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showPicker = false
    @State private var didSetup = false

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }
    private var flavor: Flavor? { flavors.first { $0.key == selectedKey } }

    private var confidence: Double? {
        guard !manuallyChosen, let selectedKey else { return nil }
        return result.matches.first { $0.key == selectedKey }?.confidence
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let flavor {
                    statusLine(flavor)
                    alternatives
                } else {
                    notRecognized
                }
                Divider().overlay(Theme.line)
                boughtInRow
                conditionPicker
                quantityRow
                if let flavor { availability(flavor) }
                Button("ZUR SAMMLUNG HINZUFÜGEN") { add() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(flavor == nil)
                    .opacity(flavor == nil ? 0.4 : 1)
                Button("Falsche Sorte? Manuell auswählen") { showPicker = true }
                    .font(.ui(13, .semibold))
                    .underline()
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .sheet(isPresented: $showPicker) {
            FlavorPickerView { picked in
                selectedKey = picked.key
                manuallyChosen = true
                showPicker = false
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    photo = image
                }
                pickerItem = nil
            }
        }
    }

    // MARK: Teile

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                if let photo {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Color(white: 0.08)
                    CanView(color: flavor.map { Color(hexString: $0.colorHex) } ?? Theme.tertiary, height: 96)
                }
            }
            .frame(width: 92, height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(alignment: .bottomTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: photo == nil ? "photo.badge.plus" : "arrow.triangle.2.circlepath")
                        .font(.ui(12, .semibold))
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                }
                .padding(4)
                .accessibilityLabel(photo == nil ? "Foto hinzufügen" : "Foto ersetzen")
            }

            VStack(alignment: .leading, spacing: 4) {
                Eyebrow(text: eyebrowText)
                Text((flavor?.name ?? "Unbekannte Dose").uppercased())
                    .font(.display(34))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if let flavor {
                    Text(flavor.detailLine).font(.ui(12)).foregroundStyle(Theme.secondary)
                }
                if let barcode = result.barcode {
                    Text("EAN \(barcode) · \(Country.region(for: boughtIn))-Version")
                        .font(.ui(12))
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    private var eyebrowText: String {
        if manuallyChosen || result.source == .manual { return "Manuell gewählt" }
        if let confidence { return "Erkannt · \(Int((confidence * 100).rounded())) % sicher" }
        return "Nicht erkannt"
    }

    private func statusLine(_ flavor: Flavor) -> some View {
        HStack(spacing: 8) {
            Image(systemName: flavor.isOwned ? "checkmark.circle" : "plus.circle")
            Text(flavor.isOwned
                 ? "Schon \(flavor.ownedCount)× in deiner Sammlung"
                 : "Neu – fehlt noch in deiner Sammlung")
        }
        .font(.ui(13, .semibold))
        .foregroundStyle(flavor.isOwned ? Theme.secondary : Theme.accent)
    }

    @ViewBuilder
    private var alternatives: some View {
        let others = result.matches.filter { $0.key != selectedKey }.compactMap { match in
            flavors.first { $0.key == match.key }
        }
        if !manuallyChosen, !others.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Oder vielleicht:").font(.ui(12)).foregroundStyle(Theme.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(others) { other in
                            Button {
                                selectedKey = other.key
                                Haptics.tap()
                            } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(Color(hexString: other.colorHex)).frame(width: 8, height: 8)
                                    Text(other.name)
                                }
                                .font(.ui(12, .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().stroke(Theme.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var notRecognized: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(result.barcode != nil
                 ? "Diesen Barcode kenne ich noch nicht. Wähl die Sorte einmal aus, dann merke ich sie mir."
                 : "Ich konnte die Sorte nicht sicher erkennen. Wähl sie bitte aus.")
                .font(.ui(13))
                .foregroundStyle(Theme.secondary)
            Button("SORTE AUSWÄHLEN") { showPicker = true }
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var boughtInRow: some View {
        Menu {
            ForEach(Country.all) { country in
                Button(country.name) { boughtIn = country.code }
            }
        } label: {
            HStack {
                Text("Gekauft in").foregroundStyle(Theme.secondary)
                Spacer()
                Text(Country.name(for: boughtIn)).fontWeight(.semibold).foregroundStyle(.white)
                Image(systemName: "chevron.right").font(.ui(12)).foregroundStyle(Theme.secondary)
            }
            .font(.ui(14))
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
        }
    }

    private var conditionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zustand").font(.ui(13)).foregroundStyle(Theme.secondary)
            HStack(spacing: 0) {
                ForEach(CanCondition.allCases) { item in
                    let selected = item == condition
                    Button {
                        condition = item
                        Haptics.tap()
                    } label: {
                        Text(item.rawValue)
                            .font(.ui(13, .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(selected ? Theme.accentDark : Color.clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private var quantityRow: some View {
        HStack {
            Text("Anzahl").font(.ui(13)).foregroundStyle(Theme.secondary)
            Spacer()
            QuantityStepper(value: $quantity)
        }
    }

    private func availability(_ flavor: Flavor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Erhältlich in deinen Ländern").font(.ui(13)).foregroundStyle(Theme.secondary)
            HStack(spacing: 6) {
                ForEach(tracked, id: \.self) { code in
                    CountryChip(code: code, available: flavor.isAvailable(in: code), highlighted: flavor.isAvailable(in: code))
                }
            }
        }
    }

    // MARK: Aktionen

    private func setup() {
        guard !didSetup else { return }
        didSetup = true
        selectedKey = result.matches.first?.key
        photo = result.image
        boughtIn = tracked.first ?? "DE"
    }

    private func add() {
        guard let flavor else { return }
        let item = CanItem(flavor: nil,
                           quantity: quantity,
                           condition: condition,
                           boughtIn: boughtIn,
                           barcode: result.barcode,
                           photo: photo?.compressedForStorage())
        context.insert(item)
        item.flavor = flavor
        // Lernen: Barcode merken, Kaufland als "erhältlich" eintragen.
        if let barcode = result.barcode, !flavor.barcodes.contains(barcode) {
            flavor.barcodes.append(barcode)
        }
        if !flavor.countries.contains(boughtIn) {
            flavor.countries = Country.sorted(flavor.countries + [boughtIn])
        }
        try? context.save()
        Haptics.success()
        onDone()
    }
}
