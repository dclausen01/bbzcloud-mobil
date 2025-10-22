/// BBZCloud Mobile - Injection Scripts
/// 
/// App-specific JavaScript injection for credential auto-fill and custom behaviors
/// 
/// @version 1.1.0

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

  /// Escape string for safe JavaScript injection
  /// Prevents XSS and syntax errors from special characters in credentials
  static String _escapeJs(String value) {
    return value
        .replaceAll('\\', '\\\\')  // Backslash must be first
        .replaceAll('"', '\\"')     // Escape double quotes
        .replaceAll("'", "\\'")     // Escape single quotes
        .replaceAll('\n', '\\n')    // Escape newlines
        .replaceAll('\r', '\\r')    // Escape carriage returns
        .replaceAll('\t', '\\t');   // Escape tabs
  }

  /// Moodle-specific credential injection
  static String getMoodleInjection(String email, String password) {
    final escapedEmail = _escapeJs(email.toLowerCase());
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          // Find and fill username field
          const usernameField = document.querySelector('input[name="username"][id="username"]');
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$escapedEmail";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[name="password"][id="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
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

  /// WebUntis credential injection (Phase 2 will be triggered separately after login)
  static String getWebuntisInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('WebUntis: Starting credential injection');
          
          // Find and fill username field
          const usernameField = document.querySelector('input[type="text"][name="school"], input[id*="username"], input[id*="user"]');
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$escapedEmail";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('WebUntis: Username filled');
          }
          
          // Find and fill password field
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
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
                
                // Phase 2 overlay closing will be handled separately after navigation
                console.log('WebUntis: Phase 2 will be triggered after page load');
              }, 300);
            }
          }
        } catch (error) {
          console.error('WebUntis injection error:', error);
        }
      })();
    ''';
  }

  /// Schul.cloud credential injection with scroll fix
  static String getSchulcloudInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('schul.cloud: Starting credential injection');
          
          // Apply scroll fix
          const style = document.createElement('style');
          style.textContent = `
            [class*="outer-scroller"],
            [class*="navigation-item-wrapper"],
            [class*="channel-list"],
            [class*="chat-list"],
            [class*="conversation-list"],
            [class*="message-list"],
            [class*="sidebar"],
            div[class*="List"],
            div[class*="Sidebar"],
            div[class*="scroller"] {
              overflow-y: auto !important;
              overflow-x: hidden !important;
              -webkit-overflow-scrolling: touch !important;
              overscroll-behavior: contain !important;
              touch-action: pan-y !important;
            }
          `;
          document.head.appendChild(style);
          console.log('schul.cloud: Scroll fix applied');
          
          // Wait for Angular to load
          function attemptFill() {
            // Try multiple selectors for email field (schul.cloud uses material design)
            const emailSelectors = [
              'input[type="email"]',
              'input[name="email"]',
              'input[name="username"]',
              'input[formcontrolname="email"]',
              'input[formcontrolname="username"]',
              'input[placeholder*="mail" i]',
              'input[placeholder*="benutzername" i]',
              'input[id*="email"]',
              'input[id*="username"]',
              'mat-form-field input[type="email"]',
              'mat-form-field input:not([type="password"])'
            ];
            
            let emailField = null;
            for (const selector of emailSelectors) {
              emailField = document.querySelector(selector);
              if (emailField && emailField.offsetParent !== null) {
                break;
              }
            }
            
            if (emailField && emailField.value === '') {
              emailField.value = "$escapedEmail";
              emailField.dispatchEvent(new Event('input', { bubbles: true }));
              emailField.dispatchEvent(new Event('change', { bubbles: true }));
              emailField.dispatchEvent(new Event('blur', { bubbles: true }));
              // Trigger Angular events
              emailField.dispatchEvent(new Event('ngModelChange', { bubbles: true }));
              console.log('schul.cloud: Email filled');
            }
            
            // Find and fill password field
            const passwordSelectors = [
              'input[type="password"]',
              'input[formcontrolname="password"]',
              'mat-form-field input[type="password"]'
            ];
            
            let passwordField = null;
            for (const selector of passwordSelectors) {
              passwordField = document.querySelector(selector);
              if (passwordField && passwordField.offsetParent !== null) {
                break;
              }
            }
            
            if (passwordField && passwordField.value === '') {
              passwordField.value = "$escapedPassword";
              passwordField.dispatchEvent(new Event('input', { bubbles: true }));
              passwordField.dispatchEvent(new Event('change', { bubbles: true }));
              passwordField.dispatchEvent(new Event('blur', { bubbles: true }));
              // Trigger Angular events
              passwordField.dispatchEvent(new Event('ngModelChange', { bubbles: true }));
              console.log('schul.cloud: Password filled');
            }
            
            // Auto-click login button if both fields are filled
            if (emailField && passwordField && emailField.value && passwordField.value) {
              const buttonSelectors = [
                'button[type="submit"]',
                'button[class*="login" i]',
                'button[class*="submit" i]',
                'button[class*="anmelden" i]',
                'button mat-button[type="submit"]',
                'input[type="submit"]'
              ];
              
              let loginButton = null;
              for (const selector of buttonSelectors) {
                loginButton = document.querySelector(selector);
                if (loginButton && loginButton.offsetParent !== null) {
                  break;
                }
              }
              
              if (loginButton) {
                setTimeout(() => {
                  console.log('schul.cloud: Clicking login button');
                  loginButton.click();
                }, 500);
              }
            }
          }
          
          // Try immediately
          attemptFill();
          
          // Retry after delays (for Angular/SPA)
          setTimeout(attemptFill, 1000);
          setTimeout(attemptFill, 2000);
          
        } catch (error) {
          console.error('Schul.cloud injection error:', error);
        }
      })();
    ''';
  }

  /// BigBlueButton credential injection (uses BBB-specific password if available)
  static String getBBBInjection(String email, String? bbbPassword) {
    final escapedEmail = _escapeJs(email);
    final password = bbbPassword ?? '';
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('BBB: Starting credential injection');
          
          // Find and fill email/username field
          const usernameSelectors = [
            'input[type="text"]',
            'input[type="email"]',
            'input[name*="name"]',
            'input[id*="name"]',
            'input[placeholder*="name" i]'
          ];
          
          let usernameField = null;
          for (const selector of usernameSelectors) {
            usernameField = document.querySelector(selector);
            if (usernameField && usernameField.offsetParent !== null) {
              break;
            }
          }
          
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$escapedEmail";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('BBB: Username filled');
          }
          
          // Find and fill password field if BBB password is available
          ${password.isNotEmpty ? '''
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('BBB: Password filled');
          }
          
          // Auto-click join/login button
          if (usernameField && passwordField && usernameField.value && passwordField.value) {
            const buttonSelectors = [
              'button[type="submit"]',
              'button[class*="join" i]',
              'button[class*="login" i]',
              'button[aria-label*="join" i]',
              'input[type="submit"]'
            ];
            
            let submitButton = null;
            for (const selector of buttonSelectors) {
              submitButton = document.querySelector(selector);
              if (submitButton && submitButton.offsetParent !== null) {
                break;
              }
            }
            
            if (submitButton) {
              setTimeout(() => {
                console.log('BBB: Clicking submit button');
                submitButton.click();
              }, 300);
            }
          }
          ''' : '''
          // No password, just click join button if username is filled
          if (usernameField && usernameField.value) {
            const buttonSelectors = [
              'button[type="submit"]',
              'button[class*="join" i]',
              'button[aria-label*="join" i]',
              'input[type="submit"]'
            ];
            
            let submitButton = null;
            for (const selector of buttonSelectors) {
              submitButton = document.querySelector(selector);
              if (submitButton && submitButton.offsetParent !== null) {
                break;
              }
            }
            
            if (submitButton) {
              setTimeout(() => {
                console.log('BBB: Clicking join button');
                submitButton.click();
              }, 300);
            }
          }
          '''}
        } catch (error) {
          console.error('BBB injection error:', error);
        }
      })();
    ''';
  }

  /// Outlook/Exchange credential injection with improved button detection
  static String getOutlookInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('Outlook: Starting credential injection');
          
          // Find and fill email field
          const emailSelectors = [
            'input[type="email"]',
            'input[name*="loginfmt"]',
            'input[id*="username"]',
            'input[name="username"]'
          ];
          
          let emailField = null;
          for (const selector of emailSelectors) {
            emailField = document.querySelector(selector);
            if (emailField && emailField.offsetParent !== null) {
              break;
            }
          }
          
          if (emailField && emailField.value === '') {
            emailField.value = "$escapedEmail";
            emailField.dispatchEvent(new Event('input', { bubbles: true }));
            emailField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('Outlook: Email filled');
          }
          
          // Find and fill password field
          const passwordSelectors = [
            'input[type="password"]',
            'input[name*="passwd"]',
            'input[name="password"]'
          ];
          
          let passwordField = null;
          for (const selector of passwordSelectors) {
            passwordField = document.querySelector(selector);
            if (passwordField && passwordField.offsetParent !== null) {
              break;
            }
          }
          
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            console.log('Outlook: Password filled');
          }
          
          // Auto-click submit/next button with improved detection
          const buttonSelectors = [
            'input[type="submit"]',
            'button[type="submit"]',
            'input[id*="submit"]',
            'button[id*="submit"]',
            'input[value*="Sign in"]',
            'input[value*="Anmelden"]',
            'button[class*="submit"]'
          ];
          
          let submitButton = null;
          for (const selector of buttonSelectors) {
            submitButton = document.querySelector(selector);
            if (submitButton && submitButton.offsetParent !== null) {
              break;
            }
          }
          
          if (submitButton && (emailField || passwordField)) {
            setTimeout(() => {
              console.log('Outlook: Clicking submit button');
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
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          // Find username field (can be email, user, or text input)
          const usernameField = document.querySelector(
            'input[type="text"], input[type="email"], input[name*="email"], input[name*="user"], input[name*="login"], input[id*="email"], input[id*="user"], input[id*="login"]'
          );
          
          if (usernameField && usernameField.value === '') {
            usernameField.value = "$escapedEmail";
            usernameField.dispatchEvent(new Event('input', { bubbles: true }));
            usernameField.dispatchEvent(new Event('change', { bubbles: true }));
            usernameField.dispatchEvent(new Event('blur', { bubbles: true }));
          }
          
          // Find password field
          const passwordField = document.querySelector('input[type="password"]');
          if (passwordField && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
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
