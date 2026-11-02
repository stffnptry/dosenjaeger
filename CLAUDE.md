# Dosenjäger – Regeln für Claude

Lies zuerst `README.md` (Funktionen, Grenzen, Bauen) und `VERLAUF.md` (Entscheidungen und warum).
Sprache mit dem Nutzer: Deutsch, Du-Form, kurze Erklärungen, kopierbare Befehle.

## Harte Regeln

- **Design-Entwurf ist Vorgabe:** dunkelgrün `#17271D`, Neongrün `#6BD31A`, Chipgrün `#3B5E00`, schwarze Karten, kondensierte fette Überschriften (`Font.display`). Neue Screens im selben Stil (`Components/`).
- **Alles auf dem Gerät.** Erkennung mit Vision/AVFoundation, keine Cloud, keine externen SwiftPM-Pakete.
- Keine Markenlogos oder Original-Artwork einbauen; Dosen werden stilisiert gezeichnet (`CanView`).
- Katalogänderungen nur über neue `Catalog.seeds` (neuer `key`). Bestehende Sorten werden beim Start nie überschrieben, damit Nutzeränderungen bleiben.
- Commits mit `11032229+stffnptry@users.noreply.github.com`.

## Bauen und testen

- In der Cloud gibt es keinen Swift-Compiler: sorgfältig gegenlesen, pushen; der Workflow `Build IPA` auf GitHub Actions ist der Compile-Check. Fehler aus dem Log beheben.
- Swift-5-Sprachmodus, iOS 17. Nur APIs verwenden, die sicher in iOS 17 existieren.
- **README.md und VERLAUF.md aktuell halten.**
