import Foundation
import SwiftUI

struct Country: Identifiable, Hashable {
    let code: String
    let short: String
    let name: String

    var id: String { code }

    /// Die Länder aus dem Entwurf, in fester Reihenfolge.
    static let all: [Country] = [
        Country(code: "DE", short: "Deutschl.", name: "Deutschland"),
        Country(code: "AT", short: "Österr.", name: "Österreich"),
        Country(code: "CH", short: "Schweiz", name: "Schweiz"),
        Country(code: "NL", short: "Niederl.", name: "Niederlande"),
        Country(code: "FR", short: "Frankr.", name: "Frankreich"),
        Country(code: "UK", short: "UK", name: "Vereinigtes Königreich"),
        Country(code: "US", short: "USA", name: "USA"),
        Country(code: "JP", short: "Japan", name: "Japan"),
    ]

    static let allCodes: [String] = all.map(\.code)

    static func name(for code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }

    /// Dosenversion nach Markt.
    static func region(for code: String) -> String {
        switch code {
        case "UK": return "UK"
        case "US": return "US"
        case "JP": return "JP"
        case "CH": return "CH"
        default: return "EU"
        }
    }

    /// Codes in der festen Reihenfolge, Unbekanntes am Ende.
    static func sorted(_ codes: some Sequence<String>) -> [String] {
        let set = Set(codes)
        let known = allCodes.filter { set.contains($0) }
        let unknown = set.subtracting(allCodes).sorted()
        return known + unknown
    }

    /// "DE, AT, UK oder US"
    static func spokenList(_ codes: [String]) -> String {
        guard codes.count > 1 else { return codes.first ?? "" }
        return codes.dropLast().joined(separator: ", ") + " oder " + codes.last!
    }
}

/// Die vom Nutzer verfolgten Länder, gespeichert als "DE,AT,UK,US".
enum TrackedCountries {
    static let storageKey = "trackedCountries"
    static let defaultValue = "DE,AT,UK,US"

    static func parse(_ raw: String) -> [String] {
        Country.sorted(raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    static func serialize(_ codes: [String]) -> String {
        Country.sorted(codes).joined(separator: ",")
    }
}

/// Kennzahlen für Sammlung, Länder und Fehlend.
struct CollectionStats {
    let tracked: [String]
    let relevant: [Flavor]
    let missing: [Flavor]
    let totalCans: Int
    let duplicates: Int

    init(flavors: [Flavor], tracked: [String]) {
        self.tracked = tracked
        let relevant = flavors.filter { $0.isAvailable(inAnyOf: tracked) }
        self.relevant = relevant
        self.missing = relevant.filter { !$0.isOwned }
        self.totalCans = flavors.reduce(0) { $0 + $1.ownedCount }
        self.duplicates = flavors.reduce(0) { $0 + $1.duplicates }
    }

    var ownedRelevant: Int { relevant.count - missing.count }

    var progress: Double {
        relevant.isEmpty ? 0 : Double(ownedRelevant) / Double(relevant.count)
    }
}
