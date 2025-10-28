# Google Play Store Setup

Diese Anleitung erklärt, wie du die App im Google Play Store veröffentlichst und den Service Account für automatische Deployments einrichtest.

## Voraussetzungen

- ✅ Google Play Developer Account (bereits eingerichtet)
- ✅ Keystore erstellt (siehe KEYSTORE_SETUP.md)
- ✅ App-Metadaten vorbereitet (siehe STORE_ASSETS.md)

## Teil 1: App im Play Console erstellen

### 1.1 Neue App anlegen

1. Gehe zu [Google Play Console](https://play.google.com/console)
2. Klicke auf "App erstellen"
3. Fülle folgende Informationen aus:
   - **App-Name**: BBZCloud Mobile
   - **Standardsprache**: Deutsch (Deutschland)
   - **App oder Spiel**: App
   - **Kostenlos oder kostenpflichtig**: Kostenlos

4. Akzeptiere die Entwicklervereinbarungen
5. Klicke auf "App erstellen"

### 1.2 App-Kategorie & Kontaktdaten

Navigation: **Wachstum → Store-Präsenz → App-Details**

- **Kategorie**: Produktivität (oder Business)
- **E-Mail-Adresse**: Deine Support-E-Mail
- **Telefonnummer**: Optional
- **Website**: Optional (z.B. https://github.com/dclausen01/bbzcloud-mobil)

### 1.3 Datenschutzrichtlinie

Navigation: **Wachstum → Store-Präsenz → App-Details**

⚠️ **ERFORDERLICH**: Du musst eine URL zu deiner Datenschutzrichtlinie angeben.

Optionen:
1. **Eigene Website**: Hoste die Datenschutzrichtlinie auf deiner Website
2. **GitHub Pages**: Erstelle eine Seite in deinem Repository
3. **Freie Hosting-Dienste**: z.B. Google Sites, WordPress.com

**Mindestinhalt der Datenschutzrichtlinie:**
- Welche Daten werden gesammelt?
- Wie werden die Daten verwendet?
- Wie werden die Daten geschützt?
- Kontaktinformationen

### 1.4 Store-Eintrag vorbereiten

Navigation: **Wachstum → Store-Präsenz → Hauptdetails zum Store-Eintrag**

#### App-Name & Beschreibungen

**Kurzbeschreibung** (max. 80 Zeichen):
```
Mobile App für den Zugriff auf BBZCloud-Dienste
```

**Vollständige Beschreibung** (max. 4000 Zeichen):
```
BBZCloud Mobile - Dein zentraler Zugriff auf BBZCloud-Dienste

Die BBZCloud Mobile App bietet dir einen einfachen und schnellen Zugriff auf alle wichtigen BBZCloud-Dienste direkt auf deinem Smartphone.

✨ Features:

📚 Integrierte Dienste:
• Moodle - Lernplattform
• Outlook - E-Mail & Kalender
• OneDrive - Cloud-Speicher
• SharePoint - Dokumentenverwaltung
• Teams - Zusammenarbeit
• OneNote - Notizen

📋 Todo-Liste:
• Erstelle und verwalte deine Aufgaben
• Lokale Speicherung - keine Cloud erforderlich
• Einfache und übersichtliche Bedienung

🔐 Sicher & Privat:
• Sichere Speicherung deiner Anmeldedaten
• Keine Weitergabe an Dritte
• Lokale Datenspeicherung

🎨 Benutzerfreundlich:
• Intuitive Bedienung
• Dark Mode Support
• Multi-Tab-Navigation
• Schneller App-Wechsel per Floating Button

⚡ Weitere Features:
• Custom App-Integration
• Download-Funktionalität
• Offline-Unterstützung für Todos
• Regelmäßige Updates

Die App wurde speziell für BBZCloud-Nutzer entwickelt und bietet optimierten Zugriff auf alle wichtigen Dienste in einer einzigen Anwendung.

Support: [Deine E-Mail]
```

#### Grafische Assets

**App-Symbol** (512 x 512 px):
- Upload: `assets/icon.png`

**Feature-Grafik** (1024 x 500 px):
- Erstelle eine ansprechende Grafik mit:
  - App-Logo
  - Slogan
  - Farbschema der App

**Screenshots** (mindestens 2, empfohlen 4-8):
- Telefon: 16:9 oder 9:16 Format
- Zeige wichtige Features:
  1. Home-Screen mit App-Liste
  2. WebView-Navigation (z.B. Moodle)
  3. Todo-Liste
  4. Settings/Custom Apps

**Optionale Assets:**
- Promo-Video (max. 30 Sekunden)
- Tablet-Screenshots
- TV-Screenshots

### 1.5 Inhaltsklassifizierung

Navigation: **Richtlinien → App-Inhalte → Inhaltsklassifizierung**

1. Klicke auf "Fragebogen starten"
2. Beantworte die Fragen wahrheitsgemäß
3. Übliche Antworten für diese App:
   - Keine Gewalt
   - Keine sexuellen Inhalte
   - Keine Drogenreferenzen
   - Keine Hassrede
4. Sende den Fragebogen ab

### 1.6 Zielgruppe

Navigation: **Richtlinien → App-Inhalte → Zielgruppe**

- **Zielgruppenalter**: 13+ oder 18+
- **Hauptzielgruppe**: Erwachsene/Studenten
- **Werbe-ID wird verwendet**: Nein (falls keine Werbung)

### 1.7 Datensicherheit

Navigation: **Richtlinien → App-Inhalte → Datensicherheit**

Beantworte den Fragebogen:

1. **Erfasst oder teilt die App Nutzerdaten?**
   - Ja (Anmeldedaten werden lokal gespeichert)

2. **Welche Daten werden erfasst?**
   - Anmeldeinformationen (lokal gespeichert)
   - App-Aktivität (lokal gespeichert)

3. **Wie werden die Daten verwendet?**
   - App-Funktionalität
   - Authentifizierung

4. **Werden Daten verschlüsselt?**
   - Ja (flutter_secure_storage)

5. **Können Nutzer Datenlöschung anfordern?**
   - Ja (Daten werden lokal gespeichert und können gelöscht werden)

## Teil 2: Service Account für automatische Deployments

### 2.1 Google Cloud Project erstellen

1. Gehe zu [Google Cloud Console](https://console.cloud.google.com/)
2. Klicke auf "Projekt auswählen" → "Neues Projekt"
3. **Projektname**: bbzcloud-mobile-ci
4. Klicke auf "Erstellen"

### 2.2 Google Play Android Developer API aktivieren

1. Im Cloud Project: Navigation → "APIs & Dienste" → "Bibliothek"
2. Suche nach "Google Play Android Developer API"
3. Klicke auf die API
4. Klicke auf "Aktivieren"

### 2.3 Service Account erstellen

1. Navigation → "IAM & Verwaltung" → "Dienstkonten"
2. Klicke auf "Dienstkonto erstellen"
3. **Dienstkontoname**: play-store-deploy
4. **Beschreibung**: Service Account für automatische Play Store Deployments
5. Klicke auf "Erstellen und fortfahren"
6. Rolle: **Keine Rolle** (wird im Play Console zugewiesen)
7. Klicke auf "Fertig"

### 2.4 JSON-Key erstellen

1. Finde das neu erstellte Dienstkonto in der Liste
2. Klicke auf das Dienstkonto
3. Tab "Schlüssel" → "Schlüssel hinzufügen" → "Neuen Schlüssel erstellen"
4. **Schlüsseltyp**: JSON
5. Klicke auf "Erstellen"
6. Die JSON-Datei wird heruntergeladen - **SICHERE DIESE DATEI!**

### 2.5 Service Account in Play Console verbinden

1. Zurück zu [Google Play Console](https://play.google.com/console)
2. Navigation: **Setup → API-Zugriff**
3. Scrolle zu "Dienstkonten"
4. Klicke auf "Dienstkonten erstellen und verwalten"
5. Du wirst zur Cloud Console weitergeleitet
6. Zurück zur Play Console
7. Klicke auf "Zugriff erteilen" beim neu erstellten Service Account

### 2.6 Berechtigungen zuweisen

1. Im Dialog "Kontoberechtigungen":
2. Tab "App-Berechtigungen"
3. Wähle deine App: "BBZCloud Mobile"
4. Setze folgende Berechtigungen:
   - ✅ **Releases erstellen und bearbeiten**
   - ✅ **Versionen in Tracks verwalten**
   - Alternativ: **Release-Manager** (empfohlen)
5. Klicke auf "Einladen"
6. Bestätige die Einladung

## Teil 3: Erster Release

### 3.1 Keystore lokal einrichten

Folge der Anleitung in `docs/KEYSTORE_SETUP.md`:
1. Keystore erstellen
2. `android/key.properties` konfigurieren
3. Lokalen Build testen

### 3.2 Signierte AAB erstellen

```bash
cd ~/Projekte/bbzcloud-mobil
flutter build appbundle --release
```

Die AAB-Datei findest du unter:
```
build/app/outputs/bundle/release/app-release.aab
```

### 3.3 Manuell im Play Console hochladen

⚠️ **Der erste Release MUSS manuell hochgeladen werden!**

1. Gehe zu Play Console → **Release → Testing → Open Testing**
2. Klicke auf "Release erstellen"
3. Klicke auf "App-Bundle hochladen"
4. Wähle die `app-release.aab` Datei
5. **Release-Name**: Version 1.0.0
6. **Versionshinweise** (kopiere aus CHANGELOG.md):
   ```
   Erste öffentliche Release-Version
   
   Features:
   - WebView-basierte Navigation für BBZCloud-Dienste
   - Integrierte Apps: Moodle, Outlook, OneDrive, SharePoint, Teams, OneNote
   - Todo-Liste mit lokaler Speicherung
   - Custom App-Integration
   - Dark/Light Mode Support
   ```
7. Klicke auf "Überprüfen"
8. Prüfe alle Informationen
9. Klicke auf "Release starten"

### 3.4 Überprüfung durch Google

- **Dauer**: Normalerweise wenige Stunden bis 2 Tage
- **Erste Überprüfung**: Kann länger dauern
- **Status prüfen**: Play Console → Dashboard
- **Benachrichtigung**: Per E-Mail

## Teil 4: GitHub Secrets einrichten

Siehe `docs/GITHUB_SECRETS.md` für detaillierte Anleitung.

Erforderliche Secrets:
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `PLAY_STORE_CONFIG_JSON`

## Teil 5: Automatische Deployments

Nach erfolgreichem ersten Release:

### 5.1 Workflow testen

1. Stelle sicher, dass alle GitHub Secrets konfiguriert sind
2. Erhöhe die Version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2
   ```
3. Aktualisiere `CHANGELOG.md` mit den Änderungen
4. Commit und Push auf `main`:
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "chore: bump version to 1.0.1"
   git push origin main
   ```
5. GitHub Actions führt automatisch Build und Deployment durch

### 5.2 Release-Prozess überwachen

1. GitHub Repository → Actions
2. Wähle den laufenden Workflow
3. Prüfe die Logs bei Fehlern
4. Nach erfolgreichem Deployment:
   - GitHub Release wird erstellt
   - App ist im Open Testing Track verfügbar

## Release Tracks

### Open Testing (Aktuell konfiguriert)
- ✅ Öffentlich über Link verfügbar
- ✅ Keine Begrenzung der Tester
- ✅ Automatische Updates
- ⚠️ Link muss geteilt werden

### Closed Testing (Alpha/Beta)
- Nur für eingeladene Tester
- E-Mail-basierte Einladungen
- Feedback-System

### Internal Testing
- Nur für Team-Mitglieder
- Schnelle Veröffentlichung
- Ideal für QA

### Production
- Öffentlich im Play Store
- Gestaffelte Veröffentlichung möglich
- Vollständige Store-Präsenz

## Troubleshooting

### Fehler: "Package name already exists"
- Die Package-ID ist bereits verwendet
- Ändere die Package-ID in `android/app/build.gradle.kts`

### Fehler: "Upload failed: Authentication failed"
- Prüfe Service Account Berechtigungen
- Stelle sicher, dass die JSON-Datei gültig ist
- Prüfe ob API aktiviert ist

### Fehler: "APK/AAB signature mismatch"
- Der Keystore stimmt nicht überein
- Verwende den gleichen Keystore für alle Releases

### Release bleibt in "Draft"
- Prüfe ob alle erforderlichen Informationen ausgefüllt sind
- Prüfe Inhaltsklassifizierung
- Prüfe Datensicherheitsformular

## Nächste Schritte

Nach erfolgreichem Setup:
1. ✅ Tester zum Open Testing Track einladen
2. ✅ Feedback sammeln
3. ✅ Bei Bedarf zu Closed Testing wechseln
4. ✅ Später: Production Release planen

## Wichtige Links

- [Google Play Console](https://play.google.com/console)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Play Console Help](https://support.google.com/googleplay/android-developer)
- [Fastlane Documentation](https://docs.fastlane.tools/)
