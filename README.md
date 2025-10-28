# BBZCloud Mobile

Eine moderne Flutter-App für den Zugriff auf alle digitalen Dienste des BBZ Rendsburg-Eckernförde.

## 📱 Features

### ✅ Implementiert

- **Onboarding & Setup**
  - Welcome Screen für neuen Benutzer
  - Email & Rollen-Auswahl (Schüler/Lehrkraft)
  - Optional: Passwort-Speicherung für Auto-Login
  - Auto-Erkennung der Rolle anhand der Email-Domain

- **App-Verwaltung**
  - 10 vorkonfigurierte BBZ-Apps
  - Rollenbasierte Filterung (verschiedene Apps für Schüler/Lehrkräfte)
  - Farbige App-Karten mit Gradient-Design
  - 2-spaltiges App-Grid für optimale Übersicht

- **WebView Integration**
  - Vollständiger InAppWebView mit Navigation
  - JavaScript Auto-Login (automatische Anmeldung)
  - Back/Forward/Refresh Navigation
  - Progress Bar für Ladefortschritt
  - Download Handler

- **Navigation**
  - Navigation Drawer mit App-Liste
  - Settings Screen
  - User Profile Display
  - Intuitive Navigation zwischen Screens

- **Settings & Personalisierung**
  - Theme-Auswahl (Hell/Dunkel/System)
  - Sofortige Theme-Anwendung
  - Account-Verwaltung
  - App-Reset Funktion
  - About-Informationen

- **Sicherheit & Datenschutz**
  - Verschlüsselte Passwort-Speicherung (flutter_secure_storage)
  - SQLite Datenbank für lokale Daten
  - Keine Cloud-Synchronisation
  - Alle Daten bleiben auf dem Gerät

## 🏗️ Architektur

### Clean Architecture mit MVVM

```
lib/
├── core/
│   ├── constants/     # App-Konfiguration, Strings, Apps
│   └── theme/         # Material Design 3 Theme
├── data/
│   ├── models/        # User, Credentials, CustomApp
│   └── services/      # Database, Credentials
├── presentation/
│   ├── providers/     # Riverpod State Management
│   ├── screens/       # UI Screens
│   └── widgets/       # Reusable Widgets
└── main.dart
```

### Tech Stack

- **Framework**: Flutter 3.35.6
- **Language**: Dart 3.x
- **State Management**: Riverpod
- **Database**: SQLite (sqflite)
- **Secure Storage**: flutter_secure_storage
- **WebView**: flutter_inappwebview
- **UI**: Material Design 3

## 🚀 Getting Started

### Voraussetzungen

- Flutter SDK 3.35.6 oder höher
- Android Studio / VS Code
- Android SDK (für Android-Builds)
- Xcode (für iOS-Builds, nur macOS)

### Installation

1. Repository klonen:
```bash
git clone https://github.com/dclausen01/bbzcloud-mobil.git
cd bbzcloud-mobil
```

2. Dependencies installieren:
```bash
flutter pub get
```

3. App starten:
```bash
# Android
flutter run

# iOS (nur macOS)
flutter run -d ios

# Web
flutter run -d chrome
```

## 🔨 Build

### Android APK

```bash
flutter build apk --release
```

Die APK befindet sich dann in: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (für Google Play)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 📋 Verfügbare Apps

Die App bietet Zugriff auf folgende BBZ-Dienste:

1. **IServ** - Schulplattform
2. **Moodle** - Lernplattform
3. **Untis** - Stundenplan
4. **BigBlueButton** - Videokonferenzen
5. **Nextcloud** - Cloud-Speicher
6. **OpenOlat** - E-Learning
7. **WebMail** - E-Mail
8. **Mahara** - E-Portfolio
9. **Wiki** - Wissensdatenbank
10. **HPI Schul-Cloud** - Cloud-Plattform

*Hinweis: Einige Apps sind nur für Lehrkräfte sichtbar.*

## 🔐 Auto-Login

Die App unterstützt automatisches Einloggen in Apps:

1. Bei der Ersteinrichtung Email und Passwort eingeben
2. Passwort wird verschlüsselt gespeichert
3. Beim Öffnen einer App werden die Credentials automatisch eingefüllt
4. Funktioniert mit allen Standard-Login-Formularen

## 🎨 Theming

Die App unterstützt drei Theme-Modi:

- **Hell**: Helles Design
- **Dunkel**: Dunkles Design
- **System**: Folgt den Systemeinstellungen

Theme kann jederzeit in den Einstellungen geändert werden.

## 📱 Unterstützte Plattformen

- ✅ Android
- ✅ iOS
- ✅ Web (experimentell)
- ✅ macOS (experimentell)
- ✅ Linux (experimentell)
- ✅ Windows (experimentell)

## 🤝 Contributing

Contributions sind willkommen! Bitte erstelle einen Pull Request oder öffne ein Issue.

### Development Setup

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

## 📄 License

Dieses Projekt ist unter der MIT License lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 👥 Team

- **Development**: BBZ Cloud Team
- **Design**: Material Design 3
- **Institution**: BBZ Rendsburg-Eckernförde

## 📞 Support

Bei Fragen oder Problemen:
- Issue erstellen auf GitHub
- Email: support@bbz-rd-eck.de
- Website: https://www.bbz-rd-eck.de

## 🗺️ Roadmap

### Geplante Features

- [ ] Custom Apps Management (Hinzufügen/Bearbeiten eigener Apps)
- [ ] Favoriten-System
- [ ] App-Suche
- [ ] Browser-Verlauf
- [ ] Download Manager
- [ ] Push-Benachrichtigungen
- [ ] Offline-Modus
- [ ] App-Reihenfolge anpassen
- [ ] Mehrsprachigkeit (DE/EN)

## 🏪 Play Store Veröffentlichung

Die App kann im Google Play Store veröffentlicht werden. Eine ausführliche Dokumentation findest du im [docs/](docs/) Verzeichnis.

### Schnellstart

📖 **[Vollständige Dokumentation](docs/README.md)** - Kompletter Leitfaden zur Veröffentlichung

### Wichtige Dokumente

- **[Release-Prozess](docs/RELEASE_PROCESS.md)** - Hauptdokumentation für die Veröffentlichung
- **[Keystore Setup](docs/KEYSTORE_SETUP.md)** - App-Signierung einrichten
- **[Play Store Setup](docs/PLAY_STORE_SETUP.md)** - Google Play Console konfigurieren
- **[GitHub Secrets](docs/GITHUB_SECRETS.md)** - CI/CD für automatische Deployments
- **[Store Assets](docs/STORE_ASSETS.md)** - Screenshots und Grafiken erstellen

### Automatische Deployments

Nach der einmaligen Einrichtung erfolgen Updates automatisch:

1. Version in `pubspec.yaml` erhöhen
2. `CHANGELOG.md` aktualisieren
3. Auf `main` Branch pushen
4. GitHub Actions deployt automatisch in den Play Store (Open Testing)

## 📊 Status

![Build Status](https://github.com/dclausen01/bbzcloud-mobil/workflows/Build/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.35.6-blue.svg)
![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green.svg)

---

Made with ❤️ by BBZ Rendsburg-Eckernförde

