# Dosenjäger

iOS-App (SwiftUI, iOS 17+) zum Verwalten deiner Monster-Energy-Dosensammlung – nach dem Design-Entwurf „Dosenjäger – iOS App“.

## Funktionen

- **Meine Sammlung:** Zahlen (Gesammelt, Fehlend, Doppelt), Fortschritt in deinen Ländern, Suche nach Sorte/Land/Barcode, Filter Alle/Original/Ultra/Juice/Weitere, Raster mit Anzahl-Badge.
- **Dose scannen:** Kamera mit Foto- und Barcode-Modus, Licht, Mediathek und manuelle Auswahl.
  - *Foto:* Texterkennung (Apple Vision) liest den Sortennamen, dazu Barcode im Bild und Farbton der Dose. Alles läuft auf dem Gerät, ohne Internet.
  - *Barcode:* Live-Scan von EAN/UPC. Die App merkt sich jeden Barcode, sobald du die Sorte einmal bestätigt hast; danach wird die Dose sofort erkannt.
- **Ergebnis:** erkannte Sorte mit Sicherheit in %, Alternativen, „Neu – fehlt noch“, Gekauft in, Zustand (Voll/Leer/Beschädigt), Anzahl, Verfügbarkeit in deinen Ländern.
- **Länder:** DE, AT, CH, NL, FR, UK, US, JP auswählen; Sorten-Matrix (weiß = erhältlich, grün = dort gekauft, – = nicht erhältlich).
- **Fehlend:** Wunschliste für „Meine Länder“ oder „Weltweit“, mit Länder-Chips (grün = in deinen Ländern).
- **Sortendetail:** Exemplare mit Foto, Kaufland und Datum (bearbeiten/löschen), „Erhältlich in“, Sorte und Verfügbarkeit bearbeiten.
- **Tauschen:** Doppelte zum Tausch freigeben, „Ich suche“-Liste, Tauschliste als Text oder Bild teilen.
- **Eigene Sorten** anlegen (Name, Linie, Farbe, Größe, Länder).

## Grenzen

- Der Startkatalog (~40 Sorten) und vor allem die **Länderverfügbarkeit sind Schätzungen**. Korrigier sie in der App (Sortendetail → ⋯). Wenn du eine Dose mit Kaufland hinzufügst, trägt die App dieses Land automatisch als „erhältlich“ ein.
- Barcodes sind nicht vorbelegt, die App lernt sie beim Scannen.
- Die Fotoerkennung braucht lesbaren Sortennamen auf dem Foto. Klappt es nicht: „Manuell“ oder Barcode-Modus.
- Daten liegen lokal (SwiftData), kein iCloud-Sync.

## Bauen

**Auf dem Mac (empfohlen):**

1. `Dosenjaeger.xcodeproj` in Xcode 16 oder neuer öffnen.
2. Target *Dosenjaeger* → *Signing & Capabilities* → dein Team (kostenloser Apple-Account reicht) wählen. Falls die Bundle-ID schon vergeben ist, `de.stffnptry.dosenjaeger` leicht ändern.
3. iPhone per Kabel anschließen, als Ziel wählen, ▶︎ drücken. Auf dem iPhone einmal *Einstellungen → Allgemein → VPN & Geräteverwaltung* dem Entwicklerzertifikat vertrauen (und ggf. den Entwicklermodus aktivieren).

**Unsignierte .ipa per GitHub Actions:** Jeder Push auf `main` baut auf einem macOS-Runner und legt die Datei unter *Releases → latest* ab (`Dosenjaeger-unsigned.ipa`). Ein Tag `v1.0` erzeugt ein festes Release.

**IPA ohne Mac aufs iPhone:** [Sideloadly](https://sideloadly.io) (Windows/macOS) oder AltStore installieren, `.ipa` hineinziehen, mit Apple-ID signieren lassen. Mit einem kostenlosen Apple-Account läuft die App 7 Tage, dann neu signieren; mit dem bezahlten Developer Program ein Jahr.

## Aufbau

```
Dosenjaeger/
  App/         App-Einstieg, Tabs, Navigation
  Model/       SwiftData-Modelle (Flavor, CanItem), Länder, Katalog
  Scan/        Kamera (AVFoundation), Erkennung (Vision), Ergebnis-Screen
  Views/       Sammlung, Länder, Fehlend, Sortendetail, Tauschen, Auswahl/Bearbeiten
  Components/  Farben, Schriften, Dose, Chips, Buttons
.github/workflows/build-ipa.yml   unsignierte IPA auf macOS-Runner
```

Das Xcode-Projekt nutzt synchronisierte Ordner: neue Dateien unter `Dosenjaeger/` gehören automatisch zum Target.
