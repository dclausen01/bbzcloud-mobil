# Workflow-Vergleich: schul.cloud vs. Moodle vs. WebUntis

## Executive Summary

**KRITISCHER UNTERSCHIED GEFUNDEN:** schul.cloud sendet das Login SOFORT ab und signalisiert Flutter "loginComplete", während Moodle und WebUntis WARTEN bis der Login-Prozess vollständig ist. Dies könnte dazu führen, dass Angular nicht genug Zeit hat, die Session zu speichern!

---

## Detaillierte Workflow-Analyse

### 1. Moodle (Einfach & Robust) ✅

```javascript
// SYNCHRONER, EINFACHER WORKFLOW
function moodleLogin() {
  1. Felder füllen
  2. Events triggern
  3. 300ms warten
  4. Button klicken
  5. FERTIG - keine weitere Logik
}
```

**Timing:**
- Füllen: Sofort
- Warten: 300ms
- Submit: Button-Click
- **Danach:** Moodle-Server verarbeitet, speichert Session automatisch

**Warum funktioniert es?**
- Moodle verwendet traditionelle Form-Submission
- Cookie wird vom Server gesetzt (lange Expiration)
- Keine JavaScript-basierte Session-Verwaltung nötig

---

### 2. WebUntis (Komplex aber Sicher) ✅

```javascript
// ASYNC WORKFLOW MIT WARTEZEIT
async function webuntisLogin() {
  1. Warten auf Form (bis 100ms Polling)
  2. React Fiber Nodes manipulieren
  3. Username füllen
  4. 100ms warten
  5. Password füllen  
  6. 500ms warten
  7. Form absenden
  8. 2000ms warten (!!! WICHTIG !!!)
  9. Prüfen ob Authenticator-Seite
  10. Nur reload wenn KEINE Auth-Seite
}
```

**Timing:**
- Füllen: Async mit Waits
- React onChange: Synchron
- Submit: Form submit
- **Nach Submit: 2000ms WARTEN** ← KRITISCH!
- Dann prüfen + optional reload

**Warum funktioniert es?**
- Wartet 2 Sekunden nach Submit
- Gibt React/Server Zeit zum Verarbeiten
- Reload nur wenn nötig (nicht bei Auth)

---

### 3. schul.cloud (Komplex & Problematisch?) ⚠️

```javascript
// ASYNC WORKFLOW MIT MEHRFACHEN VERSUCHEN
async function schulcloudLogin() {
  // PHASE 1: Email-Seite
  1. Email-Feld füllen
  2. 300ms warten
  3. "Weiter" Button klicken
  4. 2000ms warten für Seitenwechsel
  
  // PHASE 2: Password-Seite
  5. Password-Feld füllen
  6. Checkbox KLICKEN (nicht setzen!)
  7. 500ms warten für localStorage Check
  8. 1000ms warten (Desktop-App: genau 1000ms)
  9. "Anmelden" Button klicken
  10. 1000ms warten
  11. Signal an Flutter: 'loginComplete'
  12. FERTIG - Script endet
}
```

**Timing:**
- Phase 1: ~2300ms (Email + Weiter + Wait)
- Phase 2: ~2500ms (Password + Checkbox + Login)
- **Total: ~4800ms**
- **Aber:** Script wird mehrfach ausgeführt!
  - setTimeout(executeLogin, 500)
  - setTimeout(executeLogin, 1500)

**KRITISCHES PROBLEM:**
```javascript
// Nach Login-Click:
span.click();  // Login wird abgeschickt

setTimeout(() => {
  window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
  // ← Flutter denkt Login ist fertig!
}, 1000);
```

**Was passiert:**
1. Login-Button wird geklickt
2. 1000ms später: Flutter wird informiert "loginComplete"
3. Flutter versteckt Loading-Overlay
4. **ABER:** Angular braucht möglicherweise LÄNGER um:
   - Authentifizierung zu verarbeiten
   - Session in localStorage zu speichern
   - Cookies zu setzen

---

## Timing-Vergleich

| App | Felder füllen | Vor Submit | Nach Submit | Session-Save Zeit |
|-----|---------------|------------|-------------|-------------------|
| **Moodle** | Sofort | 300ms | 0ms | Server-seitig |
| **WebUntis** | Async | 500ms | **2000ms** ✅ | Während 2s Wait |
| **schul.cloud** | Async | 1000ms | **1000ms** ⚠️ | Möglicherweise zu kurz? |

---

## Das Haupt-Problem

### WebUntis vs. schul.cloud

**WebUntis nach Submit:**
```javascript
await new Promise(resolve => setTimeout(resolve, 2000)); // WARTET!
// Dann erst: Prüfen + optional reload
```
→ **React hat 2 Sekunden** zum Speichern

**schul.cloud nach Submit:**
```javascript
setTimeout(() => {
  window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
}, 1000); // Signal nach nur 1 Sekunde!
```
→ **Angular hat nur 1 Sekunde** zum Speichern

---

## Zusätzliches Problem: Multiple Executions

```javascript
// schul.cloud führt Login ZWEIMAL aus!
setTimeout(executeLogin, 500);   // Versuch 1 nach 500ms
setTimeout(executeLogin, 1500);  // Versuch 2 nach 1500ms
```

**Problem:**
- Beide Versuche könnten parallel laufen
- Checkbox könnte zweimal geklickt werden (toggle!)
- Race Condition beim Session-Speichern

**Moodle/WebUntis:**
- Nur EINE Ausführung
- Keine Race Conditions

---

## Checkpoint-Analyse

### Moodle: Keine speziellen Checkpoints
```javascript
// Einfach: Fill → Wait → Submit → Done
setTimeout(() => { loginButton.click(); }, 300);
```

### WebUntis: Mehrere Checkpoints ✅
```javascript
// Checkpoint 1: Form ready?
await new Promise((resolve) => {
  const checkForm = () => {
    if (form) resolve();
    else setTimeout(checkForm, 100);
  };
});

// Checkpoint 2: Button enabled?
if (!submitButton.disabled) { /* submit */ }

// Checkpoint 3: Auth page?
const authLabel = document.querySelector('.un-input-group__label');
if (authLabel?.textContent !== 'Bestätigungscode') {
  window.location.reload();
}
```

### schul.cloud: Wenige Checkpoints ⚠️
```javascript
// Checkpoint 1: Button enabled?
if (weiterButton && !weiterButton.disabled) { /* click */ }

// Checkpoint 2: Field visible?
if (passwordField && passwordField.offsetParent !== null) { /* fill */ }

// ABER: Kein Checkpoint ob Session gespeichert wurde!
```

---

## Desktop App vs. Mobile App

### Desktop (Electron)
```javascript
// Klickt Checkbox, dann...
setTimeout(() => {
  console.log('Clicking login button');
  loginButton.click();
}, 1000);
// KEIN Signal an App
// KEIN früher Abbruch
// partition="persist:main" speichert ALLES automatisch
```

### Mobile (Flutter)
```javascript
// Klickt Checkbox, dann...
setTimeout(() => {
  span.click();  // Login
  
  setTimeout(() => {
    window.flutter_inappwebview.callHandler('loginComplete');
    // ← App denkt Login ist fertig!
  }, 1000);
}, 1000);
```

**UNTERSCHIED:**
- Desktop: Kein Signal, Electron wartet automatisch
- Mobile: Signal nach 1s, Flutter könnte WebView zu früh manipulieren

---

## Lösungsvorschläge

### Option 1: Längere Wartezeit (Wie WebUntis) 🥇
```javascript
// Nach Login-Click: WARTEN wie WebUntis
span.click();

// NICHT sofort signalisieren!
// Stattdessen: Länger warten
await new Promise(resolve => setTimeout(resolve, 3000)); // 3s statt 1s

// Dann Signal senden
window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
```

### Option 2: Auf localStorage/Cookie warten 🥈
```javascript
span.click();

// Warten bis Session gespeichert ist
let attempts = 0;
const checkInterval = setInterval(() => {
  attempts++;
  
  // Prüfen ob Session-Keys vorhanden
  const hasSession = localStorage.getItem('someSessionKey') !== null ||
                     document.cookie.includes('session=');
  
  if (hasSession || attempts >= 30) { // Max 3 Sekunden
    clearInterval(checkInterval);
    window.flutter_inappwebview.callHandler('loginComplete');
  }
}, 100);
```

### Option 3: Multiple Executions entfernen 🥉
```javascript
// NUR EINMAL ausführen, nicht zweimal!
setTimeout(executeLogin, 500);
// setTimeout(executeLogin, 1500); // ← ENTFERNEN!
```

### Option 4: Kein Signal senden (Wie Desktop App) 🏆
```javascript
// Einfach: GAR KEIN Signal
// Flutter wartet einfach bis WebView fertig ist
span.click();
// Kein callHandler!
```

---

## Empfehlung

**Kombination aus Option 1 + 3:**

1. **Entferne zweite Ausführung** (verhindert Race Conditions)
2. **Erhöhe Wartezeit auf 3000ms** (wie WebUntis 2000ms, aber mehr wegen Angular)
3. **Optional:** Prüfe auf erfolgreiche Navigation (z.B. Dashboard-Element sichtbar?)

```javascript
// Optimierter schul.cloud Workflow:
async function fillPasswordAndLogin() {
  // ... password und checkbox Code ...
  
  span.click(); // Login absenden
  
  // LÄNGER WARTEN (wie WebUntis)
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Optional: Prüfen ob eingeloggt
  const dashboard = document.querySelector('.dashboard, .main-content, .user-menu');
  if (dashboard) {
    console.log('schul.cloud: Login successful, dashboard visible');
  }
  
  // Dann Signal
  window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
}

// NUR EINMAL ausführen:
setTimeout(executeLogin, 500); // Nur dieser!
```

---

## Zusammenfassung

| Aspekt | Moodle | WebUntis | schul.cloud |
|--------|--------|----------|-------------|
| **Komplexität** | Einfach | Mittel | Hoch |
| **Phasen** | 1 | 1 | 2 |
| **Wartezeit nach Submit** | 0ms | **2000ms** ✅ | **1000ms** ⚠️ |
| **Multiple Executions** | Nein | Nein | **Ja** ⚠️ |
| **Signal an Flutter** | Nein | Nein | **Ja** ⚠️ |
| **Session-Save Check** | N/A | Nein | **Debug only** ⚠️ |

**Hauptprobleme:**
1. ⚠️ Zu kurze Wartezeit (1s vs. 2s bei WebUntis)
2. ⚠️ Multiple Executions (Race Condition)
3. ⚠️ Frühes Flutter-Signal (könnte WebView beeinflussen)

**Empfehlung:**
- Wartezeit auf 3000ms erhöhen
- Zweite Ausführung entfernen
- Optional: Session-Check implementieren

---

**Datum:** 2025-10-24  
**Version:** 1.0
