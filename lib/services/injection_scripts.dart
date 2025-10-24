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

  /// WebUntis-specific injection - Phase 2: Hide mobile banner with CSS
  /// Uses CSS injection (like Desktop-App) - works for current AND future elements!
  static const InjectionScript webuntisPhase2Injection = InjectionScript(
    js: '''
      (function() {
        console.log('WebUntis Phase 2: Starting banner removal');
        console.log('WebUntis Phase 2: Current URL:', window.location.href);
        console.log('WebUntis Phase 2: Document ready state:', document.readyState);
        
        try {
          // DEBUG: Check for existing banners BEFORE injection
          const existingBanners = document.querySelectorAll('div.mobile-banner, .mobile-banner, [class*="mobile-banner"]');
          console.log('WebUntis Phase 2: Found', existingBanners.length, 'existing banner elements');
          existingBanners.forEach((banner, index) => {
            console.log('WebUntis Phase 2: Banner', index, 'classes:', banner.className);
            console.log('WebUntis Phase 2: Banner', index, 'visible:', banner.offsetParent !== null);
          });
          
          // Create style element with CSS rules
          const style = document.createElement('style');
          style.id = 'bbzcloud-webuntis-banner-hide';
          style.textContent = `
            /* Hide WebUntis mobile banner - applies to current and future elements */
            div.mobile-banner,
            .mobile-banner,
            [class*="mobile-banner"],
            [class*="app-banner"],
            [class*="notification-bar"] {
              display: none !important;
              visibility: hidden !important;
              opacity: 0 !important;
              height: 0 !important;
              overflow: hidden !important;
            }
          `;
          
          // Inject into head
          document.head.appendChild(style);
          console.log('WebUntis Phase 2: CSS injected successfully with ID:', style.id);
          console.log('WebUntis Phase 2: Total <style> elements in head:', document.head.querySelectorAll('style').length);
          
          // DEBUG: Check if banners are still visible AFTER injection
          setTimeout(() => {
            const stillVisibleBanners = Array.from(document.querySelectorAll('div.mobile-banner, .mobile-banner, [class*="mobile-banner"]'))
              .filter(b => b.offsetParent !== null);
            console.log('WebUntis Phase 2: Still visible banners after CSS:', stillVisibleBanners.length);
            if (stillVisibleBanners.length > 0) {
              console.error('WebUntis Phase 2: WARNING - Banners still visible despite CSS!');
              stillVisibleBanners.forEach((banner, index) => {
                console.log('WebUntis Phase 2: Visible banner', index, ':', banner.outerHTML.substring(0, 200));
              });
            } else {
              console.log('WebUntis Phase 2: SUCCESS - All banners hidden!');
            }
          }, 500);
          
        } catch (error) {
          console.error('WebUntis Phase 2 error:', error);
          console.error('WebUntis Phase 2 stack:', error.stack);
        }
      })();
    ''',
    delay: 0,
    description: 'Phase 2: Hide mobile banner with CSS injection (Desktop-App method)',
  );

  /// WebUntis-specific injection - Phase 3: Monitor for post-interaction overlays
  static const InjectionScript webuntisPhase3Injection = InjectionScript(
    js: '''
      (function() {
        console.log('WebUntis Phase 3: Starting interaction monitor');
        
        let interactionDetected = false;
        let monitoringActive = true;
        
        // Function to detect and close overlays
        function detectAndCloseOverlay() {
          if (!monitoringActive) return;
          
          try {
            // Look for close buttons that may have appeared
            const closeButtons = document.querySelectorAll(
              'button[class*="close"], button[aria-label*="close"], button[aria-label*="schließen"], ' +
              'button[aria-label*="Close"], [class*="close-button"], [class*="closeButton"], ' +
              'button:has(svg[class*="close"]), button:has([class*="icon-close"]), ' +
              'button[title*="close" i], button[title*="schließen" i], ' +
              '[role="button"]:has(svg[class*="close"])'
            );
            
            for (const button of closeButtons) {
              // Check if button is in a visible modal/dialog/overlay
              const parent = button.closest('[role="dialog"], [role="alertdialog"], [class*="modal"], [class*="overlay"], [class*="dialog"], [class*="popup"]');
              if (parent) {
                const style = window.getComputedStyle(parent);
                if (style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0') {
                  console.log('WebUntis Phase 3: Found and clicking close button after interaction');
                  button.click();
                  
                  // Stop monitoring after successful close
                  setTimeout(() => {
                    monitoringActive = false;
                    console.log('WebUntis Phase 3: Monitoring stopped');
                  }, 1000);
                  
                  return true;
                }
              }
            }
          } catch (error) {
            console.error('WebUntis Phase 3 error:', error);
          }
          return false;
        }
        
        // Listen for user interactions (click, touch, scroll)
        const interactionEvents = ['click', 'touchstart', 'scroll', 'keydown'];
        
        function handleInteraction() {
          if (!interactionDetected) {
            interactionDetected = true;
            console.log('WebUntis Phase 3: User interaction detected, watching for overlays');
            
            // After interaction, periodically check for overlays
            let checkCount = 0;
            const maxChecks = 10;
            
            const intervalId = setInterval(() => {
              checkCount++;
              
              if (detectAndCloseOverlay() || checkCount >= maxChecks || !monitoringActive) {
                clearInterval(intervalId);
                console.log('WebUntis Phase 3: Stopped checking (count: ' + checkCount + ')');
              }
            }, 1000);
          }
        }
        
        // Add event listeners
        interactionEvents.forEach(event => {
          document.addEventListener(event, handleInteraction, { once: false, passive: true });
        });
        
        // Also check periodically in case overlay appears without interaction
        let periodicCheckCount = 0;
        const periodicInterval = setInterval(() => {
          periodicCheckCount++;
          
          if (detectAndCloseOverlay() || periodicCheckCount >= 20 || !monitoringActive) {
            clearInterval(periodicInterval);
          }
        }, 2000);
        
        // Stop monitoring after 60 seconds
        setTimeout(() => {
          monitoringActive = false;
          console.log('WebUntis Phase 3: Monitoring timeout reached');
        }, 60000);
        
        console.log('WebUntis Phase 3: Monitoring active');
      })();
    ''',
    delay: 0,
    description: 'Phase 3: Monitor for overlays after user interaction',
  );

  /// WebUntis credential injection - Using React Fiber Node approach from Electron app
  static String getWebuntisInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (async function() {
        try {
          console.log('WebUntis: Starting credential injection (React Fiber approach)');
          
          // Store credentials as constants
          const USERNAME = "$escapedEmail";
          const PASSWORD = "$escapedPassword";
          
          // Wait for form to be ready
          await new Promise((resolve) => {
            const checkForm = () => {
              const form = document.querySelector('.un2-login-form form');
              if (form) {
                resolve();
              } else {
                setTimeout(checkForm, 100);
              }
            };
            checkForm();
          });

          // Get form elements
          const form = document.querySelector('.un2-login-form form');
          const usernameField = form.querySelector('input[type="text"].un-input-group__input');
          const passwordField = form.querySelector('input[type="password"].un-input-group__input');
          const submitButton = form.querySelector('button[type="submit"]');

          if (!usernameField || !passwordField || !submitButton) {
            console.log('WebUntis: Form elements not found');
            return false;
          }

          // Function to find React fiber node
          const getFiberNode = (element) => {
            const key = Object.keys(element).find(key => 
              key.startsWith('__reactFiber\$') || 
              key.startsWith('__reactInternalInstance\$')
            );
            return element[key];
          };

          // Function to find React props
          const getReactProps = (element) => {
            const fiberNode = getFiberNode(element);
            if (!fiberNode) return null;
            
            let current = fiberNode;
            while (current) {
              if (current.memoizedProps?.onChange) {
                return current.memoizedProps;
              }
              current = current.return;
            }
            return null;
          };

          // Fill username using React onChange
          const usernameProps = getReactProps(usernameField);
          if (usernameProps?.onChange) {
            usernameField.value = USERNAME;
            usernameProps.onChange({
              target: usernameField,
              currentTarget: usernameField,
              type: 'change',
              bubbles: true,
              cancelable: true,
              defaultPrevented: false,
              preventDefault: () => {},
              stopPropagation: () => {},
              isPropagationStopped: () => false,
              persist: () => {}
            });
            console.log('WebUntis: Username filled via React:', USERNAME);
          }

          // Wait a bit before password
          await new Promise(resolve => setTimeout(resolve, 100));

          // Fill password using React onChange
          const passwordProps = getReactProps(passwordField);
          if (passwordProps?.onChange) {
            passwordField.value = PASSWORD;
            passwordProps.onChange({
              target: passwordField,
              currentTarget: passwordField,
              type: 'change',
              bubbles: true,
              cancelable: true,
              defaultPrevented: false,
              preventDefault: () => {},
              stopPropagation: () => {},
              isPropagationStopped: () => false,
              persist: () => {}
            });
            console.log('WebUntis: Password filled via React');
          }

          // Wait for button to become enabled
          await new Promise(resolve => setTimeout(resolve, 500));

          // Submit form if button is enabled
          if (!submitButton.disabled) {
            console.log('WebUntis: Button enabled, submitting form');
            const formProps = getReactProps(form);
            if (formProps?.onSubmit) {
              formProps.onSubmit({
                preventDefault: () => {},
                stopPropagation: () => {},
                target: form,
                currentTarget: form,
                nativeEvent: new Event('submit')
              });
            } else {
              const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
              form.dispatchEvent(submitEvent);
            }

            // Wait 2 seconds then check for authenticator page
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            // Only reload if we're not on the authenticator page
            const authLabel = document.querySelector('.un-input-group__label');
            if (authLabel?.textContent !== 'Bestätigungscode') {
              window.location.reload();
            }
            return true;
          } else {
            console.log('WebUntis: Button still disabled after React onChange');
            return false;
          }
        } catch (error) {
          console.error('WebUntis injection error:', error);
          return false;
        }
      })();
    ''';
  }

  /// Schul.cloud credential injection with precise selectors
  /// Fixed [object Event] issue with multi-set approach
  static String getSchulcloudInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('schul.cloud: Starting credential injection v3.0');
          
          // Apply scroll fix
          const style = document.createElement('style');
          const cssRules = [
            '[class*="outer-scroller"],',
            '[class*="navigation-item-wrapper"],',
            '[class*="channel-list"],',
            '[class*="chat-list"],',
            '[class*="conversation-list"],',
            '[class*="message-list"],',
            '[class*="sidebar"],',
            'div[class*="List"],',
            'div[class*="Sidebar"],',
            'div[class*="scroller"] {',
            '  overflow-y: auto !important;',
            '  overflow-x: hidden !important;',
            '  -webkit-overflow-scrolling: touch !important;',
            '  overscroll-behavior: contain !important;',
            '  touch-action: pan-y !important;',
            '}'
          ];
          style.textContent = cssRules.join(' ');
          document.head.appendChild(style);
          console.log('schul.cloud: Scroll fix applied');
          
          // Store credentials as constants (prevents [object Event] bug)
          const EMAIL_VALUE = "$escapedEmail";
          const PASSWORD_VALUE = "$escapedPassword";
          
          // Phase 1: Fill email and click "Weiter"
          async function fillEmailAndProceed() {
            console.log('schul.cloud: Phase 1 - Email');
            
            // Find email field by ID (most reliable)
            const emailField = document.querySelector('input#username[type="text"]');
            
            if (emailField && emailField.offsetParent !== null && emailField.value === '') {
              emailField.value = EMAIL_VALUE;
              emailField.dispatchEvent(new Event('input', { bubbles: true }));
              emailField.dispatchEvent(new Event('change', { bubbles: true }));
              emailField.dispatchEvent(new Event('blur', { bubbles: true }));
              
              try {
                emailField.dispatchEvent(new Event('ngModelChange', { bubbles: true }));
              } catch (e) {}
              
              console.log('schul.cloud: Email filled:', EMAIL_VALUE);
              
              // Wait for Angular to process
              await new Promise(resolve => setTimeout(resolve, 300));
              
              // Click "Weiter" button
              const weiterButton = document.querySelector('button.btn.btn-contained[type="submit"]');
              if (weiterButton && !weiterButton.disabled) {
                console.log('schul.cloud: Clicking Weiter button');
                weiterButton.click();
                return true;
              } else {
                console.log('schul.cloud: Weiter button not found or disabled');
              }
            }
            return false;
          }
          
          // Phase 2: Fill password with DESKTOP-APP approach (NO multi-set!)
          async function fillPasswordAndLogin() {
            console.log('schul.cloud: Phase 2 - Password (desktop-app approach)');
            
            // Find password field
            const passwordField = document.querySelector('input[type="password"]');
            
            if (passwordField && passwordField.offsetParent !== null) {
              // DESKTOP-APP METHOD: Set ONCE, then trigger events
              console.log('schul.cloud: Filling login password (desktop-app method)');
              passwordField.value = PASSWORD_VALUE;
              passwordField.focus();
              
              // Trigger Angular events (EXACTLY like desktop-app)
              passwordField.dispatchEvent(new Event('input', { bubbles: true }));
              passwordField.dispatchEvent(new Event('change', { bubbles: true }));
              passwordField.dispatchEvent(new Event('blur', { bubbles: true }));
              
              console.log('schul.cloud: Password set ONCE');
              
              // FIX: Use CLICK event like Desktop App (triggers Angular's save logic!)
              // HTML: <input type="checkbox" id="stayLoggedInCheck" class="checkbox">
              const checkbox = document.querySelector('input#stayLoggedInCheck[type="checkbox"]');
              if (checkbox) {
                console.log('schul.cloud: Found stay logged in checkbox');
                
                // Check if already checked (to avoid double-click)
                if (!checkbox.checked) {
                  console.log('schul.cloud: Checkbox not checked, clicking it');
                  checkbox.click();
                  console.log('schul.cloud: Checkbox clicked, now checked =', checkbox.checked);
                } else {
                  console.log('schul.cloud: Checkbox already checked =', checkbox.checked);
                }
                
                // DEBUG: Check if localStorage/cookies are being saved
                setTimeout(() => {
                  console.log('schul.cloud: DEBUG - Checking storage after checkbox click');
                  console.log('schul.cloud: localStorage items:', Object.keys(localStorage).length);
                  console.log('schul.cloud: localStorage content:', JSON.stringify(localStorage));
                  console.log('schul.cloud: document.cookie:', document.cookie);
                }, 500);
              } else {
                console.log('schul.cloud: Checkbox input#stayLoggedInCheck not found');
              }
              
              // Wait then click login button (same as desktop-app)
              await new Promise(resolve => setTimeout(resolve, 1000));
              
              // Click "Anmelden mit Passwort" span (it's clickable!)
              const loginSpans = document.querySelectorAll('span.header');
              for (const span of loginSpans) {
                if (span.textContent && span.textContent.includes('Anmelden mit Passwort')) {
                  console.log('schul.cloud: Clicking Anmelden mit Passwort');
                  span.click();
                  
                  // FIX: Wait LONGER for Angular to save session (like WebUntis: 2s, but 3s for Angular)
                  await new Promise(resolve => setTimeout(resolve, 3000));
                  
                  // Check if session was saved
                  console.log('schul.cloud: Checking if session was saved...');
                  const sessionSaved = Object.keys(localStorage).length > 0 || document.cookie.length > 0;
                  console.log('schul.cloud: localStorage items:', Object.keys(localStorage).length);
                  console.log('schul.cloud: Session saved:', sessionSaved);
                  
                  // Signal Flutter that login is complete
                  try {
                    window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
                    console.log('schul.cloud: Sent loginComplete signal to Flutter');
                  } catch (e) {
                    console.log('schul.cloud: Could not send signal to Flutter:', e);
                  }
                  
                  return true;
                }
              }
              
              // Fallback: Try button with type submit
              const submitButton = document.querySelector('button[type="submit"]');
              if (submitButton && !submitButton.disabled) {
                console.log('schul.cloud: Clicking submit button (fallback)');
                submitButton.click();
                
                // FIX: Wait LONGER for Angular to save session
                await new Promise(resolve => setTimeout(resolve, 3000));
                
                console.log('schul.cloud: Session check - localStorage items:', Object.keys(localStorage).length);
                
                // Signal Flutter that login is complete
                try {
                  window.flutter_inappwebview.callHandler('loginComplete', {app: 'schulcloud'});
                  console.log('schul.cloud: Sent loginComplete signal to Flutter');
                } catch (e) {
                  console.log('schul.cloud: Could not send signal to Flutter:', e);
                }
                
                return true;
              }
            }
            return false;
          }
          
          // Execute phases with proper delays
          async function executeLogin() {
            // Try Phase 1 (email page)
            if (await fillEmailAndProceed()) {
              console.log('schul.cloud: Phase 1 completed, waiting for Phase 2');
              // Wait for navigation to password page
              setTimeout(async () => {
                await fillPasswordAndLogin();
              }, 2000);
            } else {
              // Maybe we're already on password page
              console.log('schul.cloud: Checking if on password page');
              setTimeout(async () => {
                await fillPasswordAndLogin();
              }, 1000);
            }
          }
          
          // FIX: Execute only ONCE to prevent race conditions (removed second execution)
          setTimeout(executeLogin, 500);
          
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
            emailField.dispatchEvent(new Event('blur', { bubbles: true }));
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
            passwordField.dispatchEvent(new Event('blur', { bubbles: true }));
            console.log('Outlook: Password filled');
          }
          
          // Auto-click submit/next button with comprehensive selector list
          function clickSubmitButton() {
            const buttonSelectors = [
              // NEW: Span elements with role="button" (Outlook uses these!)
              'span#submitButton[role="button"]',
              'span.submit[role="button"]',
              'span[role="button"][onclick*="submitLoginRequest"]',
              // Original selectors
              'input[type="submit"]',
              'button[type="submit"]',
              'input[id*="idSIButton"]',
              'button[id*="idSIButton"]',
              'input[id*="submit"]',
              'button[id*="submit"]',
              'input[value*="Sign in"]',
              'input[value*="Next"]',
              'input[value*="Anmelden"]',
              'input[value*="Weiter"]',
              'button:has([data-icon-name="SignIn"])',
              'button[data-report-event*="Signin"]',
              'button[class*="submit"]',
              'button[class*="primary"]'
            ];
            
            let submitButton = null;
            for (const selector of buttonSelectors) {
              const buttons = document.querySelectorAll(selector);
              for (const btn of buttons) {
                // Check visibility for both buttons and spans
                const isVisible = btn.offsetParent !== null || 
                                window.getComputedStyle(btn).display !== 'none';
                const isEnabled = !btn.disabled && !btn.hasAttribute('disabled');
                
                if (isVisible && isEnabled) {
                  submitButton = btn;
                  console.log('Outlook: Found button/span with selector:', selector);
                  break;
                }
              }
              if (submitButton) break;
            }
            
            if (submitButton) {
              console.log('Outlook: Clicking submit element');
              submitButton.click();
              return true;
            }
            
            console.log('Outlook: Submit button/span not found');
            return false;
          }
          
          // Wait for fields to be filled, then click
          if (emailField || passwordField) {
            setTimeout(() => {
              if (!clickSubmitButton()) {
                // Try again after a longer delay
                setTimeout(clickSubmitButton, 1000);
              }
            }, 500);
          }
        } catch (error) {
          console.error('Outlook injection error:', error);
        }
      })();
    ''';
  }

  /// Taskcards credential injection with PRECISE selector from user-provided HTML
  static String getTaskcardsInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (function() {
        try {
          console.log('Taskcards: Starting credential injection with precise selectors');
          
          // PRECISE email field selector from user-provided HTML:
          // <input tabindex="1" aria-label="Email" type="email" class="q-field__native">
          const emailField = document.querySelector(
            'input[type="email"][aria-label="Email"].q-field__native'
          );
          
          if (emailField && emailField.offsetParent !== null && emailField.value === '') {
            emailField.value = "$escapedEmail";
            emailField.dispatchEvent(new Event('input', { bubbles: true }));
            emailField.dispatchEvent(new Event('change', { bubbles: true }));
            emailField.dispatchEvent(new Event('blur', { bubbles: true }));
            
            // Trigger Quasar/Vue events
            try {
              emailField.dispatchEvent(new Event('update:modelValue', { bubbles: true }));
            } catch (e) {}
            
            console.log('Taskcards: Email filled with precise selector');
          } else if (!emailField) {
            console.log('Taskcards: Email field not found - might not be on login page');
            return;
          }
          
          // Password field (still generic but within same form context)
          const passwordField = emailField ? 
            emailField.closest('form')?.querySelector('input[type="password"]') ||
            document.querySelector('input[type="password"]') :
            null;
            
          if (passwordField && passwordField.offsetParent !== null && passwordField.value === '') {
            passwordField.value = "$escapedPassword";
            passwordField.dispatchEvent(new Event('input', { bubbles: true }));
            passwordField.dispatchEvent(new Event('change', { bubbles: true }));
            passwordField.dispatchEvent(new Event('blur', { bubbles: true }));
            
            // Trigger Quasar/Vue events
            try {
              passwordField.dispatchEvent(new Event('update:modelValue', { bubbles: true }));
            } catch (e) {}
            
            console.log('Taskcards: Password filled');
          }
          
          // Auto-click login button
          if (emailField && passwordField && emailField.value && passwordField.value) {
            const form = emailField.closest('form');
            const loginButton = form ? 
              form.querySelector('button[type="submit"], input[type="submit"], button[class*="submit"]') :
              document.querySelector('button[type="submit"]');
            
            if (loginButton && !loginButton.disabled) {
              setTimeout(() => {
                console.log('Taskcards: Clicking login button');
                loginButton.click();
              }, 300);
            }
          }
        } catch (error) {
          console.error('Taskcards injection error:', error);
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
        // No generic injection - let unknown apps handle their own login
        return null;
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
