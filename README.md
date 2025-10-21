# BBZCloud Mobile (Flutter)

Eine moderne mobile App für die BBZ Cloud - entwickelt mit Flutter für iOS und Android.

## 📱 Über das Projekt

BBZCloud Mobile ist eine Flutter-Neuimplementierung der bestehenden Ionic/Capacitor-App mit folgenden Verbesserungen:

- **Native Performance** - Keine WebView-Abhängigkeiten für die UI
- **Verbessertes Download-Management** - Native Download-Handler ohne JavaScript-Hacks
- **Perfektes Keyboard-Handling** - Out-of-the-box Android/iOS Keyboard-Support
- **Modernes Design** - Material Design 3 mit Custom Theme
- **WebView-Integration** - Für embedded Web-Apps mit Auto-Login

## 🎯 Features

### Core Features
- ✅ App-Portal für BBZ Cloud Dienste
- ✅ WebView-Integration mit JavaScript-Injection
- ✅ Zentrale Credential-Verwaltung
- ✅ Auto-Login in Web-Apps
- ✅ Native Download-Handler mit Progress
- ✅ Todo-System
- ✅ Custom Apps Management
- ✅ Theme-Support (Light/Dark)
- ✅ Benutzerrollen (Lehrer/Schüler)

### UI/UX
- Seitliches Drawer-Panel mit allen Apps
- Floating Action Button (immer sichtbar)
- Farbige App-Kacheln
- Smooth Animations
- Material Design 3

## 🏗️ Architektur

```
lib/
├── core/               # Konstanten, Theme, Utils
├── data/              # Models, Repositories, Services
├── presentation/      # Providers, Screens, Widgets
└── routes/            # App-Routing
```

### Technologie-Stack
- **Framework:** Flutter 3.35.6+ (Dart 3+)
- **State Management:** Riverpod
- **WebView:** flutter_inappwebview
- **Datenbank:** sqflite (SQLite)
- **Credentials:** flutter_secure_storage
- **UI:** Material Design 3

## 🚀 Getting Started

### Voraussetzungen
- Flutter SDK 3.35.6 oder höher
- Android Studio (für Android-Entwicklung)
- Xcode (für iOS-Entwicklung, nur auf macOS)

### Installation

```bash
# Repository klonen
git clone https://github.com/dclausen01/bbzcloud-mobil.git
cd bbzcloud-mobil

# Dependencies installieren
flutter pub get

# App starten (Android)
flutter run
```

### Entwicklung

```bash
# Flutter Doctor ausführen
flutter doctor

# Android Emulator starten
flutter emulators --launch <emulator_id>

# Hot Reload während Entwicklung
# Drücke 'r' im Terminal für Hot Reload
# Drücke 'R' für Hot Restart
```

## 📦 Packages

Hauptabhängigkeiten:
- `flutter_riverpod` - State Management
- `flutter_inappwebview` - WebView mit JavaScript-Injection
- `sqflite` - SQLite Datenbank
- `flutter_secure_storage` - Sichere Credential-Speicherung
- `path_provider` - Dateisystem-Zugriff

## 🔄 Migration von Ionic/Capacitor

Diese App ersetzt die bestehende Ionic/Capacitor-App mit folgenden Vorteilen:

| Feature | Ionic/Capacitor | Flutter |
|---------|----------------|---------|
| Keyboard-Handling | Problematisch, erfordert Plugins | Native, funktioniert out-of-the-box |
| Download-Management | JavaScript-Hacks + Native Listener | Native Events, zuverlässig |
| Performance | WebView-basiert | Native Rendering |
| UI-Konsistenz | Manchmal inkonsistent | Material Design 3 |
| Code-Wartung | TypeScript + Plugins | Dart, typsicher |

## 🎨 Design-System

### Farben
- **Primary:** Deep Blue (#1976D2)
- **Secondary:** Teal (#00897B)
- **Surface:** Dynamic (basierend auf Theme)

### App-Buttons
Jede App hat ihre eigene Farbe im Drawer-Panel (ähnlich zur Desktop-App).

## 📝 Entwicklungs-Roadmap

### Phase 1: Foundation ✅
- [x] Flutter-Projekt Setup
- [x] Git-Repository eingerichtet
- [ ] Basis-Architektur
- [ ] Theme & Design System
- [ ] Navigation

### Phase 2: Core Features (Woche 3-4)
- [ ] User Management
- [ ] App Configuration
- [ ] Custom Drawer
- [ ] Floating Action Button

### Phase 3: WebView Integration (Woche 5-6)
- [ ] InAppWebView Setup
- [ ] JavaScript Injection
- [ ] Auto-Login Mechanismus

### Phase 4: Downloads & Advanced (Woche 7-8)
- [ ] Native Download Handler
- [ ] Progress Tracking
- [ ] File Management

### Phase 5: Additional Features (Woche 9-10)
- [ ] Todo-System
- [ ] Custom Apps Management
- [ ] Settings Panel

### Phase 6: Polish & Testing (Woche 11-12)
- [ ] Animations
- [ ] Error Handling
- [ ] Performance
- [ ] Testing

## 🤝 Contributing

Dieses Projekt wird aktiv entwickelt. Feedback und Verbesserungsvorschläge sind willkommen!

## 📄 Lizenz

[Lizenz hier einfügen]

## 👤 Autor

Dennis Clausen - [GitHub](https://github.com/dclausen01)

## 🔗 Verwandte Projekte

- [BBZCloud Mobile (Ionic)](https://github.com/dclausen01/bbzcloud-mobile) - Original Ionic/Capacitor Version
- [BBZCloud Desktop](https://github.com/dclausen01/bbzcloud-2) - Electron Desktop-App

---

**Status:** 🚧 In aktiver Entwicklung

**Version:** 0.1.0 (Alpha)
