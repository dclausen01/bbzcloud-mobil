# GitHub Secrets Konfiguration

Diese Anleitung erklärt, wie du die erforderlichen GitHub Secrets für automatische Play Store Deployments einrichtest.

## Übersicht

GitHub Secrets werden verwendet, um sensible Informationen wie Keystore-Passwörter und Service Account Credentials sicher zu speichern. Diese Secrets werden dann von GitHub Actions verwendet, um automatisch signierte Builds zu erstellen und im Play Store zu veröffentlichen.

## Voraussetzungen

- ✅ Keystore erstellt (siehe KEYSTORE_SETUP.md)
- ✅ Play Store Service Account erstellt (siehe PLAY_STORE_SETUP.md)
- ✅ Admin-Zugriff auf GitHub Repository

## Erforderliche Secrets

| Secret Name | Beschreibung | Quelle |
|------------|--------------|--------|
| `KEYSTORE_BASE64` | Keystore als Base64-String | Konvertierter Keystore |
| `KEYSTORE_PASSWORD` | Passwort für den Keystore | Keystore-Erstellung |
| `KEY_ALIAS` | Alias des Signing-Keys | `upload` |
| `KEY_PASSWORD` | Passwort für den Signing-Key | Keystore-Erstellung |
| `PLAY_STORE_CONFIG_JSON` | Service Account JSON | Google Cloud Console |

## Schritt 1: Keystore zu Base64 konvertieren

### 1.1 Konvertierung durchführen

```bash
# Im Projekt-Verzeichnis
cd ~/Projekte/bbzcloud-mobil

# Keystore zu Base64 konvertieren
base64 -i android/bbzcloud-upload-keystore.jks | tr -d '\n' > keystore.base64.txt
```

### 1.2 Base64-String kopieren

```bash
# Base64-String anzeigen
cat keystore.base64.txt
```

Kopiere die **gesamte Ausgabe**. Dies ist der Wert für `KEYSTORE_BASE64`.

### 1.3 Temporäre Datei löschen

```bash
# Sichere Löschung
rm keystore.base64.txt
```

## Schritt 2: Service Account JSON vorbereiten

### 2.1 JSON-Datei öffnen

Die JSON-Datei wurde bei der Service Account Erstellung heruntergeladen:
- Dateiname: `bbzcloud-mobile-ci-xxxxx.json`
- Standardort: `~/Downloads/`

### 2.2 JSON-Inhalt kopieren

```bash
# JSON-Inhalt anzeigen (Beispiel)
cat ~/Downloads/bbzcloud-mobile-ci-*.json
```

Kopiere den **kompletten JSON-Inhalt** (von `{` bis `}`).

**Beispiel-Struktur:**
```json
{
  "type": "service_account",
  "project_id": "bbzcloud-mobile-ci",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "play-store-deploy@bbzcloud-mobile-ci.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

## Schritt 3: Secrets im GitHub Repository einrichten

### 3.1 Zu Repository Settings navigieren

1. Gehe zu deinem GitHub Repository
2. Klicke auf **Settings** (oben rechts)
3. In der Seitenleiste: **Secrets and variables** → **Actions**
4. Klicke auf **New repository secret**

### 3.2 Secret 1: KEYSTORE_BASE64

1. **Name**: `KEYSTORE_BASE64`
2. **Value**: [Base64-String aus Schritt 1.2]
3. Klicke auf **Add secret**

⚠️ **WICHTIG**: Der Base64-String sollte KEINE Zeilenumbrüche enthalten!

### 3.3 Secret 2: KEYSTORE_PASSWORD

1. **Name**: `KEYSTORE_PASSWORD`
2. **Value**: [Dein Keystore-Passwort]
3. Klicke auf **Add secret**

💡 **Tipp**: Dies ist das Passwort, das du bei der Keystore-Erstellung eingegeben hast.

### 3.4 Secret 3: KEY_ALIAS

1. **Name**: `KEY_ALIAS`
2. **Value**: `upload`
3. Klicke auf **Add secret**

💡 **Info**: Dies ist der Standard-Alias aus der Keystore-Erstellung.

### 3.5 Secret 4: KEY_PASSWORD

1. **Name**: `KEY_PASSWORD`
2. **Value**: [Dein Key-Passwort]
3. Klicke auf **Add secret**

💡 **Tipp**: Oft identisch mit dem Keystore-Passwort, es sei denn, du hast ein anderes Passwort gewählt.

### 3.6 Secret 5: PLAY_STORE_CONFIG_JSON

1. **Name**: `PLAY_STORE_CONFIG_JSON`
2. **Value**: [Kompletter JSON-Inhalt aus Schritt 2.2]
3. Klicke auf **Add secret**

⚠️ **WICHTIG**: 
- Kopiere den kompletten JSON-Inhalt inkl. geschweifte Klammern
- Stelle sicher, dass keine Formatierungsfehler vorhanden sind
- Die JSON-Datei muss gültig sein

## Schritt 4: Verifizierung

### 4.1 Secrets überprüfen

Navigiere zu: **Settings** → **Secrets and variables** → **Actions**

Du solltest folgende 5 Secrets sehen:
- ✅ `KEYSTORE_BASE64`
- ✅ `KEYSTORE_PASSWORD`
- ✅ `KEY_ALIAS`
- ✅ `KEY_PASSWORD`
- ✅ `PLAY_STORE_CONFIG_JSON`

⚠️ **Hinweis**: GitHub zeigt die Secret-Werte nicht mehr an, nachdem sie gespeichert wurden.

### 4.2 Test-Push durchführen

Um die Secrets zu testen:

1. Erstelle eine kleine Änderung (z.B. in README.md)
2. Commit und Push auf `main`:
   ```bash
   git add README.md
   git commit -m "test: verify secrets configuration"
   git push origin main
   ```
3. Gehe zu **Actions** Tab
4. Wähle den laufenden Workflow
5. Prüfe die Logs:
   - ✅ "Decode Keystore" sollte erfolgreich sein
   - ✅ "Create key.properties" sollte erfolgreich sein
   - ✅ "Create Play Store Service Account JSON" sollte erfolgreich sein

## Sicherheit

### Best Practices

✅ **IMMER:**
- Secrets nur über GitHub UI hinzufügen
- Secrets niemals in Code committen
- Secrets regelmäßig rotieren
- Zugriff auf Repository beschränken

❌ **NIEMALS:**
- Secrets in Logs ausgeben
- Secrets in Dateien speichern
- Secrets per E-Mail versenden
- Secrets in öffentlichen Issues erwähnen

### Secret-Rotation

Wenn du Secrets ändern musst:

1. **Keystore**: Neuer Keystore = neue App-ID erforderlich!
2. **Passwörter**: Ändere im GitHub Secret
3. **Service Account**: 
   - Erstelle neuen Key in Google Cloud Console
   - Aktualisiere `PLAY_STORE_CONFIG_JSON` Secret
   - Lösche alten Key in Google Cloud Console

## Troubleshooting

### Fehler: "Failed to decode keystore"

**Ursache**: Base64-String ist ungültig

**Lösung**:
1. Erstelle Base64-String neu (Schritt 1)
2. Stelle sicher, dass KEINE Zeilenumbrüche im String sind
3. Verwende `tr -d '\n'` beim Konvertieren

### Fehler: "Keystore password incorrect"

**Ursache**: Falsches Passwort in Secret

**Lösung**:
1. Überprüfe das Passwort in deinem Passwort-Manager
2. Aktualisiere `KEYSTORE_PASSWORD` Secret
3. Teste lokal mit dem Passwort

### Fehler: "Service account authentication failed"

**Ursache**: JSON-Datei ungültig oder Berechtigungen fehlen

**Lösung**:
1. Überprüfe JSON-Syntax (z.B. mit jsonlint.com)
2. Stelle sicher, dass Service Account Berechtigungen im Play Console hat
3. Prüfe ob Google Play Android Developer API aktiviert ist

### Fehler: "Secret not found"

**Ursache**: Secret-Name falsch geschrieben

**Lösung**:
1. Überprüfe Secret-Namen (case-sensitive!)
2. Vergleiche mit erforderlichen Namen oben
3. Lösche falsches Secret und erstelle neu

## Wartung

### Monatliche Checks

- ✅ Prüfe ob Secrets noch gültig sind
- ✅ Teste Deployment-Workflow
- ✅ Überprüfe Service Account Berechtigungen

### Bei Problemen

1. Prüfe GitHub Actions Logs
2. Teste lokale Builds
3. Überprüfe Secret-Konfiguration
4. Konsultiere Troubleshooting-Abschnitt

## Nächste Schritte

Nach erfolgreicher Secret-Konfiguration:
1. ✅ Teste Deployment mit Test-Push
2. ✅ Prüfe GitHub Actions Logs
3. ✅ Verifiziere App im Play Console
4. ✅ Dokumentiere Secrets-Backup-Prozess

## Wichtige Hinweise

⚠️ **Backup**: Speichere Keystore und Passwörter sicher!

⚠️ **Team**: Teile Secrets nur mit vertrauenswürdigen Team-Mitgliedern

⚠️ **Rotation**: Plane regelmäßige Secret-Rotation ein

📝 **Dokumentation**: Halte diese Dokumentation aktuell
