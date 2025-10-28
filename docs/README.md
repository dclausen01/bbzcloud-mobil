# Dokumentation - BBZCloud Mobile

Willkommen zur Dokumentation für die Play Store-Veröffentlichung von BBZCloud Mobile!

## 📚 Dokumentations-Übersicht

Diese Dokumentation führt dich durch den gesamten Prozess der Veröffentlichung deiner App im Google Play Store und die Einrichtung automatischer Deployments via GitHub Actions.

## 🚀 Quick Start

**Neu hier?** Starte mit dem [**Release-Prozess**](RELEASE_PROCESS.md) für eine vollständige Schritt-für-Schritt-Anleitung.

## 📖 Dokumentations-Index

### 1. [Release-Prozess](RELEASE_PROCESS.md) 🎯
**Hauptdokumentation** - Vollständiger Leitfaden von der Einrichtung bis zur Veröffentlichung

**Inhalt:**
- Übersicht über den gesamten Prozess
- Phase 1: Einmalige Einrichtung (6 Schritte)
- Phase 2: Laufender Betrieb
- Release-Checklisten
- Troubleshooting
- Best Practices

**Für wen:** Alle, die die App veröffentlichen möchten

**Zeitaufwand:** 5-8 Stunden (einmalig)

---

### 2. [Keystore Setup](KEYSTORE_SETUP.md) 🔐
Anleitung zur Erstellung und Verwaltung des Signing-Keystores

**Inhalt:**
- Keystore-Erstellung
- Lokale Konfiguration
- Base64-Konvertierung für CI/CD
- Sicherheits-Best-Practices
- Verifizierung

**Für wen:** Entwickler, die den Keystore erstellen

**Zeitaufwand:** 15 Minuten

---

### 3. [Play Store Setup](PLAY_STORE_SETUP.md) 🏪
Einrichtung im Google Play Console und Service Account

**Inhalt:**
- App im Play Console erstellen
- Store Listing vorbereiten
- Service Account für CI/CD
- Erster manueller Release
- Automatische Deployments

**Für wen:** App-Publisher

**Zeitaufwand:** 2-3 Stunden

---

### 4. [GitHub Secrets](GITHUB_SECRETS.md) 🔒
Konfiguration der GitHub Secrets für automatische Deployments

**Inhalt:**
- Keystore zu Base64 konvertieren
- Service Account JSON vorbereiten
- Secrets im Repository einrichten
- Verifizierung
- Troubleshooting

**Für wen:** DevOps / Repository-Admins

**Zeitaufwand:** 20 Minuten

---

### 5. [Store Assets](STORE_ASSETS.md) 🎨
Erstellung von Screenshots, Feature Graphic und Store-Texten

**Inhalt:**
- Feature Graphic (1024x500px)
- Screenshots (mindestens 2)
- Store-Beschreibungen
- Design-Empfehlungen
- Tools und Ressourcen

**Für wen:** Designer / Marketing

**Zeitaufwand:** 2-4 Stunden

---

## 🎯 Schnellzugriff nach Rolle

### Entwickler
1. [Keystore Setup](KEYSTORE_SETUP.md) - Signing einrichten
2. [GitHub Secrets](GITHUB_SECRETS.md) - CI/CD konfigurieren
3. [Release-Prozess](RELEASE_PROCESS.md) - Gesamtübersicht

### Designer / Marketing
1. [Store Assets](STORE_ASSETS.md) - Grafiken erstellen
2. [Play Store Setup](PLAY_STORE_SETUP.md) - Store Listing

### Projekt-Manager
1. [Release-Prozess](RELEASE_PROCESS.md) - Gesamtübersicht
2. [Play Store Setup](PLAY_STORE_SETUP.md) - Veröffentlichung

## 📋 Checkliste: Vor dem ersten Release

- [ ] **Google Play Developer Account** erstellt (25 USD)
- [ ] **Keystore** erstellt und gesichert ([KEYSTORE_SETUP.md](KEYSTORE_SETUP.md))
- [ ] **Feature Graphic** erstellt (1024x500px) ([STORE_ASSETS.md](STORE_ASSETS.md))
- [ ] **Screenshots** erstellt (min. 2) ([STORE_ASSETS.md](STORE_ASSETS.md))
- [ ] **Datenschutzrichtlinie** URL vorhanden
- [ ] **App im Play Console** erstellt ([PLAY_STORE_SETUP.md](PLAY_STORE_SETUP.md))
- [ ] **Store Listing** ausgefüllt ([PLAY_STORE_SETUP.md](PLAY_STORE_SETUP.md))
- [ ] **Service Account** erstellt ([PLAY_STORE_SETUP.md](PLAY_STORE_SETUP.md))
- [ ] **GitHub Secrets** konfiguriert ([GITHUB_SECRETS.md](GITHUB_SECRETS.md))
- [ ] **Lokaler Build** erfolgreich
- [ ] **Erster Release** manuell hochgeladen

## 🔄 Workflow: Zukünftige Releases

Nach der einmaligen Einrichtung ist der Prozess automatisiert:

1. **Entwickeln** auf Feature-Branch
2. **CHANGELOG.md** aktualisieren
3. **Version** in `pubspec.yaml` erhöhen
4. **Auf main pushen**
5. **GitHub Actions** deployt automatisch
6. **Im Play Console** verifizieren

⏱️ **Dauer:** ~15 Minuten (automatisiert)

## 🛠️ Technologie-Stack

- **CI/CD:** GitHub Actions
- **Deployment:** Fastlane
- **Signing:** Android Keystore (JKS)
- **Store:** Google Play Console (Open Testing)
- **Version Control:** Git / GitHub

## 🔗 Wichtige Links

### Google
- [Play Console](https://play.google.com/console)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Play Console Help](https://support.google.com/googleplay/android-developer)

### Tools
- [Fastlane Docs](https://docs.fastlane.tools/)
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
- [GitHub Actions](https://docs.github.com/en/actions)

### Design
- [Canva](https://www.canva.com/)
- [Screenshot.rocks](https://screenshot.rocks/)
- [Material Design](https://material.io/)

## ❓ Hilfe & Support

### Dokumentation durchsuchen
```bash
# Im Projekt-Verzeichnis
grep -r "dein Suchbegriff" docs/
```

### Häufige Probleme

**Build schlägt fehl:**
- Siehe [Release-Prozess - Troubleshooting](RELEASE_PROCESS.md#troubleshooting)

**Signing-Fehler:**
- Siehe [Keystore Setup - Troubleshooting](KEYSTORE_SETUP.md#troubleshooting)

**Upload-Fehler:**
- Siehe [Play Store Setup - Troubleshooting](PLAY_STORE_SETUP.md#troubleshooting)

**Secrets-Probleme:**
- Siehe [GitHub Secrets - Troubleshooting](GITHUB_SECRETS.md#troubleshooting)

### Support-Kanäle
- **GitHub Issues** - Für Bug-Reports und Feature-Requests
- **Play Console Support** - Für Play Store spezifische Fragen
- **Flutter Community** - Für technische Flutter-Fragen

## 📝 Mitwirken

Verbesserungsvorschläge für diese Dokumentation?

1. Issue erstellen mit Label `documentation`
2. Pull Request mit Verbesserungen
3. Direktes Feedback an Maintainer

## 📄 Lizenz

Diese Dokumentation ist Teil des BBZCloud Mobile Projekts.

## 🎉 Los geht's!

**Bereit zum Starten?** 

👉 Beginne mit dem [**Release-Prozess**](RELEASE_PROCESS.md)

---

*Letzte Aktualisierung: Oktober 2025*
