import Foundation
import SwiftData

/// Mitgelieferter Startkatalog.
///
/// Die Länderverfügbarkeit ist eine Schätzung (Stand Ende 2026) und kann in der App je Sorte
/// korrigiert werden. Beim Hinzufügen einer Dose wird das Kaufland automatisch als
/// "erhältlich" ergänzt. Barcodes sind bewusst leer: Die App lernt sie beim Scannen.
enum Catalog {
    struct Seed {
        let key: String
        let name: String
        let line: ProductLine
        var subtitle: String = ""
        let color: String
        var size: Int = 500
        let countries: [String]
        var keywords: [String] = []
    }

    private static let europe = ["DE", "AT", "CH", "NL", "FR", "UK"]

    static let seeds: [Seed] = [
        // Original
        Seed(key: "original", name: "Monster Energy", line: .original, color: "#6BD31A",
             countries: europe + ["US", "JP"]),
        Seed(key: "zero-sugar", name: "Monster Zero Sugar", line: .original, subtitle: "Zero Sugar", color: "#3FA7E0",
             countries: europe + ["US"], keywords: ["zero sugar"]),
        Seed(key: "lo-carb", name: "Lo-Carb", line: .original, color: "#4AA3DF",
             countries: ["US", "UK"], keywords: ["lo-carb", "lo carb", "locarb"]),
        Seed(key: "nitro-super-dry", name: "Nitro Super Dry", line: .original, color: "#5B7C99",
             countries: ["US"], keywords: ["nitro", "super dry"]),
        Seed(key: "nitro-cosmic-peach", name: "Nitro Cosmic Peach", line: .original, color: "#F28A6B",
             countries: ["US"], keywords: ["cosmic peach", "cosmic"]),
        Seed(key: "reserve-watermelon", name: "Reserve Watermelon", line: .original, color: "#E2453C",
             countries: ["US", "UK"], keywords: ["reserve watermelon"]),
        Seed(key: "reserve-white-pineapple", name: "Reserve White Pineapple", line: .original, color: "#F5E3A1",
             countries: ["US", "UK", "DE"], keywords: ["pineapple"]),
        Seed(key: "lewis-hamilton", name: "Lewis Hamilton Zero Sugar", line: .original, subtitle: "Zero Sugar", color: "#B0B0B0",
             countries: europe + ["US"], keywords: ["hamilton", "lh44", "lewis"]),
        Seed(key: "the-doctor", name: "The Doctor", line: .original, color: "#F2D21B",
             countries: europe, keywords: ["the doctor", "doctor", "rossi", "vr46"]),
        Seed(key: "assault", name: "Assault", line: .original, color: "#7A7A5A",
             countries: ["US", "DE"], keywords: ["assault"]),
        Seed(key: "khaos", name: "Khaos", line: .original, color: "#F28C1B",
             countries: ["JP"], keywords: ["khaos"]),

        // Ultra
        Seed(key: "ultra-white", name: "Ultra White", line: .ultra, subtitle: "Zero Sugar", color: "#F2F2F2",
             countries: europe + ["US", "JP"], keywords: ["white"]),
        Seed(key: "ultra-paradise", name: "Ultra Paradise", line: .ultra, subtitle: "Zero Sugar", color: "#8FD26B",
             countries: europe + ["US", "JP"], keywords: ["paradise"]),
        Seed(key: "ultra-gold", name: "Ultra Gold", line: .ultra, subtitle: "Zero Sugar", color: "#D9B23A",
             countries: ["DE", "AT", "CH", "NL", "UK", "US"], keywords: ["gold"]),
        Seed(key: "ultra-watermelon", name: "Ultra Watermelon", line: .ultra, subtitle: "Zero Sugar", color: "#E5555F",
             countries: ["DE", "AT", "NL", "UK", "US"], keywords: ["watermelon"]),
        Seed(key: "ultra-fiesta", name: "Ultra Fiesta Mango", line: .ultra, subtitle: "Zero Sugar", color: "#F2A33A",
             countries: europe + ["US"], keywords: ["fiesta"]),
        Seed(key: "ultra-rosa", name: "Ultra Rosá", line: .ultra, subtitle: "Zero Sugar", color: "#E5559A",
             countries: europe + ["US"], keywords: ["rosa", "rosá"]),
        Seed(key: "ultra-violet", name: "Ultra Violet", line: .ultra, subtitle: "Zero Sugar", color: "#8E5BD9",
             countries: ["US"], keywords: ["violet"]),
        Seed(key: "ultra-blue", name: "Ultra Blue", line: .ultra, subtitle: "Zero Sugar", color: "#2F6FD6",
             countries: ["US", "JP"], keywords: ["blue"]),
        Seed(key: "ultra-red", name: "Ultra Red", line: .ultra, subtitle: "Zero Sugar", color: "#D63A3A",
             countries: ["US"], keywords: ["red"]),
        Seed(key: "ultra-sunrise", name: "Ultra Sunrise", line: .ultra, subtitle: "Zero Sugar", color: "#F27A3A",
             countries: ["US"], keywords: ["sunrise"]),
        Seed(key: "ultra-peachy-keen", name: "Ultra Peachy Keen", line: .ultra, subtitle: "Zero Sugar", color: "#F7B58C",
             countries: ["US", "UK"], keywords: ["peachy", "keen"]),
        Seed(key: "ultra-strawberry-dreams", name: "Ultra Strawberry Dreams", line: .ultra, subtitle: "Zero Sugar", color: "#E86A8A",
             countries: ["DE", "AT", "NL", "UK", "US"], keywords: ["strawberry", "dreams"]),
        Seed(key: "ultra-fantasy-ruby-red", name: "Ultra Fantasy Ruby Red", line: .ultra, subtitle: "Zero Sugar", color: "#B5203B",
             countries: ["DE", "AT", "UK", "US"], keywords: ["fantasy", "ruby"]),
        Seed(key: "ultra-vice-guava", name: "Ultra Vice Guava", line: .ultra, subtitle: "Zero Sugar", color: "#E35DA8",
             countries: ["US", "UK"], keywords: ["vice", "guava"]),
        Seed(key: "ultra-blue-hawaiian", name: "Ultra Blue Hawaiian", line: .ultra, subtitle: "Zero Sugar", color: "#35B3D9",
             countries: ["DE", "AT", "NL", "UK", "US"], keywords: ["hawaiian"]),
        Seed(key: "ultra-black", name: "Ultra Black", line: .ultra, subtitle: "Zero Sugar", color: "#3A3A3A",
             countries: ["US"], keywords: ["black"]),

        // Juice
        Seed(key: "pipeline-punch", name: "Pipeline Punch", line: .juice, color: "#E5559A",
             countries: europe + ["US", "JP"], keywords: ["pipeline"]),
        Seed(key: "mango-loco", name: "Mango Loco", line: .juice, color: "#35B3D9",
             countries: europe + ["US", "JP"], keywords: ["mango loco", "loco"]),
        Seed(key: "pacific-punch", name: "Pacific Punch", line: .juice, color: "#E8553A",
             countries: ["DE", "AT", "UK", "US"], keywords: ["pacific"]),
        Seed(key: "khaotic", name: "Khaotic", line: .juice, color: "#F2A01B",
             countries: ["DE", "AT", "NL", "UK", "US"], keywords: ["khaotic"]),
        Seed(key: "monarch", name: "Monarch", line: .juice, color: "#F28C3A",
             countries: ["DE", "UK", "US"], keywords: ["monarch"]),
        Seed(key: "aussie-lemonade", name: "Aussie Style Lemonade", line: .juice, color: "#F2E23A",
             countries: ["DE", "AT", "UK", "US"], keywords: ["aussie", "lemonade"]),
        Seed(key: "bad-apple", name: "Bad Apple", line: .juice, color: "#7FC241",
             countries: ["DE", "UK"], keywords: ["bad apple", "apple"]),
        Seed(key: "rio-punch", name: "Rio Punch", line: .juice, color: "#E8B83A",
             countries: ["US", "UK"], keywords: ["rio"]),

        // Rehab
        Seed(key: "rehab-peach-tea", name: "Rehab Peach Tea", line: .rehab, color: "#E8A06B", size: 458,
             countries: ["US", "UK"], keywords: ["peach tea", "rehab"]),
        Seed(key: "rehab-lemonade", name: "Rehab Lemonade", line: .rehab, color: "#F2D85B", size: 458,
             countries: ["US"], keywords: ["rehab lemonade"]),

        // Java
        Seed(key: "java-mean-bean", name: "Java Mean Bean", line: .java, color: "#8B5A3C", size: 443,
             countries: ["US"], keywords: ["mean bean", "java"]),
    ]

    /// Ergänzt fehlende Katalogsorten. Vorhandene Sorten (und deine Änderungen daran) bleiben unangetastet.
    @MainActor
    static func seed(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Flavor>())) ?? []
        let keys = Set(existing.map(\.key))
        var inserted = false
        for (index, seed) in seeds.enumerated() where !keys.contains(seed.key) {
            context.insert(Flavor(key: seed.key,
                                  name: seed.name,
                                  line: seed.line,
                                  subtitle: seed.subtitle,
                                  colorHex: seed.color,
                                  sizeML: seed.size,
                                  countries: seed.countries,
                                  keywords: seed.keywords,
                                  sortIndex: index))
            inserted = true
        }
        if inserted { try? context.save() }
    }
}
