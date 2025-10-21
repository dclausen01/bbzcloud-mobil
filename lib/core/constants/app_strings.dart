/// BBZCloud Mobile - String Constants
/// 
/// All user-facing strings and messages
/// 
/// @version 0.1.0

class AppStrings {
  AppStrings._();

  // Error Messages
  static const connectionFailed = 'Die Verbindung ist fehlgeschlagen';
  static const serverNotFound = 'Der Server konnte nicht gefunden werden';
  static const noInternet = 'Keine Internetverbindung';
  static const timeout = 'Die Anfrage hat zu lange gedauert';
  static const credentialsNotFound = 'Bitte richten Sie zuerst Ihre Anmeldedaten ein';
  static const loginFailed = 'Anmeldung fehlgeschlagen';
  static const sessionExpired = 'Ihre Sitzung ist abgelaufen';
  static const databaseError = 'Datenbankfehler aufgetreten';
  static const storageError = 'Speicherfehler aufgetreten';
  static const genericError = 'Ein Fehler ist aufgetreten';
  static const browserOpenFailed = 'Browser konnte nicht geöffnet werden';
  static const urlInvalid = 'Ungültige URL';

  // Success Messages
  static const settingsSaved = 'Einstellungen gespeichert';
  static const credentialsSaved = 'Anmeldedaten gesichert';
  static const logoutSuccess = 'Erfolgreich abgemeldet';
  static const dataSynced = 'Daten synchronisiert';

  // Info Messages
  static const loading = 'Laden...';
  static const saving = 'Speichern...';
  static const connecting = 'Verbinden...';
  static const welcome = 'Willkommen bei BBZCloud';
  static const firstTimeSetup = 'Richten Sie Ihr Konto ein';

  // UI Labels
  static const appTitle = 'BBZCloud Mobile';
  static const home = 'Start';
  static const settings = 'Einstellungen';
  static const todos = 'Aufgaben';
  static const customApps = 'Eigene Apps';
  static const profile = 'Profil';
  static const logout = 'Abmelden';
  static const cancel = 'Abbrechen';
  static const save = 'Speichern';
  static const delete = 'Löschen';
  static const edit = 'Bearbeiten';
  static const add = 'Hinzufügen';
  static const search = 'Suchen';
  static const filter = 'Filtern';
  static const close = 'Schließen';

  // Auth
  static const email = 'E-Mail';
  static const password = 'Passwort';
  static const login = 'Anmelden';
  static const loginHint = 'Mit Ihren BBZ-Zugangsdaten anmelden';

  // Settings
  static const theme = 'Design';
  static const themeLight = 'Hell';
  static const themeDark = 'Dunkel';
  static const themeSystem = 'System';
  static const appearance = 'Darstellung';
  static const account = 'Konto';
  static const about = 'Über';
  static const version = 'Version';

  // Apps
  static const allApps = 'Alle Apps';
  static const favoriteApps = 'Favoriten';
  static const recentApps = 'Zuletzt verwendet';
  static const customAppsTitle = 'Eigene Apps verwalten';
  static const addCustomApp = 'Eigene App hinzufügen';
  static const editApp = 'App bearbeiten';
  static const deleteApp = 'App löschen';
  static const appName = 'Name';
  static const appUrl = 'URL';
  static const appColor = 'Farbe';
  static const appIcon = 'Symbol';

  // Todos
  static const todosTitle = 'Aufgaben';
  static const addTodo = 'Aufgabe hinzufügen';
  static const completedTodos = 'Erledigt';
  static const pendingTodos = 'Offen';
  static const noTodos = 'Keine Aufgaben';
}

/// Storage Keys
class StorageKeys {
  StorageKeys._();

  // User data
  static const userEmail = 'user_email';
  static const userRole = 'user_role';
  static const isFirstLaunch = 'is_first_launch';

  // Settings
  static const theme = 'theme';
  static const appVisibility = 'app_visibility';
  static const favoriteApps = 'favorite_apps';

  // Secure credentials
  static const credentialEmail = 'email';
  static const credentialPassword = 'password';
  static const credentialBbbPassword = 'bbbPassword';
  static const credentialWebuntisEmail = 'webuntisEmail';
  static const credentialWebuntisPassword = 'webuntisPassword';
}
