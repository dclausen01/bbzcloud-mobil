# stashcat-chat – Mobile-Integration Spec

Dieser Auftrag passt das Repo **`dclausen01/stashcat-chat`** so an, dass es als
WebView-Frontend in der nativen Flutter-App **`bbzcloud-mobil`** läuft. Das
Backend wird zentral auf `https://chat.bbz-rd-eck.com` (Ubuntu/Plesk, bereits in
Produktion) gehostet.

Bitte alle Arbeiten auf einem Feature-Branch (`feat/mobile-bridge`) entwickeln
und am Ende einen PR gegen `main` öffnen.

---

## 1. Aktivierungs-Modus „mobile bridge“

* Wird `?bridge=mobile` als Query-Parameter mitgegeben (oder
  `localStorage.bbz_bridge === 'mobile'`), soll sich der Client in einen
  Mobile-Modus schalten.
* Persistiere die Erkennung über `localStorage` und `<html data-bridge="mobile">`
  damit Tailwind-Styles darauf reagieren können.
* Im Mobile-Modus:
  * **Service-Worker / PWA-Caching deaktivieren** (`vite-plugin-pwa`
    registriert keinen SW; bestehenden SW über `navigator.serviceWorker
    .getRegistrations()` deregistrieren).
  * **Desktop-Notifications deaktivieren** (kein
    `Notification.requestPermission()`, kein `new Notification(...)`).
    Anzeige läuft komplett über Flutter.
  * **Favicon-Badge weiterhin setzen**, parallel aber die Unread-Zahl via
    Bridge an Flutter melden.
  * `viewport-fit=cover` im `<head>`, alle fixed Bottom-Bars mit
    `padding-bottom: env(safe-area-inset-bottom)`.
  * Tiptap-Toolbar einklappbar (Default eingeklappt), Emoji-Picker als
    Bottom-Sheet (full-width, sticky am Bildschirmrand).

## 2. Flutter ⇄ JS Bridge

Eine kleine Schicht `src/lib/flutterBridge.ts` mit Fallbacks für den Desktop:

```ts
type BridgePayload = Record<string, unknown> | string | number | null;

const isMobileBridge = () => /* siehe oben */;

function call<T = void>(handler: string, payload?: BridgePayload): Promise<T> {
  const w = window as any;
  const inAppWebView = w.flutter_inappwebview;
  if (!inAppWebView?.callHandler) return Promise.resolve(undefined as T);
  return inAppWebView.callHandler(handler, payload);
}

// Outgoing (Chat → Flutter)
export const bridge = {
  ready: (info: { user?: string; locale?: string }) => call('bridgeReady', info),
  unread: (n: number) => call('unread', n),
  notify: (n: { title: string; body: string; deeplink?: string }) =>
    call('notify', n),
  openExternal: (url: string) => call('openExternal', url),
  pickFiles: () => call<string[]>('pickFiles'),     // optional, Phase 4
  logout: () => call('logout'),
  jitsi: (url: string) => call('jitsi', url),       // siehe §6
  setBadge: (n: number) => call('setBadge', n),     // iOS app icon badge
};

// Incoming (Flutter → Chat)
declare global {
  interface Window {
    bbzChat?: {
      setTheme(mode: 'light' | 'dark'): void;
      setToken(token: string): void;
      navigate(path: string): void;
      reload(): void;
    };
  }
}
```

`window.bbzChat` wird im Mobile-Modus beim App-Start registriert und ruft
intern den existierenden Router (`react-router-dom`), Theme-Provider und Auth-
Store. **Bitte sicherstellen, dass `navigate` `react-router` benutzt, nicht
`window.location` – sonst bricht der State.**

Unread-Zahl: jedes Mal wenn der Store/Selector für Gesamt-Unread sich ändert,
`bridge.unread(n)` aufrufen.

## 3. Server-side Login & Token-Injection

Damit der Nutzer in der Mobile-App nur einmal Email/Passwort eingibt:

* **Neuer Endpoint** `POST /api/auth/mobile-login`
  * Body: `{ email, password }`
  * Verhalten wie der bestehende Login, gibt aber zusätzlich ein
    `mobileToken` (Opaque, 32 Byte) zurück, das serverseitig auf die Session
    gemapped wird (TTL 30 Tage, sliding).
  * Response: `{ mobileToken, user: { id, name, email } }`
* **Neuer Endpoint** `POST /api/auth/mobile-session`
  * Header `Authorization: Bearer <mobileToken>`
  * Stellt die Session wieder her und gibt das normale Session-Cookie zurück
    (Set-Cookie mit `SameSite=None; Secure; HttpOnly`).
  * Wird vom Frontend beim Bridge-Boot automatisch aufgerufen, wenn
    `window.bbzChat.setToken(token)` aufgerufen wurde, **bevor** der Chat
    seine Auth-Initialisierung macht.
* **Neuer Endpoint** `POST /api/auth/mobile-logout`
  * Invalidiert den `mobileToken`.

## 4. Push-Backend (FCM + APNs via FCM HTTP v1)

Neues Modul `server/push/` mit drei Bausteinen:

### 4.1 Token-Registry
* Tabelle bzw. JSON-Store `.push-tokens.json` (AES-256-GCM wie Sessions
  verschlüsselt), Felder: `userId`, `token`, `platform` (`android|ios`),
  `appVersion`, `locale`, `createdAt`, `lastSeenAt`.
* Endpoints:
  * `POST /api/push-tokens` (auth required) → upsert
  * `DELETE /api/push-tokens/:token` (auth required) → remove
  * `GET /api/push-tokens` (auth required) → Liste der eigenen Tokens
    (für „Geräte verwalten" UI später).

### 4.2 Event-Dispatcher
* Beim Start abonniert der Server den existierenden Socket.io-Bridge-Stream
  des `StashcatClient` (er hat schon einen Live-Channel für neue
  Nachrichten/Reactions/Poll-Updates).
* Bei jedem neuen Event für einen User:
  * Lade alle aktiven Push-Tokens des Users.
  * Erzeuge plattformspezifische Payload (siehe unten) und sende via FCM HTTP
    v1 (Service-Account-Key in `FCM_SERVICE_ACCOUNT` Env, JSON-Path).
* Rate-Limiting: pro User max. 1 Push pro 2 s (Coalescing, restliche Inhalte
  als „N neue Nachrichten in X").

### 4.3 Payload-Format

**Android (FCM, data-only, damit Flutter lokal das Banner rendert):**
```json
{
  "message": {
    "token": "<fcm-token>",
    "android": { "priority": "HIGH" },
    "data": {
      "type": "message",
      "channelId": "...",
      "channelName": "...",
      "senderName": "...",
      "preview": "...",
      "deeplink": "/c/<channelId>",
      "msgId": "...",
      "unreadCount": "5"
    }
  }
}
```

**iOS (APNs via FCM, `notification` + `apns-priority: 10`,
`mutable-content: 1`, `sound: default`):**
```json
{
  "message": {
    "token": "<fcm-token>",
    "notification": { "title": "Anna (#5b)", "body": "Hi, …" },
    "apns": {
      "headers": { "apns-priority": "10" },
      "payload": {
        "aps": { "mutable-content": 1, "sound": "default", "badge": 5 }
      }
    },
    "data": {
      "deeplink": "/c/<channelId>",
      "msgId": "...",
      "channelId": "..."
    }
  }
}
```

Bei Plattform = ios → Variante 2, sonst Variante 1. Beide enthalten
`deeplink`, damit Flutter den Tap routen kann.

### 4.4 Konfiguration
* Neue Env-Variablen in `.env.example`:
  * `FCM_SERVICE_ACCOUNT=/etc/bbzchat/firebase-admin.json`
  * `PUSH_ENABLED=true`
  * `PUSH_BATCH_MS=2000`
* `firebase-admin` als Dependency hinzufügen.
* Logging via `pino` (oder bestehender Logger), Fehler in `.push-errors.log`.

## 5. Datei-Uploads / Downloads vom Mobile-WebView

* `flutter_inappwebview` kann normale `<input type=file>` und Drag-and-Drop
  nicht. Stattdessen:
  * Für **Upload**: ein „Anhang"-Button schickt `bridge.pickFiles()`, Flutter
    öffnet `file_picker` und ruft `window.bbzChat.attachFiles(['file://…'])`.
    Phase 4. Für Phase 1–3 reicht es, wenn der `<input type=file>` durch
    `flutter_inappwebview`'s `onFileSelectionRequest`/Permission-Handler
    funktioniert – dafür im Frontend nichts ändern.
  * Für **Download**: keine `window.open(blobUrl)`-Pattern verwenden, sondern
    direkte `<a href="…/download/<id>" download>`-Links – die werden vom
    Flutter-Layer (`download_service.dart`) abgefangen und nativ
    heruntergeladen. Bestehende Download-Endpoints behalten, `Content-
    Disposition: attachment; filename="…"` sicherstellen.
  * Große Downloads (>50 MB): Server muss Range-Requests unterstützen
    (`Accept-Ranges: bytes`).

## 6. Jitsi / Video-Calls

Im Mobile-Modus **nicht inline starten**:
* Wenn ein Jitsi-Call gestartet wird, statt iframe-Einbettung
  `bridge.jitsi(jitsiUrl)` aufrufen.
* Flutter öffnet entweder die native Jitsi-Meet-App (URL-Scheme
  `org.jitsi.meet://...`) oder einen externen Browser. Kein Mic/Cam-Permission-
  Bedarf im WebView.
* Im Desktop-Modus bleibt das bisherige Verhalten unverändert.

## 7. UI-Anpassungen für Mobile (Tailwind)

* `data-bridge="mobile"` als CSS-Variant nutzen (über
  `@variant mobile (&:where([data-bridge=mobile] *))` in Tailwind 4).
* Channel-Liste: full-screen Drawer, schwenkt rüber, wenn ein Channel geöffnet
  wird.
* Composer: oben Channel-Header (sticky), unten Composer (sticky mit
  safe-area-Padding), dazwischen Nachrichtenliste (scroll-bottom-anchored).
* Reaktionen, Poll-Erstellung, Datei-Browser: Bottom-Sheets statt Modals.
* Touch-Targets ≥ 44 px.
* Long-press auf Nachricht → Reaktions-Menü (statt Hover).
* Kein eigenes Theme-Toggle in der App-Bar – kommt aus Flutter via
  `window.bbzChat.setTheme()`.

## 8. DSGVO / Datenschutz

* `docs/PRIVACY.md` im Chat-Repo ergänzen: Welche Daten (Token, IDs,
  Nachrichten-Krypto-Schlüssel) der Push-Server verarbeitet, Speicherort,
  Löschfristen.
* `DELETE /api/push-tokens` muss vom Mobile-Logout zwingend aufgerufen werden
  (Verantwortung liegt bei Flutter, hier nur dokumentieren).
* Push-Inhalte (Body) **müssen serverseitig auf User-Setting prüfen**: Wenn
  der User „Nur Hinweis ohne Inhalt" gewählt hat (neuer Toggle in den
  Account-Settings), nur `title: "Neue Nachricht"`, kein `body`.

## 9. Tests / Abnahme

* Vitest-Test für `flutterBridge.ts` (Browser-Fallback).
* Manuell auf `https://chat.bbz-rd-eck.com/?bridge=mobile` in Mobile-Safari
  und Chrome-Mobile durchklicken: Login, Channel öffnen, Nachricht schicken,
  Datei senden, Datei herunterladen.
* Lighthouse Mobile (Performance ≥ 80, A11y ≥ 90).
* Push-Smoke-Test: `curl` an `/api/push-tokens` (mit Bearer), Test-Nachricht
  via Stashcat-Web → Bridge muss FCM-Aufruf im Server-Log zeigen.

## 10. Definition of Done

- [ ] `?bridge=mobile` schaltet alle in §1 genannten Verhalten um.
- [ ] `bridge.*`-Aufrufe und `window.bbzChat.*` API funktionieren samt
      Fallback im Desktop-Browser.
- [ ] `/api/auth/mobile-login`, `/api/auth/mobile-session`,
      `/api/auth/mobile-logout` funktionieren.
- [ ] `/api/push-tokens` (POST/DELETE/GET) funktionieren.
- [ ] Push-Dispatcher verschickt korrekte FCM-Payloads (Android + iOS).
- [ ] Jitsi-Links lösen `bridge.jitsi()` aus.
- [ ] DSGVO-Toggle „nur Hinweis ohne Inhalt" wirkt im Push-Body.
- [ ] README + `.env.example` aktualisiert, kurzer Abschnitt
      „Mobile-Bridge" in der Doku.
- [ ] PR-Beschreibung erklärt Deploy-Schritte (npm install, ENV,
      Service-Restart, Firebase-Service-Account-Datei).
