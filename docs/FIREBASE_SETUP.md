# Firebase / Push-Notifications Setup

Dieses Dokument führt durch die einmalige Einrichtung von Firebase Cloud
Messaging (FCM) für BBZCloud Mobile. Ergebnis: zwei Plattform-Konfigurationen
(`google-services.json` für Android, `GoogleService-Info.plist` für iOS) im
App-Repo und eine `firebase-admin.json` auf dem Chat-Server.

Bestehende Bundle-IDs:
* **Android:** `com.bbzcloud.bbzcloud_mobil`
* **iOS:**     `com.bbzcloud.bbzcloudMobil` *(Wert aus `ios/Runner.xcodeproj`
   prüfen, ggf. anpassen)*

---

## 1. Firebase-Projekt erstellen

1. <https://console.firebase.google.com> öffnen, mit dem BBZ-Google-Account
   einloggen.
2. **„Projekt hinzufügen"** → Name z.B. `bbzcloud-mobil`.
3. Google Analytics: **deaktivieren** (für Push nicht nötig, weniger
   DSGVO-Aufwand).
4. „Projekt erstellen" → 30 s warten.

## 2. Android-App im Projekt anlegen

1. In der Konsole „App hinzufügen" → Android-Icon.
2. **Paketname:** `com.bbzcloud.bbzcloud_mobil`
3. App-Spitzname: `BBZCloud Mobile (Android)`
4. Debug-Signing-SHA-1: zunächst leer lassen, später nachpflegen für
   App-Check (optional).
5. **`google-services.json` herunterladen** → ablegen unter:
   ```
   android/app/google-services.json
   ```
6. In `android/build.gradle.kts` (oder `android/build.gradle`):
   ```kotlin
   plugins {
       // ...
       id("com.google.gms.google-services") version "4.4.2" apply false
   }
   ```
7. In `android/app/build.gradle.kts` am Ende:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```
8. **Wichtig:** `google-services.json` per `.gitignore` aus dem Repo
   raushalten und in CI als GitHub-Secret hinterlegen (`GOOGLE_SERVICES_JSON`,
   base64-encoded; in der Build-Action vor `flutter build` mit
   `echo "$GOOGLE_SERVICES_JSON" | base64 -d > android/app/google-services.json`
   herstellen). Siehe `docs/GITHUB_SECRETS.md`.

## 3. iOS-App im Projekt anlegen

1. Konsole → „App hinzufügen" → iOS-Icon.
2. **Bundle-ID:** Wert aus Xcode bzw. `ios/Runner.xcodeproj`
   (`PRODUCT_BUNDLE_IDENTIFIER`) verwenden. Bei Bedarf anpassen.
3. **`GoogleService-Info.plist` herunterladen** → in Xcode in das
   `Runner`-Target ziehen (NICHT nur in den Ordner kopieren – Drag&Drop in
   Xcode mit „Copy if needed" + Target = Runner).
4. Ablage im Repo:
   ```
   ios/Runner/GoogleService-Info.plist
   ```
   Genauso aus dem Repo heraushalten und über CI-Secret
   (`GOOGLESERVICE_INFO_PLIST`, base64) bereitstellen.

## 4. APNs-Schlüssel für iOS

iOS pusht nicht über FCM-Schlüssel allein, sondern braucht einen APNs-Key.

1. <https://developer.apple.com/account/resources/authkeys/list> öffnen
   (Apple-Developer-Account des BBZ).
2. **Keys → +** → Name `BBZ FCM`, Häkchen bei **Apple Push Notifications
   service (APNs)** → „Continue" → „Register".
3. **`AuthKey_XXXXXXXXXX.p8`** herunterladen (geht **nur einmal**, sicher in
   Bitwarden/1Password ablegen).
4. Key-ID und Team-ID notieren (Team-ID steht oben rechts im Apple-Dev-Portal).
5. Zurück in Firebase: **Projekt-Einstellungen → Cloud Messaging → Apple App
   konfigurieren** → APNs-Auth-Key + Key-ID + Team-ID hochladen.

## 5. Service-Account für den Push-Server

Der `stashcat-chat`-Server (`chat.bbz-rd-eck.com`) sendet via FCM HTTP v1 und
braucht einen Service-Account-Key.

1. Firebase-Konsole → **Projekt-Einstellungen → Dienstkonten**.
2. „Neuen privaten Schlüssel generieren" → JSON-Datei herunterladen.
3. Auf dem Chat-Server ablegen, **nicht** ins Git:
   ```
   /etc/bbzchat/firebase-admin.json   # chmod 600, owner = node-user
   ```
4. In der `.env` des stashcat-chat-Servers:
   ```
   FCM_SERVICE_ACCOUNT=/etc/bbzchat/firebase-admin.json
   PUSH_ENABLED=true
   ```
5. Service-Restart: `pm2 restart stashcat-chat` (bzw. systemd-Unit).

## 6. iOS-Project-Settings (Xcode)

In `ios/Runner.xcworkspace` öffnen, Target **Runner** auswählen:

1. **Signing & Capabilities → + Capability → Push Notifications**.
2. **+ Capability → Background Modes** → Häkchen bei
   **„Remote notifications"**.
3. `ios/Runner/Info.plist`: einen freundlichen Usage-String für
   `NSUserNotificationsUsageDescription` (Push erklären) ergänzen:
   ```xml
   <key>NSUserNotificationsUsageDescription</key>
   <string>Damit du neue Chat-Nachrichten erhältst, wenn die App geschlossen ist.</string>
   ```
4. Provisioning-Profile (Distribution + Development) im Apple-Dev-Portal
   müssen die Push-Notifications-Entitlement enthalten – nach Schritt 1 neu
   generieren und in Xcode neu laden.

## 7. Android-Manifest

In `android/app/src/main/AndroidManifest.xml` innerhalb von `<application>`:

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="bbz_chat_messages" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_stat_notify" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

`ic_stat_notify` als monochromes 24 dp Vektor-Drawable hinterlegen
(weiß auf transparent – sonst zeigt Android ab API 23 nur einen weißen
Punkt). Tool: <https://romannurik.github.io/AndroidAssetStudio/icons-notification.html>.

`colors.xml` ergänzen:
```xml
<color name="notification_color">#3880FF</color>
```

## 8. Dart-Setup (kommt in Phase 3, hier zur Vollständigkeit)

`pubspec.yaml`:
```yaml
firebase_core: ^3.6.0
firebase_messaging: ^15.1.3
flutter_local_notifications: ^17.2.3
```

In Phase 3 erstellen wir `lib/services/push_service.dart` und initialisieren
Firebase in `main.dart` via:
```dart
await Firebase.initializeApp();
await PushService.instance.init();
```

## 9. Akzeptanztest (nach Schritt 1–7)

1. App auf einem echten Gerät (iOS & Android) installieren.
2. Onboarding durchlaufen → die App soll Push-Permission anfragen (Phase 3).
3. In der Firebase-Konsole **Cloud Messaging → Senden** → Test-Push an die
   Geräte-Token-ID schicken.
4. Banner muss erscheinen (Foreground via flutter_local_notifications,
   Background nativ).
5. Auf den Push tippen → App öffnet, in der Bridge kommt `deeplink` an.
6. Test-Push vom `stashcat-chat`-Server via echtem Chat: ein anderer User
   schreibt eine Nachricht → Push muss innerhalb von 2 s ankommen.

## 10. Häufige Stolperfallen

| Symptom | Ursache | Fix |
|---|---|---|
| Push kommt auf Android, aber nicht iOS | APNs-Key fehlt oder Bundle-ID falsch im FCM-Projekt | Schritt 4 wiederholen |
| Push nur bei offener App | iOS-Background-Mode „Remote notifications" nicht aktiv | Schritt 6.2 prüfen |
| `data`-only Push wird auf Android nicht angezeigt | erwartet: `flutter_local_notifications` rendert in `onMessage` | Phase-3-Code prüfen |
| Token wechselt ständig | App deinstalliert + neu installiert oder Datenlöschung | normal, Server muss `onTokenRefresh` immer respektieren |
| Server kann nicht senden („Requested entity was not found") | Token expired/invalid | Push-Server muss bei 404/`UNREGISTERED` den Token aus der Registry löschen |
