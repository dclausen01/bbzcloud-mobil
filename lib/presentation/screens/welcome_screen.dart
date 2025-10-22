/// BBZCloud Mobile - Welcome Screen
/// 
/// First-launch setup screen for new users
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_config.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/user.dart';
import 'package:bbzcloud_mobil/data/models/credentials.dart';
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/settings_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bbbPasswordController = TextEditingController();
  final _webuntisEmailController = TextEditingController();
  final _webuntisPasswordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureBbbPassword = true;
  bool _obscureWebuntisPassword = true;
  bool _saveCredentials = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bbbPasswordController.dispose();
    _webuntisEmailController.dispose();
    _webuntisPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                
                // Logo/Icon
                Icon(
                  Icons.school,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Welcome Text
                Text(
                  AppStrings.welcome,
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.firstTimeSetup,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    hintText: 'name@bbz-rd-eck.de',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte E-Mail eingeben';
                    }
                    if (!value.contains('@')) {
                      return 'Bitte gültige E-Mail eingeben';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Auto-detect role from email domain
                    if (value.endsWith('@bbz-rd-eck.de')) {
                      setState(() {
                        _selectedRole = UserRole.teacher;
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Role Selection
                Text(
                  'Ich bin...',
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment<UserRole>(
                      value: UserRole.student,
                      label: Text('Schüler/in'),
                      icon: Icon(Icons.school),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.teacher,
                      label: Text('Lehrkraft'),
                      icon: Icon(Icons.person),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (Set<UserRole> newSelection) {
                    setState(() {
                      _selectedRole = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Optional Password
                ExpansionTile(
                  title: const Text('Passwort speichern (optional)'),
                  subtitle: const Text('Für Auto-Login in Apps'),
                  initiallyExpanded: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: AppStrings.password,
                              hintText: 'Ihr BBZ-Passwort',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CheckboxListTile(
                            value: _saveCredentials,
                            onChanged: (value) {
                              setState(() {
                                _saveCredentials = value ?? false;
                              });
                            },
                            title: const Text('Sicher speichern'),
                            subtitle: const Text(
                              'Verschlüsselt im Gerätespeicher',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Teacher-specific fields
                if (_selectedRole == UserRole.teacher) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ExpansionTile(
                    title: const Text('Zusätzliche Zugangsdaten (Lehrkräfte)'),
                    subtitle: const Text('Für BBB und WebUntis'),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BBB Password
                            const Text(
                              'BigBlueButton',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _bbbPasswordController,
                              obscureText: _obscureBbbPassword,
                              decoration: InputDecoration(
                                labelText: 'BBB-Passwort',
                                hintText: 'Optional, falls abweichend',
                                prefixIcon: const Icon(Icons.videocam),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureBbbPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureBbbPassword = !_obscureBbbPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            // WebUntis credentials
                            const Text(
                              'WebUntis',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _webuntisEmailController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'WebUntis-Benutzername',
                                hintText: 'Optional, falls abweichend',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _webuntisPasswordController,
                              obscureText: _obscureWebuntisPassword,
                              decoration: InputDecoration(
                                labelText: 'WebUntis-Passwort',
                                hintText: 'Optional, falls abweichend',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureWebuntisPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureWebuntisPassword = !_obscureWebuntisPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Diese Felder nur ausfüllen, wenn Ihre WebUntis-Zugangsdaten von der Haupt-E-Mail abweichen.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                
                // Submit Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _handleSubmit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isLoading ? AppStrings.saving : 'Fertig',
                    style: AppTextStyles.button,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Privacy Note
                Text(
                  'Ihre Daten werden nur lokal auf Ihrem Gerät gespeichert.',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Create and save user
      final user = User(
        email: email,
        role: _selectedRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(userProvider.notifier).saveUser(user);

      // Save credentials if provided and checkbox is checked
      if (password.isNotEmpty && _saveCredentials) {
        final bbbPassword = _bbbPasswordController.text.trim();
        final webuntisEmail = _webuntisEmailController.text.trim();
        final webuntisPassword = _webuntisPasswordController.text.trim();
        
        final credentials = Credentials(
          email: email,
          password: password,
          bbbPassword: bbbPassword.isNotEmpty ? bbbPassword : null,
          webuntisEmail: webuntisEmail.isNotEmpty ? webuntisEmail : null,
          webuntisPassword: webuntisPassword.isNotEmpty ? webuntisPassword : null,
        );
        await CredentialService.instance.saveCredentials(credentials);
      }

      // Mark first launch as complete
      await ref.read(settingsProvider.notifier).completeFirstLaunch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.settingsSaved),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
