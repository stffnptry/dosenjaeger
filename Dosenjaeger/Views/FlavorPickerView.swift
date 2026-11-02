import SwiftUI
import SwiftData

/// Manuelle Sortenauswahl (aus Scan und Ergebnis-Screen).
struct FlavorPickerView: View {
    let onPick: (Flavor) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @State private var search = ""
    @State private var showNew = false

    private var filtered: [Flavor] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return flavors }
        return flavors.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ProductLine.allCases) { line in
                    let group = filtered.filter { $0.line == line }
                    if !group.isEmpty {
                        Section(line.rawValue) {
                            ForEach(group) { flavor in
                                Button { onPick(flavor) } label: { row(flavor) }
                                    .listRowBackground(Color.black)
                            }
                        }
                    }
                }
                Section {
                    Button {
                        showNew = true
                    } label: {
                        Label("Neue Sorte anlegen", systemImage: "plus")
                            .foregroundStyle(Theme.accent)
                    }
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .searchable(text: $search, prompt: "Sorte suchen")
            .navigationTitle("Sorte wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .sheet(isPresented: $showNew) {
                FlavorEditView(flavor: nil) { created in
                    if let created { onPick(created) }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func row(_ flavor: Flavor) -> some View {
        HStack(spacing: 12) {
            CanView(color: Color(hexString: flavor.colorHex), height: 40)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(flavor.name).font(.ui(15, .semibold)).foregroundStyle(.white)
                Text(flavor.detailLine).font(.ui(11)).foregroundStyle(Theme.secondary)
            }
            Spacer()
            if flavor.isOwned {
                Text("\(flavor.ownedCount)×").font(.ui(12, .bold)).foregroundStyle(Theme.accent)
            }
        }
    }
}

/// Sorte anlegen oder Verfügbarkeit/Daten einer Sorte bearbeiten.
struct FlavorEditView: View {
    let flavor: Flavor?
    var onFinish: (Flavor?) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allFlavors: [Flavor]

    @State private var name = ""
    @State private var subtitle = ""
    @State private var line: ProductLine = .original
    @State private var color: Color = Theme.accent
    @State private var size = 500
    @State private var countries: Set<String> = []
    @State private var barcodes: [String] = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sorte") {
                    TextField("Name, z. B. Ultra Paradise", text: $name)
                    TextField("Zusatz, z. B. Zero Sugar", text: $subtitle)
                    Picker("Linie", selection: $line) {
                        ForEach(ProductLine.allCases) { Text($0.rawValue).tag($0) }
                    }
                    ColorPicker("Farbe", selection: $color, supportsOpacity: false)
                    Stepper("Größe: \(size) ml", value: $size, in: 150...1000, step: 1)
                }
                .listRowBackground(Color.black)

                Section {
                    ForEach(Country.all) { country in
                        Toggle(isOn: Binding(
                            get: { countries.contains(country.code) },
                            set: { on in
                                if on { countries.insert(country.code) } else { countries.remove(country.code) }
                            })) {
                            Text("\(country.code) · \(country.name)")
                        }
                    }
                } header: {
                    Text("Erhältlich in")
                } footer: {
                    Text("Die Verfügbarkeit im Katalog ist eine Schätzung. Korrigier sie hier, wenn du es besser weißt.")
                }
                .listRowBackground(Color.black)

                if !barcodes.isEmpty {
                    Section("Gelernte Barcodes") {
                        ForEach(barcodes, id: \.self) { Text($0).font(.ui(14).monospacedDigit()) }
                            .onDelete { barcodes.remove(atOffsets: $0) }
                    }
                    .listRowBackground(Color.black)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(flavor == nil ? "Neue Sorte" : "Sorte bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
        .preferredColorScheme(.dark)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let flavor else {
            countries = Set(["DE"])
            return
        }
        name = flavor.name
        subtitle = flavor.subtitle
        line = flavor.line
        color = Color(hexString: flavor.colorHex)
        size = flavor.sizeML
        countries = Set(flavor.countries)
        barcodes = flavor.barcodes
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let target: Flavor
        if let flavor {
            target = flavor
        } else {
            let base = trimmedName.lowercased().replacingOccurrences(of: " ", with: "-")
            target = Flavor(key: "custom-\(base)-\(UUID().uuidString.prefix(6))",
                            name: trimmedName,
                            line: line,
                            colorHex: color.hexString,
                            countries: [],
                            isCustom: true,
                            sortIndex: 10_000 + allFlavors.count)
            context.insert(target)
        }
        target.name = trimmedName
        target.subtitle = subtitle.trimmingCharacters(in: .whitespaces)
        target.line = line
        target.colorHex = color.hexString
        target.sizeML = size
        target.countries = Country.sorted(countries)
        target.barcodes = barcodes
        if target.isCustom {
            target.keywords = [trimmedName]
        }
        try? context.save()
        onFinish(target)
        dismiss()
    }
}
