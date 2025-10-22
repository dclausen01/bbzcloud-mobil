/// BBZCloud Mobile - Injection Scripts
/// 
/// App-specific JavaScript injection for credential auto-fill and custom behaviors
/// 
/// @version 1.0.0

/// Injection script configuration
class InjectionScript {
  final String js;
  final int delay;
  final String description;

  const InjectionScript({
    required this.js,
    this.delay = 0,
    required this.description,
  });
}

/// App-specific injection scripts
class InjectionScripts {
  InjectionScripts._();

  /// Moodle-specific credential injection
  static String getMoodleInjection(String email, String password) {
    return '''
      (function() {
        try {
          // Find and fill username field
          const usernameField = document.querySelector('input[name="username"][id="username"]');
          if (usernameField && usernameField.value === '') {
            usernameField.value = "${email.toLowerCase()}";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[name="password"][id="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Auto-click login button
          const loginButton = document.querySelector('button[type="submit"][id="loginbtn"]');
          if (loginButton && usernameField && passwordField && usernameField.value && passwordField.value) {
            setTimeout(() => {
              loginButton.click();
            }, 300);
          }
        } catch (error) {
          console.error('Moodle injection error:', error);
        }
      })();
    ''';
  }

  /// WebUntis-specific injection - Phase 1: Close "Im Browser öffnen" dialog BEFORE login
  static const InjectionScript webuntisPhase1Injection = InjectionScript(
    js: '''
      (function() {
        function closeInitialDialog() {
          try {
            // Close "Im Browser öffnen" dialog
            const links = document.querySelectorAll('a, button');
            for (const link of links) {
              if (link.textContent && (
                link.textContent.includes('Im Browser öffnen') ||
                link.textContent.includes('Open in browser')
              )) {
                console.log('WebUntis Phase 1: Clicking "Im Browser öffnen" button');
                link.click();
                return true;
              }
            }
          } catch (error) {
            console.error('WebUntis Phase 1 error:', error);
          }
          return false;
        }
        
        // Try immediately
        if (!closeInitialDialog()) {
          // Try again after short delay if not found
          setTimeout(closeInitialDialog, 500);
        }
      })();
    ''',
    delay: 500,
    description: 'Phase 1: Close initial WebUntis dialog',
  );

  /// WebUntis-specific injection - Phase 2: Close overlay "X" AFTER login
  static const InjectionScript webuntisPhase2Injection = InjectionScript(
    js: '''
      (function() {
        function closeOverlay() {
          try {
            console.log('WebUntis Phase 2: Attempting to close overlay');
            
            // Find and click close buttons (X button)
            const closeButtons = document.querySelectorAll(
              'button[class*="close"], button[aria-label*="close"], button[aria-label*="Close"], ' +
              '[class*="close-button"], [class*="closeButton"], ' +
              'button:has(svg[class*="close"]), button:has([class*="icon-close"])'
            );
            
            for (const button of closeButtons) {
              const parent = button.closest('[role="dialog"], [class*="modal"], [class*="overlay"], [class*="banner"]');
              if (parent && window.getComputedStyle(parent).display !== 'none') {
                console.log('WebUntis Phase 2: Clicking close button (X)');
                button.click();
                return true;
              }
            }
            
            // Also try to remove any overlay backdrops
            const overlays = document.querySelectorAll('[class*="overlay"], [class*="backdrop"], [class*="mask"]');
            for (const overlay of overlays) {
              const style = window.getComputedStyle(overlay);
              if (style.display !== 'none' && style.visibility !== 'hidden') {
                console.log('WebUntis Phase 2: Hiding overlay backdrop');
                overlay.style.display = 'none';
                return true;
              }
            }
          } catch (error) {
            console.error('WebUntis Phase 2 error:', error);
          }
          return false;
        }
        
        // Wait a bit for login to process, then close overlay
        setTimeout(() => {
          if (!closeOverlay()) {
            // Try again if not successful
            setTimeout(closeOverlay, 1000);
            setTimeout(closeOverlay, 2000);
          }
        }, 1500);
      })();
    ''',
    delay: 0,
    description: 'Phase 2: Close overlay after login',
  );

  /// WebUntis credential injection with Phase 2 overlay close
  static String getWebuntisInjection(String email, String password) {
    return '''
      (function() {
        try {
          console.log('WebUntis: Starting credential injection');
          
          // Find and fill username field
          const usernameField = document.querySelector('input[type="text"][name="school"], input[id*="username"], input[id*="user"]');
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$email";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('WebUntis: Username filled');
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('WebUntis: Password filled');
          }
          
          // Auto-click login button if both fields are filled
          if (usernameField && passwordField && usernameField.value && passwordField.value) {
            const loginButton = document.querySelector('button[type="submit"], button[id*="login"], input[type="submit"]');
            if (loginButton) {
              setTimeout(() => {
                console.log('WebUntis: Clicking login button');
                loginButton.click();
                
                // Schedule Phase 2: Close overlay after login completes
                ${webuntisPhase2Injection.js}
              }, 300);
            }
          }
        } catch (error) {
          console.error('WebUntis injection error:', error);
        }
      })();
    ''';
  }

  /// Schul.cloud credential injection
  static String getSchulcloudInjection(String email, String password) {
    return '''
      (function() {
        try {
          // Find and fill email field
          const emailField = document.querySelector('input[type="email"], input[name*="email"], input[id*="email"]');
          if (emailField && emailField.value === '') {
            emailField.value = "$email";
            emailField.dispatchEvent(new Event('input', { bubbles: true }));
            emailField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Auto-click login button
          const loginButton = document.querySelector('button[type="submit"], button[class*="login"]');
          if (loginButton && emailField && passwordField && emailField.value && passwordField.value) {
            setTimeout(() => {
              loginButton.click();
            }, 300);
          }
        } catch (error) {
          console.error('Schul.cloud injection error:', error);
        }
      })();
    ''';
  }

  /// BigBlueButton credential injection (uses BBB-specific password if available)
  static String getBBBInjection(String email, String? bbbPassword) {
    final password = bbbPassword ?? '';
    return '''
      (function() {
        try {
          // Find and fill email/username field
          const usernameField = document.querySelector('input[type="text"], input[type="email"], input[name*="name"], input[id*="name"]');
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$email";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Find and fill password field if BBB password is available
          ${password.isNotEmpty ? '''
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          ''' : ''}
        } catch (error) {
          console.error('BBB injection error:', error);
        }
      })();
    ''';
  }

  /// Outlook/Exchange credential injection
  static String getOutlookInjection(String email, String password) {
    return '''
      (function() {
        try {
          // Find and fill email field
          const emailField = document.querySelector('input[type="email"], input[name*="loginfmt"], input[id*="username"]');
          if (emailField && emailField.value === '') {
            emailField.value = "$email";
            emailField.dispatchEvent(new Event('input', { bubbles: true }));
            emailField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[type="password"], input[name*="passwd"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Auto-click submit/next button
          const submitButton = document.querySelector('input[type="submit"], button[type="submit"]');
          if (submitButton) {
            setTimeout(() => {
              submitButton.click();
            }, 300);
          }
        } catch (error) {
          console.error('Outlook injection error:', error);
        }
      })();
    ''';
  }

  /// Generic fallback injection for unknown apps
  static String getGenericInjection(String email, String password) {
    return '''
      (function() {
        try {
          // Find username field (can be email, user, or text input)
          const usernameField = document.querySelector(
            'input[type="text"]:not([type="password"]), input[type="email"], input[name*="email"], input[name*="user"], input[name*="login"], input[id*="email"], input[id*="user"], input[id*="login"]'
          );
          
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$email";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            usernameField.dispatchEvent(new Event('blur', { bubbles: true }));
          }
          
          // Find password field
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$password";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            passwordField.dispatchEvent(new Event('blur', { bubbles: true }));
          }
        } catch (error) {
          console.error('Generic injection error:', error);
        }
      })();
    ''';
  }

  /// Get app-specific injection script
  static String? getInjectionForApp(
    String appId,
    String email,
    String password, {
    String? bbbPassword,
    String? webuntisEmail,
    String? webuntisPassword,
  }) {
    switch (appId.toLowerCase()) {
      case 'moodle':
        return getMoodleInjection(email, password);
      
      case 'webuntis':
        // Use WebUntis-specific credentials if available, otherwise fallback to email
        final untisEmail = webuntisEmail ?? email;
        final untisPassword = webuntisPassword ?? password;
        return getWebuntisInjection(untisEmail, untisPassword);
      
      case 'schulcloud':
        return getSchulcloudInjection(email, password);
      
      case 'bbb':
        return getBBBInjection(email, bbbPassword);
      
      case 'outlook':
        return getOutlookInjection(email, password);
      
      default:
        // Use generic injection for unknown apps
        return getGenericInjection(email, password);
    }
  }

  /// Get post-load script for app (e.g., dialog dismissal)
  /// This runs BEFORE credential injection
  static InjectionScript? getPostLoadScriptForApp(String appId) {
    switch (appId.toLowerCase()) {
      case 'webuntis':
        return webuntisPhase1Injection; // Phase 1: Close "Im Browser öffnen" dialog
      
      default:
        return null;
    }
  }
}
