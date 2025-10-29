# iOS Setup & Deployment Guide

Diese Anleitung beschreibt die Schritte zur Vorbereitung und Veröffentlichung der BBZCloud Mobile App im Apple App Store.

## 📋 Voraussetzungen

### Apple Developer Account
- **Apple Developer Program Mitgliedschaft** erforderlich (99 USD/Jahr)
- Registrierung unter: https://developer.apple.com/programs/
- Nach Registrierung ca. 24-48h Bearbeitungszeit

### Lokale Entwicklungsumgebung
- ✅ macOS mit Xcode installiert
- ✅ Flutter SDK installiert
- ✅ CocoaPods installiert (`sudo gem install cocoapods`)

## ✅ Bereits durchgeführte Anpassungen

Die folgenden iOS-spezifischen Anpassungen wurden bereits vorgenommen:

### 1. Info.plist Konfiguration ✅
Die `ios/Runner/Info.plist` wurde erweitert mit:

- **NSCameraUsageDescription** - Kamera für Datei-Uploads
- **NSPhotoLibraryUsageDescription** - Fotos für Datei-Uploads
- **NSPhotoLibraryAddUsageDescription** - Speichern von Downloads in Fotos
- **NSMicrophoneUsageDescription** - Mikrofon für BBB-Videokonferenzen
- **NSLocalNetworkUsageDescription** - Lokale Netzwerk-Zugriffe
- **NSAppTransportSecurity** - HTTP-Verbindungen erlauben (für BBZ-Dienste)
- **LSApplicationQueriesSchemes** - URL Schemes für schulcloud und untis

### 2. Projekt-Konfiguration ✅
- Bundle Identifier: `com.bbzcloud.bbzcloudMobil`
- iOS Deployment Target: iOS 13.0+
- Unterstützte Orientierungen: Portrait, Landscape (iPhone & iPad)

## 🔧 Noch erforderliche Schritte

### Schritt 1: Apple Developer Account einrichten

1. **Apple Developer Program beitreten**
   - Gehe zu https://developer.apple.com/programs/
   - Melde dich mit deiner Apple ID an
   - Zahle die jährliche Gebühr (99 USD)
   - Warte auf Bestätigung (24-48h)

2. **Team ID notieren**
   - Nach Aktivierung in Apple Developer Portal
   - Unter "Membership" findest du deine Team ID
   - Diese wird später für Code Signing benötigt

### Schritt 2: Certificates & Provisioning Profile erstellen

#### Option A: Automatisch (empfohlen für Anfänger)

1. Xcode öffnen:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Wähle das Runner-Target
   - Gehe zu "Signing & Capabilities"
   - Aktiviere "Automatically manage signing"
   - Wähle dein Team aus dem Dropdown
   - Xcode erstellt automatisch alle benötigten Certificates

#### Option B: Manuell (für fortgeschrittene Nutzer)

1. **Development Certificate erstellen**
   ```bash
   # Mit fastlane match (empfohlen)
   cd ios
   bundle install
   bundle exec fastlane match development
   ```

2. **Distribution Certificate erstellen**
   ```bash
   bundle exec fastlane match appstore
   ```

### Schritt 3: App Store Connect einrichten

1. **App registrieren**
   - Gehe zu https://appstoreconnect.apple.com
   - Klicke auf "Meine Apps" → "+" → "Neue App"
   - Wähle iOS als Plattform
   - Gib folgende Informationen ein:
     * **Name**: BBZ Cloud
     * **Primäre Sprache**: Deutsch
     * **Bundle ID**: com.bbzcloud.bbzcloudMobil
     * **SKU**: bbzcloud-mobil-001 (oder eigene ID)

2. **App-Informationen ausfüllen**
   - **Kategorie**: Bildung (Education)
   - **Unterkategorie**: Schulbildung
   - **Altersfreigabe**: 4+

3. **Privacy Policy hinzufügen**
   - URL zur Privacy Policy: (siehe `docs/privacy_policy.html`)
   - Hosting notwendig (z.B. GitHub Pages)

### Schritt 4: App Screenshots erstellen

iOS benötigt Screenshots in verschiedenen Größen:

#### Erforderliche Formate
- **6.7" Display (iPhone 14 Pro Max)**: 1290 x 2796 px
- **6.5" Display (iPhone 11 Pro Max)**: 1242 x 2688 px
- **5.5" Display (iPhone 8 Plus)**: 1242 x 2208 px

Optional für iPad:
- **12.9" iPad Pro**: 2048 x 2732 px
- **11" iPad Pro**: 1668 x 2388 px

#### Screenshots vorbereiten

1. **Mit iOS Simulator erstellen**:
   ```bash
   # Simulator starten
   flutter run -d "iPhone 15 Pro Max"
   
   # Screenshots in Simulator: Cmd + S
   # Gespeichert in: ~/Desktop/
   ```

2. **Oder mit Device Farm Tool**:
   - Fastlane's `snapshot` Tool nutzen
   - Oder manuell mit echtem iPhone erstellen

### Schritt 5: App Icon vorbereiten

Die App nutzt bereits `assets/icon.png`. Für iOS werden verschiedene Größen benötigt:

1. **Mit flutter_launcher_icons** (bereits konfiguriert):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

2. **Manuelle Anpassung** (falls nötig):
   - Icon sollte 1024x1024 px sein (ohne Transparenz)
   - Abgerundete Ecken werden automatisch von iOS hinzugefügt
   - Hochladen in App Store Connect unter "App-Informationen"

### Schritt 6: Build erstellen

#### Debug Build (für lokales Testen)
```bash
flutter build ios --debug
```

#### Release Build (für App Store)
```bash
flutter build ios --release
```

#### Archive erstellen (mit Xcode)
1. Xcode öffnen:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Wähle "Any iOS Device" als Build-Ziel
   - Menü: Product → Archive
   - Warte bis Archivierung abgeschlossen
   - Organizer öffnet sich automatisch

3. **Upload zu App Store Connect**:
   - Im Organizer: "Distribute App" klicken
   - "App Store Connect" auswählen
   - "Upload" auswählen
   - Signing-Optionen bestätigen
   - Warte auf Upload (kann 10-20 Min dauern)

### Schritt 7: TestFlight Beta-Test (empfohlen)

1. **TestFlight einrichten**
   - In App Store Connect → TestFlight
   - Build wird automatisch nach Upload verfügbar
   - Interne Tester hinzufügen (bis zu 100)

2. **Beta-Tester einladen**
   - Interne Tester: Sofort verfügbar
   - Externe Tester: Benötigt Beta-App-Review (~24h)

3. **Feedback sammeln**
   - TestFlight sammelt automatisch Crash-Reports
   - Beta-Tester können Feedback geben
   - Mehrere Test-Iterationen möglich

### Schritt 8: App Store Submission

1. **App-Details vervollständigen**
   - Screenshots hochladen (alle Größen)
   - App-Beschreibung schreiben (deutsch & englisch)
   - Keywords für SEO optimieren
   - Werbematerialien (optional)

2. **Versionsinformationen**
   - **Version**: 1.0.1 (aus pubspec.yaml)
   - **Build**: 2 (aus pubspec.yaml)
   - **Copyright**: © 2024 BBZ Rendsburg-Eckernförde
   - **Release-Notizen**: Aus CHANGELOG.md

3. **Einreichung zur Prüfung**
   - Alle Abschnitte als "Bereit" markieren
   - "Zur Prüfung einreichen" klicken
   - Review-Prozess: 1-3 Werktage

4. **Review-Status überwachen**
   - "In Prüfung" → "Bereit für Verkauf"
   - Bei Ablehnung: Feedback beachten und neu einreichen

## 🚀 Fastlane Setup (Optional, für CI/CD)

Für automatisierte Deployments kann Fastlane eingerichtet werden:

### 1. Fastlane installieren
```bash
cd ios
bundle install
bundle exec fastlane init
```

### 2. Fastfile erstellen
```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    build_app(scheme: "Runner")
    upload_to_testflight
  end

  desc "Deploy a new version to the App Store"
  lane :release do
    build_app(scheme: "Runner")
    upload_to_app_store
  end
end
```

### 3. API Key einrichten
- In App Store Connect: Users & Access → Keys
- API Key erstellen und herunterladen
- In Fastlane konfigurieren

## 🔍 Troubleshooting

### Häufige Probleme

#### Problem: "No signing identity found"
**Lösung**: 
```bash
# In Xcode: Preferences → Accounts → Download Manual Profiles
# Oder Automatic Signing aktivieren
```

#### Problem: "Provisioning profile doesn't match"
**Lösung**:
```bash
cd ios
bundle exec fastlane match nuke development
bundle exec fastlane match development --force
```

#### Problem: Build schlägt fehl mit "Pod install error"
**Lösung**:
```bash
cd ios
pod deintegrate
pod install
flutter clean
flutter pub get
```

#### Problem: "App Icon size mismatch"
**Lösung**:
```bash
# Icon neu generieren
flutter pub run flutter_launcher_icons
```

## 📱 iOS-spezifische Features

### Unterstützte Features
- ✅ WebView mit JavaScript
- ✅ File Downloads zu Documents Directory
- ✅ Auto-Login via JavaScript Injection
- ✅ Kamera & Foto-Zugriff
- ✅ Mikrofon für Videokonferenzen
- ✅ URL Schemes (Deep Linking)
- ✅ System Browser Integration

### Bekannte Einschränkungen
- ❌ Schreiben ins öffentliche Downloads-Verzeichnis (iOS verwendet app-spezifisches Documents-Verzeichnis)
- ❌ Cleartext HTTP (ATS erlaubt alle Verbindungen via NSAllowsArbitraryLoads)

## 🎯 Checkliste vor Release

- [ ] Apple Developer Account aktiv
- [ ] Bundle ID registriert
- [ ] Signing Certificates erstellt
- [ ] Provisioning Profiles generiert
- [ ] App Store Connect App erstellt
- [ ] Screenshots in allen Größen hochgeladen
- [ ] App Icon hochgeladen (1024x1024 px)
- [ ] App-Beschreibung verfasst (DE & EN)
- [ ] Privacy Policy gehostet und verlinkt
- [ ] TestFlight Beta-Test durchgeführt
- [ ] Alle App Store Guidelines überprüft
- [ ] Copyright-Informationen korrekt
- [ ] Kontakt-Informationen aktuell

## 📚 Weitere Ressourcen

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

## 🆘 Support

Bei Fragen oder Problemen:
- GitHub Issues: https://github.com/dclausen01/bbzcloud-mobil/issues
- Flutter Discord: https://discord.gg/flutter
- Stack Overflow: Tag `flutter` + `ios`

---

**Letztes Update**: Oktober 2024
**Version**: 1.0
**Autor**: BBZ Cloud Team
