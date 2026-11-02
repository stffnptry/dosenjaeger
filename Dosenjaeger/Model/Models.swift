import Foundation
import SwiftData

enum ProductLine: String, CaseIterable, Identifiable, Codable {
    case original = "Original"
    case ultra = "Ultra"
    case juice = "Juice"
    case rehab = "Rehab"
    case java = "Java"
    case other = "Sonstige"

    var id: String { rawValue }
}

enum CanCondition: String, CaseIterable, Identifiable, Codable {
    case full = "Voll"
    case empty = "Leer"
    case damaged = "Beschädigt"

    var id: String { rawValue }
}

/// Eine Sorte (Geschmack) – kommt aus dem mitgelieferten Katalog oder ist selbst angelegt.
@Model
final class Flavor {
    @Attribute(.unique) var key: String
    var name: String
    var lineRaw: String
    /// Zusatz wie "Zero Sugar".
    var subtitle: String
    var colorHex: String
    var sizeML: Int
    /// Ländercodes, in denen die Sorte erhältlich ist (DE, AT, CH, NL, FR, UK, US, JP).
    var countries: [String]
    /// Gelernte EAN/UPC-Codes; werden beim Scannen ergänzt.
    var barcodes: [String]
    /// Begriffe, nach denen die Texterkennung auf dem Foto sucht.
    var keywords: [String]
    var isCustom: Bool
    /// In der Tauschliste freigegeben.
    var tradeable: Bool
    var sortIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \CanItem.flavor)
    var items: [CanItem] = []

    init(key: String,
         name: String,
         line: ProductLine,
         subtitle: String = "",
         colorHex: String,
         sizeML: Int = 500,
         countries: [String],
         barcodes: [String] = [],
         keywords: [String] = [],
         isCustom: Bool = false,
         sortIndex: Int) {
        self.key = key
        self.name = name
        self.lineRaw = line.rawValue
        self.subtitle = subtitle
        self.colorHex = colorHex
        self.sizeML = sizeML
        self.countries = countries
        self.barcodes = barcodes
        self.keywords = keywords
        self.isCustom = isCustom
        self.tradeable = false
        self.sortIndex = sortIndex
    }

    var line: ProductLine {
        get { ProductLine(rawValue: lineRaw) ?? .other }
        set { lineRaw = newValue.rawValue }
    }

    /// Anzahl Dosen dieser Sorte in der Sammlung.
    var ownedCount: Int { items.reduce(0) { $0 + max(1, $1.quantity) } }
    var isOwned: Bool { ownedCount > 0 }
    var duplicates: Int { max(0, ownedCount - 1) }

    var firstAdded: Date? { items.map(\.addedAt).min() }

    /// Zeile unter dem Namen: "Ultra · Zero Sugar · 500 ml".
    var detailLine: String {
        var parts = [line.rawValue]
        if !subtitle.isEmpty { parts.append(subtitle) }
        parts.append("\(sizeML) ml")
        return parts.joined(separator: " · ")
    }

    /// Überzeile auf der Detailseite: "ULTRA · ZERO SUGAR".
    var eyebrow: String {
        subtitle.isEmpty ? line.rawValue : "\(line.rawValue) · \(subtitle)"
    }

    func isAvailable(in code: String) -> Bool { countries.contains(code) }

    func isAvailable(inAnyOf codes: [String]) -> Bool {
        codes.contains { countries.contains($0) }
    }

    /// Länder, in denen bereits ein Exemplar gekauft wurde.
    var boughtCountries: Set<String> { Set(items.map(\.boughtIn)) }

    /// Version des zuletzt erfassten Exemplars (EU, UK, US, JP).
    var marketVersion: String {
        let latest = items.max { $0.addedAt < $1.addedAt }
        if let code = latest?.boughtIn ?? countries.first {
            return Country.region(for: code)
        }
        return "–"
    }
}

/// Ein Exemplar (oder mehrere gleiche) in der Sammlung.
@Model
final class CanItem {
    var flavor: Flavor?
    var quantity: Int
    var conditionRaw: String
    /// Ländercode, in dem die Dose gekauft wurde.
    var boughtIn: String
    var addedAt: Date
    var barcode: String?
    @Attribute(.externalStorage) var photo: Data?

    init(flavor: Flavor?,
         quantity: Int = 1,
         condition: CanCondition = .full,
         boughtIn: String,
         addedAt: Date = .now,
         barcode: String? = nil,
         photo: Data? = nil) {
        self.flavor = flavor
        self.quantity = quantity
        self.conditionRaw = condition.rawValue
        self.boughtIn = boughtIn
        self.addedAt = addedAt
        self.barcode = barcode
        self.photo = photo
    }

    var condition: CanCondition {
        get { CanCondition(rawValue: conditionRaw) ?? .full }
        set { conditionRaw = newValue.rawValue }
    }
}
