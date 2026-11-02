import SwiftUI
import SwiftData

/// Screen 6: Detail einer Sorte mit Exemplaren und Verfügbarkeit.
struct FlavorDetailView: View {
    @Bindable var flavor: Flavor

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TrackedCountries.storageKey) private var trackedRaw = TrackedCountries.defaultValue
    @State private var showAdd = false
    @State private var showEdit = false
    @State private var editingItem: CanItem?
    @State private var confirmDelete = false

    private var tracked: [String] { TrackedCountries.parse(trackedRaw) }
    private var items: [CanItem] { flavor.items.sorted { $0.addedAt < $1.addedAt } }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                statsRow
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Meine Exemplare")
                    if items.isEmpty {
                        Text("Noch kein Exemplar. Füg eins hinzu, sobald du die Dose hast.")
                            .font(.ui(13))
                            .foregroundStyle(Theme.secondary)
                    } else {
                        let list = items
                        ForEach(list.indices, id: \.self) { index in
                            itemRow(list[index], number: index + 1)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Erhältlich in")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(Country.all) { country in
                            let available = flavor.isAvailable(in: country.code)
                            HStack(spacing: 5) {
                                Text(country.code)
                                if available { Circle().frame(width: 6, height: 6) } else { Text("–") }
                            }
                            .font(.ui(12, .bold))
                            .foregroundStyle(available ? (tracked.contains(country.code) ? Theme.accent : .white) : Theme.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(available ? Theme.accent.opacity(tracked.contains(country.code) ? 0.7 : 0.25) : Theme.line, lineWidth: 1))
                        }
                    }
                }
                HStack(spacing: 10) {
                    Button("+ EXEMPLAR") { showAdd = true }
                        .buttonStyle(PrimaryButtonStyle())
                    NavigationLink(value: TradeRoute()) {
                        Text("TAUSCHEN")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow(text: flavor.eyebrow)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Sorte & Verfügbarkeit bearbeiten", systemImage: "pencil") }
                    if flavor.isCustom {
                        Button(role: .destructive) { confirmDelete = true } label: { Label("Sorte löschen", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                ScanResultView(result: .manual(key: flavor.key), onDone: { showAdd = false })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { showAdd = false }
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showEdit) {
            FlavorEditView(flavor: flavor)
        }
        .sheet(item: $editingItem) { item in
            ItemEditView(item: item)
        }
        .confirmationDialog("„\(flavor.name)“ mit allen Exemplaren löschen?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                let doomed = flavor
                let modelContext = context
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    modelContext.delete(doomed)
                    try? modelContext.save()
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            if let photo = items.last?.photo, let image = UIImage(data: photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                CanView(color: Color(hexString: flavor.colorHex), height: 170)
                    .padding(.top, 6)
            }
            Text(flavor.name.uppercased())
                .font(.display(44))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(flavor.isOwned
                 ? "In Sammlung · \(flavor.ownedCount) \(flavor.ownedCount == 1 ? "Exemplar" : "Exemplare")"
                 : "Fehlt noch in deiner Sammlung")
                .font(.ui(13, .semibold))
                .foregroundStyle(flavor.isOwned ? Theme.accent : Theme.warning)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            stat("Größe", "\(flavor.sizeML) ml")
            Divider().overlay(Theme.line)
            stat("Version", flavor.marketVersion)
            Divider().overlay(Theme.line)
            stat("Seit", flavor.firstAdded.map { $0.formatted(.dateTime.month(.twoDigits).year()) } ?? "–")
        }
        .frame(height: 64)
        .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.line).frame(height: 1) }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.ui(11)).foregroundStyle(Theme.secondary)
            Text(value).font(.display(24))
        }
        .frame(maxWidth: .infinity)
    }

    private func itemRow(_ item: CanItem, number: Int) -> some View {
        Button {
            editingItem = item
        } label: {
            HStack(spacing: 12) {
                PhotoThumb(data: item.photo, size: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text("#\(number) · \(item.condition.rawValue)\(item.quantity > 1 ? " · \(item.quantity)×" : "")")
                        .font(.ui(14, .semibold))
                    Text("Gekauft in \(Country.name(for: item.boughtIn)) · \(item.addedAt.formatted(date: .numeric, time: .omitted))")
                        .font(.ui(12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Image(systemName: "pencil").foregroundStyle(Theme.secondary)
            }
            .foregroundStyle(.white)
            .cardStyle(padding: 10)
        }
        .buttonStyle(.plain)
    }
}

/// Ein Exemplar bearbeiten oder löschen.
struct ItemEditView: View {
    @Bindable var item: CanItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Zustand", selection: Binding(get: { item.condition }, set: { item.condition = $0 })) {
                        ForEach(CanCondition.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Gekauft in", selection: $item.boughtIn) {
                        ForEach(Country.all) { Text($0.name).tag($0.code) }
                    }
                    Stepper("Anzahl: \(item.quantity)", value: $item.quantity, in: 1...99)
                    DatePicker("Erfasst am", selection: $item.addedAt, displayedComponents: .date)
                    if let barcode = item.barcode {
                        LabeledContent("Barcode", value: barcode)
                    }
                }
                .listRowBackground(Color.black)

                Section {
                    Button("Exemplar löschen", role: .destructive) {
                        let doomed = item
                        let modelContext = context
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            modelContext.delete(doomed)
                            try? modelContext.save()
                        }
                    }
                }
                .listRowBackground(Color.black)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Exemplar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
