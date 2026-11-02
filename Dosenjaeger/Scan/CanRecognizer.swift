import Foundation
import UIKit
import Vision

/// Ergebnis eines Scans – wird an den Ergebnis-Screen übergeben.
struct ScanResult: Identifiable, Hashable {
    struct Match: Hashable {
        let key: String
        let confidence: Double
    }

    enum Source: Hashable { case photo, barcode, manual }

    let id = UUID()
    var source: Source
    var image: UIImage?
    var barcode: String?
    /// Kandidaten, beste zuerst.
    var matches: [Match]

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static func manual(key: String?) -> ScanResult {
        ScanResult(source: .manual, image: nil, barcode: nil,
                   matches: key.map { [Match(key: $0, confidence: 1)] } ?? [])
    }
}

/// Was die Erkennung über eine Sorte wissen muss (thread-sicher kopiert).
struct FlavorSnapshot: Sendable {
    let key: String
    let name: String
    let isUltra: Bool
    let keywords: [String]
    let barcodes: [String]
    let colorHex: String

    init(_ flavor: Flavor) {
        key = flavor.key
        name = flavor.name
        isUltra = flavor.line == .ultra
        keywords = flavor.keywords
        barcodes = flavor.barcodes
        colorHex = flavor.colorHex
    }
}

/// Erkennt eine Dose auf einem Foto – komplett auf dem Gerät:
/// 1. Barcode (EAN/UPC) im Bild → bekannte Sorte mit 99 %.
/// 2. Texterkennung (Vision) → Abgleich mit Sortennamen und Stichwörtern.
/// 3. Dominante Farbe als Feinabstimmung zwischen ähnlichen Treffern.
enum CanRecognizer {
    static func analyze(image: UIImage, flavors: [FlavorSnapshot]) async -> ScanResult {
        await Task.detached(priority: .userInitiated) {
            let (texts, barcode) = CanRecognizer.readImage(image)
            let hue = CanRecognizer.dominantHue(of: image)
            let matches = CanRecognizer.rank(texts: texts, barcode: barcode, hue: hue, flavors: flavors)
            return ScanResult(source: .photo, image: image, barcode: barcode, matches: matches)
        }.value
    }

    static func lookup(barcode: String, flavors: [FlavorSnapshot]) -> ScanResult {
        let matches = flavors
            .filter { $0.barcodes.contains(barcode) }
            .map { ScanResult.Match(key: $0.key, confidence: 0.99) }
        return ScanResult(source: .barcode, image: nil, barcode: barcode, matches: matches)
    }

    // MARK: Vision

    static func readImage(_ image: UIImage) -> ([String], String?) {
        guard let cgImage = image.cgImage else { return ([], nil) }
        let handler = VNImageRequestHandler(cgImage: cgImage,
                                            orientation: CGImagePropertyOrientation(image.imageOrientation),
                                            options: [:])
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = false
        textRequest.minimumTextHeight = 0.015
        let barcodeRequest = VNDetectBarcodesRequest()
        barcodeRequest.symbologies = [.ean13, .ean8, .upce]

        do {
            try handler.perform([textRequest, barcodeRequest])
        } catch {
            return ([], nil)
        }
        let texts = (textRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        let barcode = (barcodeRequest.results ?? []).compactMap(\.payloadStringValue).first
        return (texts, barcode)
    }

    // MARK: Abgleich

    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en")).lowercased()
        let mapped = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(mapped).split(separator: " ").joined(separator: " ")
    }

    static func rank(texts: [String], barcode: String?, hue: Double?, flavors: [FlavorSnapshot]) -> [ScanResult.Match] {
        if let barcode {
            let known = flavors.filter { $0.barcodes.contains(barcode) }
            if !known.isEmpty {
                return known.map { ScanResult.Match(key: $0.key, confidence: 0.99) }
            }
        }

        let hay = " " + normalize(texts.joined(separator: " ")) + " "
        let tokens = Set(hay.split(separator: " ").map(String.init))
        let saysUltra = hay.contains(" ultra ")
        let saysMonster = hay.contains("monster") || tokens.contains { distance($0, "monster") <= 1 }

        var scored: [ScanResult.Match] = []
        for flavor in flavors {
            var phrases = flavor.keywords.map(normalize)
            if phrases.isEmpty {
                // Ohne Stichwörter: unterscheidende Wörter des Namens.
                let generic: Set<String> = ["monster", "energy", "ultra", "zero", "sugar", "juice"]
                phrases = normalize(flavor.name).split(separator: " ").map(String.init).filter { !generic.contains($0) }
            }

            var best = 0
            for phrase in phrases where !phrase.isEmpty {
                if hay.contains(" \(phrase) ") || (phrase.count >= 6 && hay.contains(phrase)) {
                    best = max(best, phrase.count)
                } else if !phrase.contains(" "), phrase.count >= 5,
                          tokens.contains(where: { abs($0.count - phrase.count) <= 1 && distance($0, phrase) <= 1 }) {
                    best = max(best, phrase.count - 1)
                }
            }

            var confidence: Double
            if best > 0 {
                confidence = 0.62 + min(0.26, Double(best) * 0.03)
                if flavor.isUltra && saysUltra { confidence += 0.06 }
                if !flavor.isUltra && saysUltra { confidence -= 0.12 }
                if flavor.isUltra && !saysUltra && !hay.trimmingCharacters(in: .whitespaces).isEmpty { confidence -= 0.04 }
            } else if phrases.isEmpty && saysMonster && !saysUltra {
                // Das klassische Monster Energy: nur "Monster", sonst nichts Spezifisches.
                confidence = 0.45
            } else {
                continue
            }

            if let hue, let flavorHue = hueOf(hex: flavor.colorHex) {
                let delta = min(abs(hue - flavorHue), 1 - abs(hue - flavorHue))
                confidence += delta < 0.06 ? 0.04 : (delta > 0.25 ? -0.03 : 0)
            }
            scored.append(.init(key: flavor.key, confidence: min(0.98, max(0.05, confidence))))
        }
        return scored.sorted { $0.confidence > $1.confidence }.prefix(4).map { $0 }
    }

    /// Levenshtein-Distanz für OCR-Tippfehler auf gewölbten Dosen.
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                current[j] = min(previous[j] + 1,
                                 current[j - 1] + 1,
                                 previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            previous = current
        }
        return previous[b.count]
    }

    // MARK: Farbe

    /// Mittlerer Farbton der kräftig gefärbten Pixel in der Bildmitte (0…1), nil bei grauem Bild.
    static func dominantHue(of image: UIImage) -> Double? {
        guard let cgImage = image.cgImage else { return nil }
        let size = 32
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: size, height: size,
                                          bitsPerComponent: 8, bytesPerRow: size * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drawn else { return nil }

        var sumX = 0.0, sumY = 0.0, count = 0
        for y in (size / 4)..<(size * 3 / 4) {
            for x in (size / 4)..<(size * 3 / 4) {
                let i = (y * size + x) * 4
                let color = UIColor(red: CGFloat(pixels[i]) / 255, green: CGFloat(pixels[i + 1]) / 255,
                                    blue: CGFloat(pixels[i + 2]) / 255, alpha: 1)
                var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
                color.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
                guard s > 0.35, v > 0.3 else { continue }
                sumX += cos(Double(h) * 2 * .pi)
                sumY += sin(Double(h) * 2 * .pi)
                count += 1
            }
        }
        guard count > 12 else { return nil }
        var angle = atan2(sumY, sumX) / (2 * .pi)
        if angle < 0 { angle += 1 }
        return angle
    }

    static func hueOf(hex: String) -> Double? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        guard let value = UInt32(cleaned, radix: 16) else { return nil }
        let color = UIColor(red: CGFloat((value >> 16) & 0xFF) / 255,
                            green: CGFloat((value >> 8) & 0xFF) / 255,
                            blue: CGFloat(value & 0xFF) / 255, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
        return s > 0.25 ? Double(h) : nil
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

extension UIImage {
    /// Verkleinert auf maximal `maxDimension` Pixel und liefert JPEG-Daten zum Speichern.
    func compressedForStorage(maxDimension: CGFloat = 1200) -> Data? {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.72)
    }
}
