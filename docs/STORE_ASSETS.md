# Play Store Assets & Screenshots

Diese Anleitung hilft dir bei der Erstellung der erforderlichen grafischen Assets für den Google Play Store.

## Übersicht

Für die Veröffentlichung im Play Store benötigst du verschiedene grafische Assets. Diese Anleitung zeigt dir, welche Assets erforderlich sind und wie du sie erstellen kannst.

## Erforderliche Assets

### 1. App-Icon (bereits vorhanden)

✅ **Status**: Bereits erstellt unter `assets/icon.png`

**Spezifikationen:**
- Größe: 512 x 512 px
- Format: 32-bit PNG
- Maximale Dateigröße: 1024 KB
- Transparenz erlaubt

**Verwendung:**
- Wird als App-Symbol im Play Store angezeigt
- Wird auf Geräten als App-Icon verwendet

### 2. Feature Graphic (ERFORDERLICH)

⚠️ **Status**: Muss noch erstellt werden

**Spezifikationen:**
- Größe: 1024 x 500 px
- Format: JPEG oder 24-bit PNG
- Maximale Dateigröße: 1024 KB
- Keine Transparenz

**Design-Empfehlungen:**
- App-Logo prominent platzieren
- Slogan oder Tagline hinzufügen
- Farbschema der App verwenden
- Nicht zu viel Text (wird auf kleinen Bildschirmen unleserlich)
- Kein Gerät-Screenshot (wird automatisch eingefügt)

**Empfohlener Inhalt:**
```
┌─────────────────────────────────────────────────┐
│                                                 │
│         [App Logo]                              │
│                                                 │
│   BBZCloud Mobile                               │
│   Dein zentraler Zugriff auf BBZCloud-Dienste  │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Tools zum Erstellen:**
- [Canva](https://www.canva.com/) - Kostenlos mit Templates
- [Figma](https://www.figma.com/) - Professionelles Design-Tool
- GIMP - Open Source Bildbearbeitung
- Adobe Photoshop

### 3. Screenshots (ERFORDERLICH)

⚠️ **Status**: Müssen noch erstellt werden

**Mindestanforderung:**
- **Minimum**: 2 Screenshots
- **Empfohlen**: 4-8 Screenshots
- **Maximum**: 8 Screenshots

**Spezifikationen:**
- Format: JPEG oder 24-bit PNG
- Minimale Dimension: 320 px
- Maximale Dimension: 3840 px
- Format: 16:9 oder 9:16 (Portrait empfohlen für mobile Apps)
- Maximale Dateigröße: 8 MB pro Screenshot

**Empfohlene Screenshots:**

#### Screenshot 1: Home Screen
**Inhalt:** App-Liste mit allen verfügbaren Diensten
**Zweck:** Zeigt die Hauptfunktionalität der App

#### Screenshot 2: WebView (z.B. Moodle)
**Inhalt:** Beispiel einer geöffneten BBZCloud-App
**Zweck:** Demonstriert die WebView-Funktionalität

#### Screenshot 3: Todo-Liste
**Inhalt:** Todo-Listen-Feature mit einigen Beispiel-Todos
**Zweck:** Zeigt zusätzliche Produktivitäts-Features

#### Screenshot 4: Custom Apps / Settings
**Inhalt:** Custom App-Dialog oder Settings-Screen
**Zweck:** Zeigt Anpassungsmöglichkeiten

**Optional:**

#### Screenshot 5: Multi-Tab-Navigation
**Inhalt:** App Switcher Overlay
**Zweck:** Zeigt fortgeschrittene Navigation

#### Screenshot 6: Dark Mode
**Inhalt:** App im Dark Mode
**Zweck:** Zeigt Theme-Support

### 4. Promo Video (OPTIONAL)

**Spezifikationen:**
- Länge: Maximal 30 Sekunden
- Format: MP4 oder MOV
- Maximale Dateigröße: 100 MB
- YouTube-Link erforderlich

**Inhalt-Empfehlung:**
1. (0-5s) App-Logo & Name
2. (5-15s) Hauptfunktionen demonstrieren
3. (15-25s) Besondere Features hervorheben
4. (25-30s) Call-to-Action

## Screenshots erstellen

### Methode 1: Direkt vom Gerät (Empfohlen)

#### Android Emulator verwenden:

1. **Emulator starten:**
   ```bash
   flutter emulators --launch Pixel_7_Pro_API_34
   ```

2. **App ausführen:**
   ```bash
   flutter run
   ```

3. **Screenshots erstellen:**
   - Im Emulator: Klicke auf das Kamera-Symbol
   - Oder: Android Studio → Camera Button
   - Speicherort: Emulator Screenshot-Verzeichnis

4. **Screenshots übertragen:**
   ```bash
   # Screenshots befinden sich normalerweise hier
   ~/Pictures/Screenshots/
   ```

#### Physisches Gerät verwenden:

1. **Debug-Build installieren:**
   ```bash
   flutter install
   ```

2. **Screenshots erstellen:**
   - Android: Power + Volume Down
   - Screenshots werden im Gallery gespeichert

3. **Screenshots übertragen:**
   - Per USB verbinden
   - Dateien vom Gerät kopieren

### Methode 2: Fastlane Screengrab (Automatisiert)

```bash
# Installation
cd android
bundle exec fastlane supply init

# Screenshots automatisch erstellen
bundle exec fastlane screenshots
```

### Screenshot-Bearbeitung

**Empfohlene Bearbeitungen:**
- ✅ Statusleiste bereinigen (Zeit, Batterie, etc.)
- ✅ Placeholder-Daten verwenden (keine echten persönlichen Daten)
- ✅ Gute Beleuchtung (gut lesbar)
- ✅ Einheitlicher Style (alle Screenshots im gleichen Theme)
- ❌ Keine übertriebenen Effekte
- ❌ Keine irreführenden Darstellungen

**Tools:**
- [Screenshot.rocks](https://screenshot.rocks/) - Device Frames hinzufügen
- [Mockup.photos](https://mockup.photos/) - Mockups erstellen
- GIMP - Kostenlose Bildbearbeitung
- [Figma](https://www.figma.com/) - Device Frames

## Store Listing Text

### Kurzbeschreibung (max. 80 Zeichen)

**Empfehlung:**
```
Mobile App für den Zugriff auf BBZCloud-Dienste
```

**Alternativen:**
```
BBZCloud-Dienste in einer App - Moodle, Teams & mehr
Dein zentraler Zugriff auf BBZCloud - Alles in einer App
BBZCloud Mobile - Einfacher Zugriff auf alle Dienste
```

### Vollständige Beschreibung (max. 4000 Zeichen)

Siehe `docs/PLAY_STORE_SETUP.md` für die vollständige Beschreibung.

## Asset-Checkliste

Vor dem Upload:

### App-Icon
- [x] 512 x 512 px
- [x] PNG-Format
- [x] Bereits vorhanden: `assets/icon.png`

### Feature Graphic
- [ ] 1024 x 500 px
- [ ] JPEG oder PNG
- [ ] Design erstellt
- [ ] Keine Transparenz

### Screenshots
- [ ] Minimum 2 Screenshots
- [ ] Portrait-Format (9:16)
- [ ] Statusleiste bereinigt
- [ ] Keine persönlichen Daten
- [ ] Einheitlicher Style

### Texte
- [ ] Kurzbeschreibung (max. 80 Zeichen)
- [ ] Vollständige Beschreibung (max. 4000 Zeichen)
- [ ] Kategorien ausgewählt
- [ ] Kontakt-E-Mail

### Optional
- [ ] Promo-Video erstellt
- [ ] Tablet-Screenshots
- [ ] Verschiedene Sprachen

## Dateiorganisation

Empfohlene Struktur:
```
store-assets/
├── icon/
│   └── icon-512.png (bereits vorhanden: assets/icon.png)
├── feature-graphic/
│   └── feature-graphic-1024x500.png
├── screenshots/
│   ├── phone/
│   │   ├── 01-home-screen.png
│   │   ├── 02-webview-moodle.png
│   │   ├── 03-todo-list.png
│   │   └── 04-custom-apps.png
│   └── tablet/ (optional)
│       ├── 01-tablet-home.png
│       └── 02-tablet-landscape.png
└── promo-video/ (optional)
    └── promo.mp4
```

## Tools & Ressourcen

### Design Tools
- [Canva](https://www.canva.com/) - Templates & einfaches Design
- [Figma](https://www.figma.com/) - Professionelles UI-Design
- [Adobe Express](https://www.adobe.com/express/) - Schnelle Grafik-Erstellung

### Screenshot Tools
- [Screenshot.rocks](https://screenshot.rocks/) - Device Frames
- [Appure](https://appure.io/) - App Store Screenshot Generator
- [Previewed](https://previewed.app/) - Mockup Generator

### Farb-Tools
- [Coolors](https://coolors.co/) - Farbpaletten-Generator
- [Adobe Color](https://color.adobe.com/) - Farbharmonie-Tool

### Bild-Optimierung
- [TinyPNG](https://tinypng.com/) - PNG-Komprimierung
- [Squoosh](https://squoosh.app/) - Bild-Optimierung

## Best Practices

### Feature Graphic
✅ **Do:**
- Verwende hohe Auflösung
- Halte es einfach und klar
- Nutze Markenfarben
- Teste verschiedene Designs
- Betrachte auf verschiedenen Bildschirmgrößen

❌ **Don't:**
- Zu viel Text
- Geringe Qualität
- Irreführende Darstellung
- Urheberrechtlich geschütztes Material

### Screenshots
✅ **Do:**
- Zeige echte App-Features
- Verwende saubere, professionelle Beispieldaten
- Halte es konsistent
- Zeige die besten Features zuerst
- Nutze hochwertige Bilder

❌ **Don't:**
- Fake Features zeigen
- Persönliche/sensible Daten
- Unscharfe oder pixelige Bilder
- Inkonsistenter Style
- Zu viele Screenshots

## Nächste Schritte

1. **Feature Graphic erstellen**
   - Design in Canva oder Figma
   - Export als PNG (1024x500)
   - In `store-assets/feature-graphic/` speichern

2. **Screenshots erstellen**
   - Emulator oder physisches Gerät
   - Mindestens 4 Screenshots
   - Bearbeiten und optimieren
   - In `store-assets/screenshots/phone/` speichern

3. **Assets hochladen**
   - Siehe `docs/PLAY_STORE_SETUP.md`
   - Im Play Console unter "Store-Präsenz"

4. **Review anfordern**
   - Alle Assets hochgeladen
   - Texte ausgefüllt
   - App zur Überprüfung einreichen

## Feedback & Iteration

Nach dem ersten Upload:
- Analysiere Conversion-Raten
- A/B-Teste verschiedene Screenshots
- Optimiere basierend auf Nutzer-Feedback
- Aktualisiere Assets bei großen Updates
