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
  static const InjectionScript webuntisPhase2Injection = InjectionScript(
    js: '''
      (function() {
        try {
          const style = document.createElement('style');
          style.id = 'bbzcloud-webuntis-banner-hide';
          style.textContent = `
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
          document.head.appendChild(style);
        } catch (error) {
          console.error('WebUntis Phase 2 error:', error);
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
        let interactionDetected = false;
        let monitoringActive = true;
        
        function detectAndCloseOverlay() {
          if (!monitoringActive) return false;
          
          try {
            const closeButtons = document.querySelectorAll(
              'button[class*="close"], button[aria-label*="close"], button[aria-label*="schließen"], ' +
              'button[aria-label*="Close"], [class*="close-button"], [class*="closeButton"], ' +
              'button:has(svg[class*="close"]), button:has([class*="icon-close"]), ' +
              'button[title*="close" i], button[title*="schließen" i], ' +
              '[role="button"]:has(svg[class*="close"])'
            );
            
            for (const button of closeButtons) {
              const parent = button.closest('[role="dialog"], [role="alertdialog"], [class*="modal"], [class*="overlay"], [class*="dialog"], [class*="popup"]');
              if (parent) {
                const style = window.getComputedStyle(parent);
                if (style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0') {
                  button.click();
                  setTimeout(() => { monitoringActive = false; }, 1000);
                  return true;
                }
              }
            }
          } catch (error) {
            console.error('WebUntis Phase 3 error:', error);
          }
          return false;
        }
        
        const interactionEvents = ['click', 'touchstart', 'scroll', 'keydown'];
        
        function handleInteraction() {
          if (!interactionDetected) {
            interactionDetected = true;
            let checkCount = 0;
            const intervalId = setInterval(() => {
              checkCount++;
              if (detectAndCloseOverlay() || checkCount >= 10 || !monitoringActive) {
                clearInterval(intervalId);
              }
            }, 1000);
          }
        }
        
        interactionEvents.forEach(event => {
          document.addEventListener(event, handleInteraction, { once: false, passive: true });
        });
        
        let periodicCheckCount = 0;
        const periodicInterval = setInterval(() => {
          periodicCheckCount++;
          if (detectAndCloseOverlay() || periodicCheckCount >= 20 || !monitoringActive) {
            clearInterval(periodicInterval);
          }
        }, 2000);
        
        setTimeout(() => { monitoringActive = false; }, 60000);
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
              
              // Auto-click "Angemeldet bleiben" checkbox
              const checkbox = document.querySelector('input#stayLoggedInCheck[type="checkbox"]');
              if (checkbox && !checkbox.checked) {
                console.log('schul.cloud: Clicking checkbox');
                checkbox.click();
              }
              
              await new Promise(resolve => setTimeout(resolve, 1000));
              
              // Click "Anmelden mit Passwort" span
              const loginSpans = document.querySelectorAll('span.header');
              for (const span of loginSpans) {
                if (span.textContent && span.textContent.includes('Anmelden mit Passwort')) {
                  console.log('schul.cloud: Clicking login button');
                  span.click();
                  await new Promise(resolve => setTimeout(resolve, 3000));
                  return true;
                }
              }
              
              // Fallback: Try button with type submit
              const submitButton = document.querySelector('button[type="submit"]');
              if (submitButton && !submitButton.disabled) {
                console.log('schul.cloud: Clicking submit button (fallback)');
                submitButton.click();
                await new Promise(resolve => setTimeout(resolve, 3000));
                return true;
              }
              
              return false;
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
  /// Uses Desktop-App approach with ONE-TIME reload after login
  static String getOutlookInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    final escapedPassword = _escapeJs(password);
    
    return '''
      (async function() {
        try {
          console.log('Outlook: Starting credential injection (Desktop-App method)');
          
          // Check if we already did the post-login reload
          const reloadDoneKey = 'bbzcloud_outlook_reload_done';
          const reloadDone = sessionStorage.getItem(reloadDoneKey);
          
          if (reloadDone === 'true') {
            console.log('Outlook: Post-login reload already done, skipping');
            return;
          }
          
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
          
          // Only do ONE-TIME reload after login (Desktop-App method)
          // Check if we actually filled credentials (indicating login attempt)
          const didFillCredentials = (emailField && emailField.value === "$escapedEmail") || 
                                    (passwordField && passwordField.value === "$escapedPassword");
          
          if (didFillCredentials) {
            console.log('Outlook: Credentials filled, will reload ONCE after 5 seconds');
            
            // Wait for fields to be filled, then click
            if (emailField || passwordField) {
              setTimeout(() => {
                if (!clickSubmitButton()) {
                  // Try again after a longer delay
                  setTimeout(clickSubmitButton, 1000);
                }
              }, 500);
            }
            
            // ONE-TIME reload after 5 seconds (Desktop-App method)
            // This prevents false error messages and ensures proper login flow
            // Mark that we will do the reload to prevent multiple reloads
            setTimeout(() => {
              console.log('Outlook: Reloading page ONCE after 5 seconds (desktop-app method)');
              sessionStorage.setItem(reloadDoneKey, 'true');
              window.location.reload();
            }, 5000);
          } else {
            console.log('Outlook: No credentials filled, skipping reload (already logged in or different page)');
          }
        } catch (error) {
          console.error('Outlook injection error:', error);
        }
      })();
    ''';
  }

  /// Taskcards credential injection - EMAIL ONLY (no password)
  /// User requested to only fill email, not password
  static String getTaskcardsInjection(String email, String password) {
    final escapedEmail = _escapeJs(email);
    // password parameter kept for compatibility, but not used
    
    return '''
      (function() {
        try {
          console.log('Taskcards: Starting EMAIL-ONLY injection (no password)');
          
          // PRECISE email field selector from user-provided HTML:
          // <input tabindex="1" aria-label="Email" icon="mdi-email" type="email" class="q-field__native">
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
            
            console.log('Taskcards: ✅ Email filled (password intentionally NOT filled)');
          } else if (!emailField) {
            console.log('Taskcards: Email field not found - might not be on login page');
            return;
          }
          
          // NOTE: Password field intentionally NOT filled per user request
          // User will enter password manually
          
          console.log('Taskcards: Email injection complete - user will enter password manually');
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
        // Re-enabled with cookie backup/restore script
        return getSchulcloudInjection(email, password);
      
      case 'bbb':
        return getBBBInjection(email, bbbPassword);
      
      case 'outlook':
        return getOutlookInjection(email, password);
      
      case 'taskcards':
        // TaskCards: Email only, no password (per user request)
        return getTaskcardsInjection(email, password);
      
      default:
        // No generic injection - let unknown apps handle their own login
        return null;
    }
  }

  /// schul.cloud session backup/restore (sessionStorage + cookies)
  /// Workaround for session persistence issues
  /// schul.cloud stores auth tokens in sessionStorage which gets cleared on app restart
  static const InjectionScript schulcloudCookieBackupInjection = InjectionScript(
    js: '''
      (function() {
        console.log('schul.cloud: Session backup/restore script starting');
        
        try {
          // Function to backup sessionStorage to localStorage
          function backupSessionStorageToLocalStorage() {
            const sessionBackup = {};
            let itemCount = 0;
            
            // Backup all sessionStorage items
            Object.keys(sessionStorage).forEach(key => {
              sessionBackup[key] = sessionStorage.getItem(key);
              itemCount++;
            });
            
            if (itemCount > 0) {
              console.log('schul.cloud: Backing up', itemCount, 'sessionStorage items to localStorage');
              localStorage.setItem('bbzcloud_session_backup', JSON.stringify(sessionBackup));
              localStorage.setItem('bbzcloud_session_backup_time', Date.now().toString());
              console.log('schul.cloud: sessionStorage backed up successfully');
              
              // Log important items
              if (sessionBackup['__ENC__token']) {
                console.log('schul.cloud: ✅ Auth token backed up');
              }
              if (sessionBackup['stayLoggedIn']) {
                console.log('schul.cloud: stayLoggedIn =', sessionBackup['stayLoggedIn']);
              }
            }
          }
          
          // Function to restore sessionStorage from localStorage
          function restoreSessionStorageFromLocalStorage() {
            const backup = localStorage.getItem('bbzcloud_session_backup');
            const backupTime = localStorage.getItem('bbzcloud_session_backup_time');
            
            if (backup && backupTime) {
              const timeSinceBackup = Date.now() - parseInt(backupTime);
              const hoursSinceBackup = timeSinceBackup / (1000 * 60 * 60);
              
              console.log('schul.cloud: Found sessionStorage backup from', hoursSinceBackup.toFixed(1), 'hours ago');
              
              // Only restore if backup is less than 24 hours old
              if (hoursSinceBackup < 24) {
                console.log('schul.cloud: Restoring sessionStorage from localStorage');
                
                try {
                  const sessionData = JSON.parse(backup);
                  let restoredCount = 0;
                  
                  // Restore all items
                  Object.entries(sessionData).forEach(([key, value]) => {
                    sessionStorage.setItem(key, value);
                    restoredCount++;
                  });
                  
                  console.log('schul.cloud: ✅ Restored', restoredCount, 'sessionStorage items');
                  
                  // Verify important items
                  if (sessionStorage.getItem('__ENC__token')) {
                    console.log('schul.cloud: ✅ Auth token restored');
                  }
                  
                  // Force stayLoggedIn to true to keep session
                  sessionStorage.setItem('stayLoggedIn', 'true');
                  console.log('schul.cloud: ✅ Set stayLoggedIn = true');
                  
                  console.log('schul.cloud: Reloading page with restored session');
                  // Give sessionStorage time to be set, then reload
                  setTimeout(() => window.location.reload(), 500);
                  return true;
                  
                } catch (parseError) {
                  console.error('schul.cloud: Error parsing backup:', parseError);
                }
              } else {
                console.log('schul.cloud: Backup too old, clearing');
                localStorage.removeItem('bbzcloud_session_backup');
                localStorage.removeItem('bbzcloud_session_backup_time');
              }
            } else {
              console.log('schul.cloud: No sessionStorage backup found');
            }
            return false;
          }
          
          // Function to backup cookies to localStorage (fallback, though schul.cloud doesn't use cookies much)
          function backupCookiesToLocalStorage() {
            const cookies = document.cookie.split(';').filter(c => c.trim());
            if (cookies.length > 0) {
              console.log('schul.cloud: Backing up', cookies.length, 'cookies to localStorage');
              localStorage.setItem('bbzcloud_cookie_backup', document.cookie);
            }
          }
          
          // Check if we're on login page
          const isLoginPage = window.location.href.includes('login') || 
                             document.querySelector('input[type="password"]') !== null;
          
          if (isLoginPage) {
            console.log('schul.cloud: On login page, checking for session backup');
            // Try to restore session if on login page
            if (!restoreSessionStorageFromLocalStorage()) {
              console.log('schul.cloud: No valid backup found, user needs to login');
            }
          } else {
            console.log('schul.cloud: Not on login page, backing up session');
            
            // Backup sessionStorage if logged in
            backupSessionStorageToLocalStorage();
            backupCookiesToLocalStorage();
            
            // Also backup periodically (every 5 minutes)
            setInterval(() => {
              backupSessionStorageToLocalStorage();
              backupCookiesToLocalStorage();
            }, 5 * 60 * 1000);
            
            // Backup before page unload
            window.addEventListener('beforeunload', () => {
              backupSessionStorageToLocalStorage();
              backupCookiesToLocalStorage();
            });
            
            console.log('schul.cloud: Session backup active (every 5 min + before unload)');
          }
          
        } catch (error) {
          console.error('schul.cloud: Session backup/restore error:', error);
        }
      })();
    ''',
    delay: 0,
    description: 'Backup sessionStorage + cookies to localStorage for session persistence',
  );

  /// Outlook error page fallback - Reload standard URL when permission error appears
  /// This handles the "Sie sind nicht autorisiert" error that sometimes appears after login
  /// Since user is already logged in, reloading the standard URL should work
  static const InjectionScript outlookErrorPageFallback = InjectionScript(
    js: '''
      (function() {
        console.log('Outlook: Error page fallback monitor starting');
        
        let fallbackExecuted = false;
        const OUTLOOK_STANDARD_URL = 'https://exchange.bbz-rd-eck.de/owa/#path=/mail';
        
        function checkForErrorPage() {
          if (fallbackExecuted) return;
          
          try {
            const pageText = document.body.textContent || '';
            const pageHTML = document.body.innerHTML || '';
            
            // Check for German error message from screenshot:
            // "Fehler" and "Sie sind nicht autorisiert, auf diese Website zuzugreifen"
            const hasErrorTitle = pageText.includes('Fehler');
            const hasPermissionError = pageText.includes('Sie sind nicht autorisiert') || 
                                      pageText.includes('nicht autorisiert');
            const hasAccessError = pageText.includes('auf diese Website zuzugreifen');
            
            // Also check for English variants
            const hasEnglishError = pageText.includes('You don\\'t have access') ||
                                   pageText.includes('not authorized') ||
                                   pageText.includes('Access Denied');
            
            if ((hasErrorTitle && hasPermissionError) || 
                (hasPermissionError && hasAccessError) ||
                hasEnglishError) {
              console.log('Outlook: ⚠️ Permission error page detected!');
              console.log('Outlook: Executing fallback - reloading standard URL');
              console.log('Outlook: Target URL:', OUTLOOK_STANDARD_URL);
              
              fallbackExecuted = true;
              
              // Reload standard Outlook URL (user is already logged in)
              setTimeout(() => {
                console.log('Outlook: Loading standard URL');
                window.location.href = OUTLOOK_STANDARD_URL;
              }, 500);
            }
          } catch (error) {
            console.error('Outlook: Error page check failed:', error);
          }
        }
        
        // Check immediately
        checkForErrorPage();
        
        // Check again after short delay (page might still be loading)
        setTimeout(checkForErrorPage, 1000);
        setTimeout(checkForErrorPage, 2000);
        
        // Set up periodic check for the first 10 seconds
        let checkCount = 0;
        const intervalId = setInterval(() => {
          checkCount++;
          checkForErrorPage();
          
          if (checkCount >= 5 || fallbackExecuted) {
            clearInterval(intervalId);
          }
        }, 2000);
      })();
    ''',
    delay: 0,
    description: 'Monitor for Outlook permission error page and reload standard URL',
  );

  /// Get post-load script for app (e.g., dialog dismissal)
  /// This runs BEFORE credential injection
  static InjectionScript? getPostLoadScriptForApp(String appId) {
    switch (appId.toLowerCase()) {
      case 'webuntis':
        return webuntisPhase1Injection; // Phase 1: Close "Im Browser öffnen" dialog
      
      case 'schulcloud':
        return schulcloudCookieBackupInjection; // Backup/restore cookies to localStorage
      
      case 'outlook':
        return outlookErrorPageFallback; // Auto-navigate back on permission error page
      
      default:
        return null;
    }
  }
}
