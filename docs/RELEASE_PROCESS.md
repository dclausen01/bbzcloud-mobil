# Release-Prozess

Vollständige Anleitung für die Veröffentlichung der BBZCloud Mobile App im Google Play Store.

## Übersicht

Dieser Leitfaden führt dich durch den gesamten Prozess von der Vorbereitung bis zur automatisierten Veröffentlichung im Play Store.

## Voraussetzungen

✅ Bereits erledigt:
- [x] Google Play Developer Account
- [x] GitHub Repository

📋 Noch zu erledigen:
- [ ] Keystore erstellen
- [ ] Store Assets vorbereiten
- [ ] Service Account einrichten
- [ ] GitHub Secrets konfigurieren

## Phase 1: Einmalige Einrichtung

### Schritt 1: Keystore & Signing

**Dokumentation:** `docs/KEYSTORE_SETUP.md`

**Aufgaben:**
1. Keystore erstellen
2. `android/key.properties` konfigurieren
3. Lokalen Build testen
4. Keystore sicher aufbewahren

**Geschätzte Zeit:** 15 Minuten

**Befehle:**
```bash
# Keystore erstellen
keytool -genkey -v -keystore ~/bbzcloud-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload -storetype JKS

# Keystore verschieben
mv ~/bbzcloud-upload-keystore.jks ~/Projekte/bbzcloud-mobil/android/

# key.properties erstellen
cp android/key.properties.template android/key.properties
# Dann bearbeite key.properties und füge deine Passwörter ein

# Lokalen Build testen
flutter build appbundle --release
```

**Erfolgskriterium:** ✅ Build erfolgreich, AAB-Datei erstellt

---

### Schritt 2: Store Assets erstellen

**Dokumentation:** `docs/STORE_ASSETS.md`

**Aufgaben:**
1. Feature Graphic erstellen (1024x500px)
2. Screenshots erstellen (mindestens 2, empfohlen 4-8)
3. Store-Texte vorbereiten
4. Optional: Promo-Video

**Geschätzte Zeit:** 2-4 Stunden

**Empfohlene Tools:**
- [Canva](https://www.canva.com/) für Feature Graphic
- Android Emulator für Screenshots
- [Screenshot.rocks](https://screenshot.rocks/) für Device Frames

**Erfolgskriterium:** ✅ Alle Assets in `store-assets/` Verzeichnis

---

### Schritt 3: Play Console Setup

**Dokumentation:** `docs/PLAY_STORE_SETUP.md` (Teil 1)

**Aufgaben:**
1. App im Play Console erstellen
2. Store Listing ausfüllen
3. Assets hochladen
4. Inhaltsklassifizierung
5. Datensicherheit-Fragebogen
6. Datenschutzrichtlinie-URL

**Geschätzte Zeit:** 1-2 Stunden

**Link:** [Google Play Console](https://play.google.com/console)

**Erfolgskriterium:** ✅ Store Listing vollständig ausgefüllt

---

### Schritt 4: Erster manueller Release

**Dokumentation:** `docs/PLAY_STORE_SETUP.md` (Teil 3)

**Aufgaben:**
1. Signierte AAB lokal bauen
2. Im Play Console hochladen (Open Testing)
3. Release-Notizen hinzufügen
4. Zur Überprüfung einreichen

**Geschätzte Zeit:** 30 Minuten + Google Review-Zeit

**Befehle:**
```bash
# AAB bauen
cd ~/Projekte/bbzcloud-mobil
flutter build appbundle --release

# AAB befindet sich hier:
# build/app/outputs/bundle/release/app-release.aab
```

**Erfolgskriterium:** ✅ App in Überprüfung durch Google

---

### Schritt 5: Service Account für CI/CD

**Dokumentation:** `docs/PLAY_STORE_SETUP.md` (Teil 2)

**Aufgaben:**
1. Google Cloud Project erstellen
2. Play Android Developer API aktivieren
3. Service Account erstellen
4. JSON-Key herunterladen
5. Service Account im Play Console verbinden
6. Berechtigungen zuweisen

**Geschätzte Zeit:** 30 Minuten

**Links:**
- [Google Cloud Console](https://console.cloud.google.com/)
- [Play Console API-Zugriff](https://play.google.com/console)

**Erfolgskriterium:** ✅ Service Account JSON-Datei heruntergeladen

---

### Schritt 6: GitHub Secrets konfigurieren

**Dokumentation:** `docs/GITHUB_SECRETS.md`

**Aufgaben:**
1. Keystore zu Base64 konvertieren
2. 5 Secrets im GitHub Repository erstellen
3. Secrets testen

**Geschätzte Zeit:** 20 Minuten

**Erforderliche Secrets:**
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`
- `PLAY_STORE_CONFIG_JSON`

**Befehle:**
```bash
# Base64 konvertieren
cd ~/Projekte/bbzcloud-mobil
base64 -i android/bbzcloud-upload-keystore.jks | tr -d '\n' > keystore.base64.txt
cat keystore.base64.txt
rm keystore.base64.txt
```

**Erfolgskriterium:** ✅ Alle 5 Secrets konfiguriert

---

## Phase 2: Laufender Betrieb

### Release-Workflow

Nach der einmaligen Einrichtung ist der Prozess für zukünftige Releases automatisiert:

#### 1. Änderungen entwickeln

Arbeite auf dem `develop` Branch oder Feature-Branches.

```bash
git checkout develop
# Entwickle Features
git add .
git commit -m "feat: neue Funktion"
git push origin develop
```

#### 2. CHANGELOG.md aktualisieren

Bevor du einen Release machst, aktualisiere `CHANGELOG.md`:

```markdown
## [1.0.1] - 2025-10-29

### Hinzugefügt
- Neue Funktion XYZ

### Behoben
- Bug fix ABC
```

#### 3. Version erhöhen

In `pubspec.yaml`:

```yaml
version: 1.0.1+2  # MAJOR.MINOR.PATCH+BUILD
```

**Versionierungs-Regeln:**
- **MAJOR** (1.x.x): Breaking Changes
- **MINOR** (x.1.x): Neue Features, abwärtskompatibel
- **PATCH** (x.x.1): Bugfixes
- **BUILD** (+x): Muss bei jedem Release erhöht werden

#### 4. Auf main mergen

```bash
git checkout main
git merge develop
git push origin main
```

#### 5. Automatischer Deployment

🤖 GitHub Actions übernimmt ab hier:

1. **Build-Job** läuft:
   - Flutter Dependencies installieren
   - Tests ausführen
   - APK & AAB bauen
   - Artifacts hochladen

2. **Deploy-Job** läuft (nur bei main):
   - Signiertes AAB bauen
   - Zu Play Store hochladen (Open Testing)
   - GitHub Release erstellen
   - Changelog hinzufügen

#### 6. Verifizierung

1. Gehe zu **GitHub Actions** → Prüfe Workflow-Status
2. Gehe zu **Play Console** → Prüfe neuen Release
3. Gehe zu **GitHub Releases** → Verifiziere Release-Notes

**Dauer:** ~10-15 Minuten für kompletten Workflow

---

## Release-Checkliste

### Vor jedem Release

- [ ] Alle Tests bestehen lokal
- [ ] CHANGELOG.md aktualisiert
- [ ] Version in pubspec.yaml erhöht
- [ ] Keine Debug-Logs oder TODOs im Code
- [ ] README.md aktualisiert (falls nötig)

### Nach dem Release

- [ ] GitHub Actions Workflow erfolgreich
- [ ] App im Play Console sichtbar
- [ ] GitHub Release erstellt
- [ ] Tester informieren (bei Open Testing)
- [ ] Release-Notes kommunizieren

---

## Release Tracks

### Open Testing (Aktuell konfiguriert)

**Eigenschaften:**
- ✅ Öffentlich über Link zugänglich
- ✅ Unbegrenzte Tester
- ✅ Automatische Updates
- ⚠️ Manuelles Teilen des Links erforderlich

**Wann verwenden:**
- Für öffentliche Beta-Tests
- Sammeln von Feedback
- Vor Production-Release

**Tester einladen:**
1. Play Console → Testing → Open Testing
2. Kopiere "Opt-in URL"
3. Teile Link mit Testern

### Andere Tracks

**Closed Testing (Alpha/Beta):**
- Einladung per E-Mail
- Begrenzte Tester-Liste
- Feedback-System integriert

**Internal Testing:**
- Nur Team-Mitglieder
- Sofortige Veröffentlichung
- Ideal für QA

**Production:**
- Öffentlich im Play Store
- Gestaffelte Veröffentlichung möglich
- Vollständige Store-Präsenz

### Track wechseln

Im Fastlane Fastfile:

```ruby
# Zu Production promovieren
bundle exec fastlane promote_to_production
```

Oder im Workflow anpassen:
```yaml
# .github/workflows/build-android.yml
- name: Build and Deploy to Play Store
  run: |
    cd android
    bundle exec fastlane deploy_production  # Statt deploy_open_testing
```

---

## Troubleshooting

### Build schlägt fehl

**Problem:** Flutter Build schlägt fehl

**Lösung:**
```bash
# Dependencies aktualisieren
flutter pub get
flutter pub upgrade

# Cache löschen
flutter clean
flutter pub get

# Neu bauen
flutter build appbundle --release
```

### Signing-Fehler

**Problem:** "Keystore was tampered with"

**Lösung:**
1. Überprüfe Passwörter in `android/key.properties`
2. Teste lokal mit `flutter build appbundle --release`
3. Prüfe GitHub Secrets

### Upload schlägt fehl

**Problem:** "Authentication failed"

**Lösung:**
1. Überprüfe Service Account Berechtigungen im Play Console
2. Stelle sicher, dass Play Android Developer API aktiviert ist
3. Verifiziere `PLAY_STORE_CONFIG_JSON` Secret

### Version-Konflikt

**Problem:** "Version code already exists"

**Lösung:**
1. Erhöhe BUILD-Nummer in `pubspec.yaml`
2. Build-Nummer muss höher sein als alle vorherigen

---

## Best Practices

### Versioning

✅ **Do:**
- Immer BUILD-Nummer erhöhen
- Semantic Versioning befolgen
- Changelog vor Release aktualisieren
- Version-Tags in Git erstellen

❌ **Don't:**
- BUILD-Nummer wiederverwenden
- Versionen überspringen
- Breaking Changes in MINOR-Updates

### Testing

✅ **Do:**
- Vor Release lokal testen
- CI/CD Tests beobachten
- Open Testing vor Production
- Feedback von Testern einholen

❌ **Don't:**
- Direkt zu Production deployen
- Tests überspringen
- Ohne Changelog releasen

### Security

✅ **Do:**
- Keystore sicher aufbewahren
- Secrets regelmäßig rotieren
- Zugriff auf Repository beschränken
- Backup von Keystore erstellen

❌ **Don't:**
- Keystore ins Git committen
- Passwörter im Code
- Secrets in Logs ausgeben

---

## Monitoring & Analytics

### GitHub Actions

**Überwachen:**
- Workflow-Erfolgsrate
- Build-Dauer
- Deployment-Fehler

**Dashboard:** Repository → Actions

### Play Console

**Metriken:**
- Downloads & Installationen
- Bewertungen & Reviews
- Crash-Reports
- ANR-Rate

**Dashboard:** [Play Console](https://play.google.com/console)

### User Feedback

**Quellen:**
- Play Store Reviews
- GitHub Issues
- Direkte Nutzer-Meldungen

**Reaktionszeit:** Innerhalb von 48 Stunden

---

## Eskalation

### Bei kritischen Problemen

1. **Kritischer Bug in Production:**
   - Hotfix-Branch erstellen
   - Schnell fixen
   - Version erhöhen (PATCH)
   - Sofort deployen

2. **Play Store Ablehnung:**
   - Ablehnungsgrund lesen
   - Problem beheben
   - Neue Version einreichen

3. **Build-Fehler in CI/CD:**
   - Logs überprüfen
   - Lokal reproduzieren
   - Fix committen
   - Workflow neu starten

### Support-Kanäle

- GitHub Issues
- Play Console Support
- Fastlane Community
- Flutter Discord

---

## Zusammenfassung

### Einmalige Setup-Zeit
**Gesamt:** ~5-8 Stunden
- Keystore: 15 Min
- Store Assets: 2-4 Std
- Play Console: 1-2 Std
- Service Account: 30 Min
- GitHub Secrets: 20 Min
- Erster Release: 30 Min + Review-Zeit

### Zukünftige Releases
**Gesamt:** ~15-30 Minuten
- Entwicklung: (variiert)
- Changelog: 5 Min
- Version: 2 Min
- Commit & Push: 2 Min
- Automatischer Deploy: 10-15 Min
- Verifizierung: 5 Min

### Dokumentations-Index

1. **KEYSTORE_SETUP.md** - Keystore & Signing
2. **PLAY_STORE_SETUP.md** - Play Console & Service Account
3. **GITHUB_SECRETS.md** - CI/CD Secrets
4. **STORE_ASSETS.md** - Screenshots & Grafiken
5. **RELEASE_PROCESS.md** - Dieser Leitfaden

---

## Nächste Schritte

1. ✅ **Folge der Phase-1-Checkliste** (Einmalige Einrichtung)
2. ✅ **Warte auf Google-Überprüfung** (1-2 Tage)
3. ✅ **Teste automatisches Deployment** (Test-Release)
4. ✅ **Sammle Tester-Feedback** (Open Testing)
5. ✅ **Plane Production-Release** (Nach erfolgreichem Testing)

## Fragen?

Bei Fragen oder Problemen:
1. Konsultiere die spezifische Dokumentation
2. Prüfe Troubleshooting-Abschnitte
3. Erstelle ein GitHub Issue
4. Kontaktiere Play Console Support

**Viel Erfolg mit deinem Release! 🚀**
