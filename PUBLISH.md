# 1. Entwickeln & testen
git checkout -b feature/neue-funktion
# ... entwickeln ...
git push origin feature/neue-funktion

# 2. Pull Request erstellen & mergen
# GitHub → Pull Request → Review → Merge to main

# 3. Version erhöhen (auf main)
# pubspec.yaml: Versionsnummer hochzählen

# 4. CHANGELOG aktualisieren
# Änderungen dokumentieren

# 5. Push auf main
git push origin main

# 6. Automatisch:
# → GitHub Actions baut & deployt
# → Play Store erhält neue Version
# → GitHub Release wird erstellt
# → Tester erhalten Update
