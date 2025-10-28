# Keystore Setup für Play Store Veröffentlichung

## Übersicht

Für die Veröffentlichung im Google Play Store benötigt die App eine digitale Signatur. Diese Anleitung führt dich durch die Erstellung des Keystores und dessen Konfiguration.

## Voraussetzungen

- Java Development Kit (JDK) installiert
- Zugriff auf die Kommandozeile
- Sicherer Ort zur Aufbewahrung des Keystores

## Schritt 1: Keystore erstellen

⚠️ **WICHTIG**: Dieser Schritt muss nur EINMAL durchgeführt werden. Der Keystore und die Passwörter müssen sicher aufbewahrt werden!

### 1.1 Keystore generieren

Führe folgenden Befehl aus:

```bash
keytool -genkey -v -keystore ~/bbzcloud-upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS
```

### 1.2 Informationen eingeben

Du wirst nach folgenden Informationen gefragt:

- **Keystore-Passwort**: Wähle ein sicheres Passwort (mindestens 8 Zeichen)
- **Schlüssel-Passwort**: Kann identisch zum Keystore-Passwort sein
- **Vor- und Nachname**: Dein Name oder Firmenname
- **Organisationseinheit**: z.B. "Development"
- **Organisation**: z.B. "BBZCloud"
- **Stadt**: Deine Stadt
- **Bundesland/Kanton**: Dein Bundesland/Kanton
- **Ländercode**: z.B. "CH" für Schweiz, "DE" für Deutschland

**Beispiel:**
```
Keystore-Passwort eingeben: ****************
Geben Sie das neue Passwort erneut ein: ****************
Wie lautet Ihr Vor- und Nachname?
  [Unknown]:  Max Mustermann
Wie lautet der Name Ihrer organisatorischen Einheit?
  [Unknown]:  Development
Wie lautet der Name Ihrer Organisation?
  [Unknown]:  BBZCloud
Wie lautet der Name Ihrer Stadt oder Gemeinde?
  [Unknown]:  Zürich
Wie lautet der Name Ihres Bundeslandes oder Ihrer Provinz?
  [Unknown]:  ZH
Wie lautet der Ländercode (zwei Buchstaben) für diese Einheit?
  [Unknown]:  CH
Ist CN=Max Mustermann, OU=Development, O=BBZCloud, L=Zürich, ST=ZH, C=CH richtig?
  [Nein]:  ja

Geben Sie das Passwort für <upload> ein.
        (EINGABETASTE, wenn Passwort dasselbe wie für Keystore): 
```

### 1.3 Keystore verschieben

Verschiebe den Keystore in das Android-Verzeichnis deines Projekts:

```bash
mv ~/bbzcloud-upload-keystore.jks ~/Projekte/bbzcloud-mobil/android/
```

## Schritt 2: Lokale Konfiguration

### 2.1 key.properties erstellen

Erstelle die Datei `android/key.properties` mit folgendem Inhalt:

```properties
storePassword=DEIN_KEYSTORE_PASSWORT
keyPassword=DEIN_KEY_PASSWORT
keyAlias=upload
storeFile=bbzcloud-upload-keystore.jks
```

⚠️ **WICHTIG**: Diese Datei wird NICHT ins Git-Repository committet!

### 2.2 Prüfen

Stelle sicher, dass `android/key.properties` in `.gitignore` eingetragen ist (bereits erledigt).

## Schritt 3: GitHub Secrets vorbereiten

### 3.1 Keystore zu Base64 konvertieren

Für GitHub Actions muss der Keystore als Base64-String vorliegen:

```bash
base64 -i android/bbzcloud-upload-keystore.jks | tr -d '\n' > keystore.base64.txt
```

### 3.2 Base64-String kopieren

```bash
cat keystore.base64.txt
```

Kopiere die gesamte Ausgabe. Dies wird als GitHub Secret `KEYSTORE_BASE64` benötigt.

### 3.3 Aufräumen

```bash
rm keystore.base64.txt
```

## Schritt 4: GitHub Secrets einrichten

Gehe zu deinem GitHub Repository → Settings → Secrets and variables → Actions

Erstelle folgende Secrets:

| Secret Name | Wert | Beschreibung |
|------------|------|--------------|
| `KEYSTORE_BASE64` | [Base64-String aus Schritt 3.2] | Keystore als Base64 |
| `KEYSTORE_PASSWORD` | [Dein Keystore-Passwort] | Passwort für den Keystore |
| `KEY_ALIAS` | `upload` | Alias des Keys im Keystore |
| `KEY_PASSWORD` | [Dein Key-Passwort] | Passwort für den Key |

## Sicherheit

### Keystore sichern

✅ **MUSS:**
- Keystore-Datei an sicherem Ort aufbewahren (z.B. verschlüsselter USB-Stick)
- Passwörter in Passwort-Manager speichern
- Backup des Keystores erstellen

❌ **NIEMALS:**
- Keystore ins Git-Repository committen
- Keystore per E-Mail versenden
- Passwörter im Klartext speichern
- Keystore auf unsicheren Systemen lagern

### Keystore verloren?

Wenn der Keystore verloren geht:
- ⚠️ Du kannst die App NICHT mehr updaten
- ⚠️ Du musst eine neue App mit neuer Package-ID veröffentlichen
- ⚠️ Alle Nutzer verlieren ihre Daten und müssen die neue App installieren

**Deshalb: Backup erstellen und sicher aufbewahren!**

## Verifizierung

### Lokaler Test

Teste die Signing-Konfiguration lokal:

```bash
cd ~/Projekte/bbzcloud-mobil
flutter build appbundle --release
```

Wenn der Build erfolgreich ist, ist die Konfiguration korrekt.

### Signatur prüfen

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

Erwartete Ausgabe sollte "jar verified" enthalten.

## Troubleshooting

### Fehler: "Module java.naming does not read a module"

**Problem:** Gradle verwendet die falsche Java-Version (z.B. aus Android Studio statt System-Java)

**Lösung 1: JAVA_HOME setzen**

```bash
# Finde die richtige Java-Installation
which java
java -version

# Setze JAVA_HOME (z.B. für OpenJDK 17)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Teste
java -version
```

**Dauerhaft setzen in `~/.bashrc` oder `~/.zshrc`:**

```bash
# Am Ende der Datei hinzufügen
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
```

**Lösung 2: gradle.properties konfigurieren**

Erstelle/bearbeite `android/gradle.properties`:

```properties
org.gradle.java.home=/usr/lib/jvm/java-17-openjdk
```

**Lösung 3: Gradle Cache löschen**

```bash
# Gradle Cache löschen
rm -rf ~/.gradle/caches
rm -rf ~/.gradle/wrapper

# Flutter clean
flutter clean

# Neu versuchen
flutter build appbundle --release
```

### Fehler: "Keystore was tampered with, or password was incorrect"
- Überprüfe das Keystore-Passwort in `android/key.properties`
- Stelle sicher, dass der Keystore-Pfad korrekt ist

### Fehler: "Could not read key from keystore"
- Überprüfe das Key-Passwort in `android/key.properties`
- Stelle sicher, dass der Key-Alias korrekt ist (`upload`)

### Fehler: "Keystore file not found"
- Überprüfe den Pfad zum Keystore
- Stelle sicher, dass der Keystore in `android/` liegt

## Nächste Schritte

Nach erfolgreichem Setup:
1. ✅ Lokalen Release-Build testen
2. ✅ GitHub Secrets konfigurieren
3. ✅ Play Store Service Account einrichten (siehe PLAY_STORE_SETUP.md)
4. ✅ Ersten automatischen Deployment testen
