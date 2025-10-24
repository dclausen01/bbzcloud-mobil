# Schul.cloud Session Persistence - Tiefenanalyse

## Kritischer Unterschied: Desktop vs. Mobile

### Desktop App (Electron) - Funktioniert ✅
```javascript
<webview
  partition="persist:main"  // ← KRITISCH!
  webpreferences="nativeWindowOpen=yes,javascript=yes,plugins=yes"
/>
```

**Electron's `partition="persist:main"`:**
- Erstellt eine **separate persistente Session-Partition**
- Cookies werden automatisch auf Festplatte gespeichert
- localStorage bleibt zwischen App-Neustarts erhalten
- Kein Code nötig - Electron macht das automatisch

### Mobile App (Flutter InAppWebView) - Problem? ❓
```dart
InAppWebViewSettings(
  thirdPartyCookiesEnabled: true,  // ✅ Cookies erlaubt
  cacheEnabled: true,              // ✅ Cache aktiv
  clearCache: false,               // ✅ Kein Auto-Clear
  incognito: false,                // ✅ Nicht privat
)
```

**Aber:** Flutter InAppWebView hat **KEIN** direktes Äquivalent zu `partition="persist:main"`!

## Das Problem

### Zwei mögliche Szenarien:

#### Szenario A: Angular speichert nicht (Checkbox-Problem)
**Status:** BEHOBEN mit `.click()` statt `.checked = true`
- Checkbox-Click triggert Angular's onClick Handler
- Handler speichert in localStorage/Cookies
- **Fix:** Bereits implementiert ✅

#### Szenario B: Flutter löscht Session beim Neustart
**Status:** MÖGLICHES PROBLEM ⚠️
- Angular speichert korrekt in localStorage/Cookies
- **ABER:** Flutter InAppWebView löscht diese Daten beim App-Neustart?
- Kein `partition="persist:main"` Äquivalent

## Debug-Mechanismus (Hinzugefügt)

```javascript
// Neu hinzugefügter Debug-Code in injection_scripts.dart:
setTimeout(() => {
  console.log('schul.cloud: DEBUG - Checking storage after checkbox click');
  console.log('schul.cloud: localStorage items:', Object.keys(localStorage).length);
  console.log('schul.cloud: localStorage content:', JSON.stringify(localStorage));
  console.log('schul.cloud: document.cookie:', document.cookie);
}, 500);
```

**Was der Debug-Code testet:**
1. Wird localStorage überhaupt gefüllt nach Checkbox-Click?
2. Welche Keys/Values werden gespeichert?
3. Sind Session-Cookies vorhanden?

## Test-Protokoll

### Phase 1: Erste Login-Sitzung
1. App öffnen
2. schul.cloud öffnen
3. Auto-Login beobachten
4. **Console-Logs prüfen:**
   ```
   schul.cloud: Checkbox clicked, now checked = true
   schul.cloud: DEBUG - Checking storage after checkbox click
   schul.cloud: localStorage items: X
   schul.cloud: localStorage content: {...}
   schul.cloud: document.cookie: ...
   ```
5. Notieren: Welche localStorage-Keys und Cookies existieren?

### Phase 2: App-Neustart-Test
1. **App KOMPLETT schließen** (Force Quit)
2. App neu öffnen
3. schul.cloud öffnen
4. **Console-Logs prüfen:**
   ```
   schul.cloud: DEBUG - Checking storage after checkbox click
   schul.cloud: localStorage items: 0 oder X?
   schul.cloud: document.cookie: leer oder gefüllt?
   ```

### Erwartete Ergebnisse:

#### ✅ ERFOLG (Session persistent):
```
Phase 1: localStorage items: 5
Phase 2: localStorage items: 5  ← Gleich!
Phase 2: Kein Login-Formular sichtbar
```

#### ❌ PROBLEM (Session nicht persistent):
```
Phase 1: localStorage items: 5
Phase 2: localStorage items: 0  ← GELÖSCHT!
Phase 2: Login-Formular wird angezeigt
```

## Mögliche Lösungen (Falls Szenario B)

### Lösung 1: CookieManager explizit konfigurieren
```dart
// In main.dart oder webview_screen.dart
await CookieManager.instance().setCookie(
  url: WebUri('https://app.schul.cloud'),
  name: 'session_cookie',
  value: value,
  expiresDate: DateTime.now().add(Duration(days: 365)),
  isSecure: true,
  isHttpOnly: true,
  sameSite: HTTPCookieSameSitePolicy.LAX,
);
```

### Lösung 2: Shared Preferences als Backup
```dart
// Session-Token in Flutter's SharedPreferences sichern
final prefs = await SharedPreferences.getInstance();
await prefs.setString('schulcloud_session', sessionToken);
```

### Lösung 3: Custom WebView Session Manager
```dart
// Eigener Session Manager, der Cookies vor App-Neustart sichert
class SessionManager {
  Future<void> saveCookies() async {
    final cookies = await CookieManager.instance().getCookies(
      url: WebUri('https://app.schul.cloud'),
    );
    // Cookies in lokaler Datei/DB speichern
  }
  
  Future<void> restoreCookies() async {
    // Cookies beim App-Start wiederherstellen
  }
}
```

## Vergleich: Warum funktioniert Moodle?

**Hypothese:** Moodle könnte ein längeres Cookie-Expiration verwenden:
```
Moodle: Cookie expires in 30 days
schul.cloud: Cookie expires on session end
```

Wenn schul.cloud nur **Session-Cookies** verwendet (ohne Expiration), werden diese von Flutter InAppWebView möglicherweise nicht persistent gespeichert!

## Nächste Schritte

1. **Test durchführen** mit Debug-Logs
2. **Console-Output analysieren**:
   - Sind localStorage-Keys vorhanden nach Login?
   - Sind Cookies vorhanden?
   - Bleiben sie nach App-Neustart?
3. **Entscheidung treffen**:
   - Wenn Daten nach Neustart weg sind → Lösung 1-3 implementieren
   - Wenn Daten erhalten bleiben → Checkbox-Fix war ausreichend

## Wichtige Erkenntnisse

### Desktop App (Electron) - Automatisch ✅
- `partition="persist:main"` macht alles automatisch
- Keine manuelle Cookie-Verwaltung nötig
- Session bleibt immer erhalten

### Mobile App (Flutter) - Manuell ⚠️
- Kein automatischer Mechanismus wie `partition`
- Möglicherweise manuelle Cookie/Session-Verwaltung nötig
- InAppWebView-Standardverhalten könnte Session-Cookies löschen

---

**Status:** Debug-Logging hinzugefügt  
**Nächster Schritt:** Test mit Debug-Logs durchführen  
**Datum:** 2025-10-24
