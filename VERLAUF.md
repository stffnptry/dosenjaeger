# Verlauf

## 2026-11-02 – Erste Version

- Alle sieben Screens aus dem Entwurf umgesetzt (Sammlung, Scannen, Ergebnis, Länder, Fehlend, Sortendetail, Tauschen).
- **Xcode-Projekt von Hand** mit synchronisiertem Ordner (Format von Xcode 16), weil in der Cloud kein Xcode/XcodeGen läuft. Vorteil: Dateien müssen nicht einzeln im Projekt eingetragen werden.
- **Erkennung auf dem Gerät:** Vision-Texterkennung + Barcode im Foto + Farbton. Ein Bilderkennungsmodell für Dosen gibt es nicht frei; Namen auf der Dose sind das verlässlichste Merkmal. Barcodes werden gelernt statt vorbelegt, weil verlässliche EAN-Listen je Land fehlen.
- **Länderverfügbarkeit** als Schätzung im Katalog, editierbar; Kaufland wird beim Hinzufügen automatisch als „erhältlich“ ergänzt.
- „Anzahl“ speichert ein Exemplar mit Menge statt mehrerer Einträge, damit das Foto nicht dupliziert wird.
- **Sorten-Matrix:** grüner Punkt bedeutet „in diesem Land gekauft“ (Länderversion in der Sammlung), weißer „erhältlich“.
- Unsignierte IPA über GitHub Actions (`macos-15`, Xcode 16); Signieren per Xcode, Sideloadly oder AltStore.

## 2026-11-02 – Installationsfehler „appIdName“

- Sideloadly meldete „An invalid value 'Dosenjäger' was provided for the parameter 'appIdName'“: Apple akzeptiert beim Anlegen der App-ID mit kostenloser Apple-ID keine Umlaute.
- Info.plist-Namen jetzt ASCII („Dosenjaeger“); der deutsche Name „Dosenjäger“ kommt über `de.lproj/InfoPlist.strings` auf den Home-Bildschirm. Der Workflow prüft die Namen auf ASCII.
