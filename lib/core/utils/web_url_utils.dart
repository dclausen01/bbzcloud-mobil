/// BBZCloud Mobile - Web URL Helpers
///
/// Zentrale Stelle fuer UA-/URL-spezifische Sonderbehandlungen, z.B.
/// OnlyOffice: aufmobilen Geraeten wuerde der Server sonst den
/// abgespeckten Mobile-Editor ausliefern - mit Desktop-UA-String
/// bekommen wir die volle Desktop-Variante.

/// Desktop-UA-String (Chrome 120 auf Win 10 x64). Identisch zu dem,
/// den wir schon fuer WebUntis/SchulCloud verwenden.
const String kDesktopUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/120.0.0.0 Safari/537.36';

/// Default-UA fuer die App (mobiler Chrome auf Android 10).
const String kMobileUserAgent =
    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 '
    'BBZCloud/1.0';

/// True, wenn die URL zum OnlyOffice-Editor unter
/// office.bbz-rd-eck.de gehoert. Wir matchen via Host, damit
/// sub-paths egal sind.
bool isOnlyOfficeUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  try {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();
    return host == 'office.bbz-rd-eck.de' ||
        host.endsWith('.office.bbz-rd-eck.de');
  } catch (_) {
    return false;
  }
}
