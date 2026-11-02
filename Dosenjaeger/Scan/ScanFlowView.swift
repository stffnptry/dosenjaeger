import SwiftUI
import SwiftData
import PhotosUI

/// Vollbild-Ablauf: Kamera → Ergebnis → Hinzufügen.
struct ScanFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var result: ScanResult?

    var body: some View {
        NavigationStack {
            CameraScreen(onResult: { result = $0 }, onClose: { dismiss() })
                .navigationDestination(item: $result) { result in
                    ScanResultView(result: result, onDone: { dismiss() })
                }
        }
    }
}

/// Screen 2: DOSE SCANNEN
struct CameraScreen: View {
    enum Mode: Hashable { case photo, barcode }

    let onResult: (ScanResult) -> Void
    let onClose: () -> Void

    @Query(sort: \Flavor.sortIndex) private var flavors: [Flavor]
    @StateObject private var camera = CameraModel()
    @State private var mode: Mode = .photo
    @State private var analyzing = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showManual = false

    var body: some View {
        VStack(spacing: 14) {
            topBar
            PillToggle(selection: $mode, options: [(value: Mode.photo, label: "Foto"), (value: Mode.barcode, label: "Barcode")], compact: true)
            statusChip
            viewfinder
            Text(mode == .photo
                 ? "Dose mit der Vorderseite mittig ausrichten.\nDer Barcode auf der Rückseite verbessert die Erkennung der Länderversion."
                 : "Halte den Barcode auf der Rückseite in den Rahmen.\nDie App merkt sich jeden Barcode für die nächste Dose.")
                .font(.ui(12))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer(minLength: 0)
            bottomBar
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.black.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await camera.start() }
        .onAppear {
            camera.barcodeMode = mode == .barcode
            camera.detectedBarcode = nil
        }
        .onDisappear { camera.stop() }
        .onChange(of: mode) { _, newMode in
            camera.barcodeMode = newMode == .barcode
            camera.detectedBarcode = nil
        }
        .onChange(of: camera.detectedBarcode) { _, code in
            guard let code, mode == .barcode, !analyzing else { return }
            Haptics.success()
            onResult(CanRecognizer.lookup(barcode: code, flavors: flavors.map(FlavorSnapshot.init)))
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            pickerItem = nil
            Task { await loadFromLibrary(item) }
        }
        .sheet(isPresented: $showManual) {
            FlavorPickerView { flavor in
                showManual = false
                onResult(.manual(key: flavor.key))
            }
        }
    }

    // MARK: Teile

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark").font(.ui(18, .semibold))
            }
            .accessibilityLabel("Schließen")
            Spacer()
            Text("DOSE SCANNEN").font(.display(24))
            Spacer()
            Button { camera.toggleTorch() } label: {
                Image(systemName: camera.torchOn ? "bolt.fill" : "bolt").font(.ui(18, .semibold))
            }
            .accessibilityLabel("Licht")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var statusChip: some View {
        let text: String = {
            if analyzing { return "Erkenne Dose …" }
            switch camera.access {
            case .denied: return "Kein Kamerazugriff"
            case .unavailable: return "Keine Kamera verfügbar"
            default: return mode == .photo ? "Bereit für ein Foto" : "Suche Barcode …"
            }
        }()
        HStack(spacing: 8) {
            if analyzing {
                ProgressView().controlSize(.mini).tint(Theme.accent)
            } else {
                Circle().fill(Theme.accent).frame(width: 7, height: 7)
            }
            Text(text).font(.ui(12, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(Theme.accentDark.opacity(0.45)))
        .overlay(Capsule().stroke(Theme.accent, lineWidth: 1))
    }

    private var viewfinder: some View {
        ZStack {
            switch camera.access {
            case .granted:
                CameraPreview(session: camera.session)
            case .denied:
                placeholder("Erlaube den Kamerazugriff in den Einstellungen.\nAlternativ: Mediathek oder Manuell.",
                            showSettings: true)
            case .unavailable:
                placeholder("Auf diesem Gerät gibt es keine Kamera.\nNutze Mediathek oder Manuell.")
            case .unknown:
                Color.black
            }
            ViewfinderCorners()
                .stroke(Theme.accent, lineWidth: 3)
            if mode == .barcode {
                Rectangle().fill(Theme.accent).frame(height: 2).padding(.horizontal, 30)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .frame(maxWidth: .infinity)
        .aspectRatio(0.72, contentMode: .fit)
        .padding(.horizontal, 36)
    }

    private func placeholder(_ text: String, showSettings: Bool = false) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera").font(.ui(28)).foregroundStyle(Theme.tertiary)
            Text(text).font(.ui(12)).foregroundStyle(Theme.secondary).multilineTextAlignment(.center)
            if showSettings, let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Einstellungen öffnen", destination: url).font(.ui(13, .semibold))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.08))
    }

    private var bottomBar: some View {
        HStack(alignment: .center) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                barButton(icon: "photo", label: "Mediathek")
            }
            .frame(maxWidth: .infinity)

            Button {
                Task { await shoot() }
            } label: {
                ZStack {
                    Circle().stroke(Color.white, lineWidth: 4).frame(width: 74, height: 74)
                    Circle().fill(Color.white).frame(width: 60, height: 60)
                }
            }
            .disabled(mode != .photo || analyzing || camera.access != .granted)
            .opacity(mode == .photo && camera.access == .granted ? 1 : 0.35)
            .accessibilityLabel("Foto aufnehmen")
            .frame(maxWidth: .infinity)

            Button { showManual = true } label: {
                barButton(icon: "line.3.horizontal", label: "Manuell")
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
    }

    private func barButton(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.ui(20))
            Text(label).font(.ui(11))
        }
        .foregroundStyle(.white)
    }

    // MARK: Aktionen

    private func shoot() async {
        analyzing = true
        defer { analyzing = false }
        guard let image = await camera.capturePhoto() else { return }
        await analyze(image)
    }

    private func loadFromLibrary(_ item: PhotosPickerItem) async {
        analyzing = true
        defer { analyzing = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await analyze(image)
    }

    private func analyze(_ image: UIImage) async {
        let snapshots = flavors.map(FlavorSnapshot.init)
        let result = await CanRecognizer.analyze(image: image, flavors: snapshots)
        Haptics.success()
        onResult(result)
    }
}

/// Grüne Ecken des Suchers.
struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(rect.width, rect.height) * 0.12
        var path = Path()
        let r = rect.insetBy(dx: 1.5, dy: 1.5)
        // oben links
        path.move(to: CGPoint(x: r.minX, y: r.minY + length))
        path.addLine(to: CGPoint(x: r.minX, y: r.minY))
        path.addLine(to: CGPoint(x: r.minX + length, y: r.minY))
        // oben rechts
        path.move(to: CGPoint(x: r.maxX - length, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.minY + length))
        // unten rechts
        path.move(to: CGPoint(x: r.maxX, y: r.maxY - length))
        path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.maxX - length, y: r.maxY))
        // unten links
        path.move(to: CGPoint(x: r.minX + length, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.maxY - length))
        return path
    }
}
