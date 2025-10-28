# Datenschutzerklärung für BBZ Cloud Mobile

**Stand: 28. Oktober 2025**

## 1. Verantwortlicher

BBZ Rendsburg-Eckernförde  
Kieler Str. 30  
24768 Rendsburg  
Deutschland

E-Mail: support@bbz-rd-eck.de  
Website: https://www.bbz-rd-eck.de

## 2. Allgemeines zur Datenverarbeitung

### 2.1 Umfang der Verarbeitung personenbezogener Daten

Die App BBZ Cloud Mobile dient als Zugangsportal zu den digitalen Diensten des BBZ Rendsburg-Eckernförde. Wir erheben und verwenden personenbezogene Daten unserer Nutzer grundsätzlich nur, soweit dies zur Bereitstellung einer funktionsfähigen App erforderlich ist.

### 2.2 Datenspeicherung

Alle von der App gespeicherten Daten werden **ausschließlich lokal auf Ihrem Gerät** gespeichert. Es erfolgt **keine Übertragung an externe Server** des App-Betreibers. Die App fungiert lediglich als Zugangsportal zu den bereits bestehenden BBZ-Diensten.

## 3. Welche Daten werden erhoben?

### 3.1 Lokal auf dem Gerät gespeicherte Daten

Die App speichert folgende Daten lokal auf Ihrem Gerät:

#### a) Anmeldedaten (optional)
- E-Mail-Adresse (BBZ-Schulaccount)
- Passwort (verschlüsselt gespeichert mittels flutter_secure_storage)
- Ausgewählte Rolle (Schüler/Lehrkraft)

**Zweck:** Auto-Login-Funktion für bequemen Zugang zu BBZ-Diensten  
**Rechtsgrundlage:** Einwilligung (Art. 6 Abs. 1 lit. a DSGVO)  
**Speicherort:** Verschlüsselter Speicher des Betriebssystems (Keychain/Keystore)

#### b) App-Einstellungen
- Theme-Präferenz (Hell/Dunkel/System)
- Favorisierte Apps
- Letzte Verwendung von Apps

**Zweck:** Personalisierung der App-Nutzung  
**Rechtsgrundlage:** Berechtigtes Interesse (Art. 6 Abs. 1 lit. f DSGVO)  
**Speicherort:** Lokale Datenbank (SQLite) auf dem Gerät

#### c) Custom Apps (benutzerdefinierte Apps)
- Name, URL und Icon eigener hinzugefügter Apps

**Zweck:** Erweiterung der App-Funktionalität nach Nutzerwünschen  
**Rechtsgrundlage:** Einwilligung (Art. 6 Abs. 1 lit. a DSGVO)  
**Speicherort:** Lokale Datenbank (SQLite) auf dem Gerät

### 3.2 Temporäre Daten

Die App verwendet einen WebView-Browser zur Anzeige der BBZ-Dienste. Dabei können folgende temporäre Daten entstehen:

- Browser-Cache
- Cookies der besuchten BBZ-Websites
- Browser-Verlauf innerhalb der App

Diese Daten werden lokal gespeichert und können durch Löschen der App-Daten oder Deinstallation der App vollständig entfernt werden.

## 4. Berechtigungen der App

Die App benötigt folgende Berechtigungen:

### 4.1 Internet-Zugriff (INTERNET)
**Zweck:** Zugriff auf die BBZ-Online-Dienste (IServ, Moodle, Nextcloud, etc.)  
**Datenübertragung:** Nur direkt zwischen Ihrem Gerät und den jeweiligen BBZ-Servern

### 4.2 Netzwerkstatus (ACCESS_NETWORK_STATE)
**Zweck:** Prüfung der Internetverbindung zur Verbesserung der Nutzererfahrung  
**Datenübertragung:** Keine; lokale Prüfung

### 4.3 Speicherzugriff (READ/WRITE_EXTERNAL_STORAGE, nur Android 12 und älter)
**Zweck:** Download von Dateien aus den BBZ-Diensten (z.B. Dokumente aus Moodle)  
**Datenübertragung:** Keine; Dateien werden lokal gespeichert

## 5. Datenweitergabe an Dritte

### 5.1 Keine Weitergabe durch die App

Die App selbst gibt **keine Daten an Dritte weiter**. Alle Daten verbleiben auf Ihrem Gerät.

### 5.2 Zugriff auf BBZ-Dienste

Wenn Sie über die App auf BBZ-Dienste zugreifen (z.B. IServ, Moodle, Nextcloud), erfolgt eine **direkte Verbindung** zwischen Ihrem Gerät und dem jeweiligen Dienst. Für diese Dienste gelten die jeweiligen Datenschutzerklärungen:

- **IServ**: https://iserv.eu/de/datenschutz
- **Moodle**: Datenschutzerklärung des BBZ Rendsburg-Eckernförde
- **Nextcloud**: Datenschutzerklärung des BBZ Rendsburg-Eckernförde
- **Weitere BBZ-Dienste**: Siehe jeweilige Datenschutzerklärung

Die App fungiert hierbei lediglich als Browser-Oberfläche (WebView).

## 6. Datenübertragung in Drittländer

Es erfolgt **keine Datenübertragung** in Drittländer außerhalb der EU/EWR durch die App selbst.

## 7. Datensicherheit

### 7.1 Verschlüsselung

Sensible Daten (Passwörter) werden verschlüsselt gespeichert:
- **Android:** Android Keystore System
- **iOS:** iOS Keychain

### 7.2 HTTPS-Verbindungen

Alle Verbindungen zu BBZ-Diensten erfolgen über verschlüsselte HTTPS-Verbindungen.

### 7.3 Lokale Datenspeicherung

Alle App-Daten sind durch die Gerätesicherheit (PIN, Fingerabdruck, Face ID) geschützt.

## 8. Speicherdauer

- **Anmeldedaten:** Bis zur manuellen Löschung durch Nutzer oder Deinstallation der App
- **App-Einstellungen:** Bis zur Deinstallation der App
- **Cache und temporäre Daten:** Können jederzeit in den App-Einstellungen gelöscht werden

## 9. Ihre Rechte als betroffene Person

Sie haben gemäß DSGVO folgende Rechte:

### 9.1 Auskunftsrecht (Art. 15 DSGVO)
Sie können Auskunft über die von der App gespeicherten personenbezogenen Daten verlangen.

### 9.2 Recht auf Berichtigung (Art. 16 DSGVO)
Sie können die Berichtigung unrichtiger Daten verlangen.

### 9.3 Recht auf Löschung (Art. 17 DSGVO)
Sie können die Löschung Ihrer Daten verlangen durch:
- Zurücksetzen der App in den Einstellungen
- Löschen der App-Daten in den Geräteeinstellungen
- Deinstallation der App

### 9.4 Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)
Sie können die Einschränkung der Verarbeitung verlangen.

### 9.5 Recht auf Datenübertragbarkeit (Art. 20 DSGVO)
Sie können die Herausgabe Ihrer Daten in einem strukturierten Format verlangen.

### 9.6 Widerspruchsrecht (Art. 21 DSGVO)
Sie können der Verarbeitung Ihrer Daten widersprechen.

### 9.7 Recht auf Widerruf der Einwilligung (Art. 7 Abs. 3 DSGVO)
Sie können Ihre Einwilligung zur Speicherung von Anmeldedaten jederzeit widerrufen durch:
- Deaktivierung der Auto-Login-Funktion in den App-Einstellungen
- Löschung der gespeicherten Anmeldedaten

## 10. Beschwerderecht

Sie haben das Recht, sich bei einer Datenschutz-Aufsichtsbehörde über die Verarbeitung Ihrer personenbezogenen Daten zu beschweren.

**Zuständige Aufsichtsbehörde für Schleswig-Holstein:**

Unabhängiges Landeszentrum für Datenschutz Schleswig-Holstein (ULD)  
Holstenstraße 98  
24103 Kiel  
Deutschland

Telefon: +49 431 988-1200  
E-Mail: mail@datenschutzzentrum.de  
Website: https://www.datenschutzzentrum.de

## 11. Keine automatisierte Entscheidungsfindung

Die App verwendet **keine automatisierte Entscheidungsfindung** einschließlich Profiling gemäß Art. 22 DSGVO.

## 12. Keine Analyse-Tools oder Tracking

Die App verwendet:
- ❌ **Keine Analyse-Tools** (z.B. Google Analytics)
- ❌ **Kein Tracking** oder Nutzerverhalten-Analysen
- ❌ **Keine Werbe-Netzwerke**
- ❌ **Keine Crash-Reporting-Dienste**

Die App respektiert Ihre Privatsphäre vollständig.

## 13. Minderjährige

Die App richtet sich an Schüler und Lehrkräfte des BBZ Rendsburg-Eckernförde. Die Nutzung durch Minderjährige erfolgt im Rahmen des Schulbetriebs. Eltern oder Erziehungsberechtigte sollten die Nutzung der App durch Minderjährige begleiten.

## 14. Änderungen dieser Datenschutzerklärung

Wir behalten uns vor, diese Datenschutzerklärung anzupassen, um sie an geänderte Rechtslage oder Änderungen der App anzupassen. Die aktuelle Datenschutzerklärung ist stets in der App und unter folgendem Link abrufbar:

https://github.com/dclausen01/bbzcloud-mobil/blob/main/docs/PRIVACY_POLICY.md

## 15. Kontakt

Bei Fragen zum Datenschutz oder zur Ausübung Ihrer Rechte kontaktieren Sie uns:

**Per E-Mail:**  
support@bbz-rd-eck.de

**Per Post:**  
BBZ Rendsburg-Eckernförde  
z.Hd. Datenschutzbeauftragter  
Kieler Str. 30  
24768 Rendsburg  
Deutschland

---

**Hinweis:** Diese Datenschutzerklärung bezieht sich ausschließlich auf die App "BBZ Cloud Mobile" selbst. Für die über die App erreichbaren BBZ-Dienste (IServ, Moodle, Nextcloud, etc.) gelten die jeweiligen Datenschutzerklärungen dieser Dienste.

---

*Letzte Aktualisierung: 28. Oktober 2025*
