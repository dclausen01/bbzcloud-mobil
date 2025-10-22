/// BBZCloud Mobile - Credentials Dialog
/// 
/// Dialog for editing user credentials
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/constants/app_strings.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/core/utils/validators.dart';
import 'package:bbzcloud_mobil/data/models/credentials.dart';
import 'package:bbzcloud_mobil/data/models/user.dart' show User, UserRole;
import 'package:bbzcloud_mobil/data/services/credential_service.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';

class CredentialsDialog extends ConsumerStatefulWidget {
  const CredentialsDialog({super.key});

  @override
  ConsumerState<CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends ConsumerState<CredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bbbPasswordController = TextEditingController();
  final _webuntisEmailController = TextEditingController();
  final _webuntisPasswordController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureBBBPassword = true;
  bool _obscureWebUntisPassword = true;
  
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    setState(() => _isLoading = true);
    
    try {
      final userState = ref.read(userProvider);
      userState.whenData((user) {
        if (user != null) {
          _userRole = user.role;
        }
      });
      
      final credentials = await CredentialService.instance.loadCredentials();
      
      if (mounted) {
        setState(() {
          _emailController.text = credentials.email ?? '';
          _passwordController.text = credentials.password ?? '';
          _bbbPasswordController.text = credentials.bbbPassword ?? '';
          _webuntisEmailController.text = credentials.webuntisEmail ?? '';
          _webuntisPasswordController.text = credentials.webuntisPassword ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final credentials = Credentials(
        email: _emailController.text.trim(),
        password: _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : null,
        bbbPassword: _bbbPasswordController.text.isNotEmpty
            ? _bbbPasswordController.text
            : null,
        webuntisEmail: _webuntisEmailController.text.isNotEmpty
            ? _webuntisEmailController.text
            : null,
        webuntisPassword: _webuntisPasswordController.text.isNotEmpty
            ? _webuntisPasswordController.text
            : null,
      );

      await CredentialService.instance.saveCredentials(credentials);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anmeldedaten gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    }
  }

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
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.vpn_key,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Anmeldedaten verwalten',
                            style: AppTextStyles.heading2.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email (required)
                            Text(
                              'Basis-Anmeldedaten',
                              style: AppTextStyles.heading3.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-Mail-Adresse *',
                                hintText: 'vorname.nachname@bbz-rd-eck.de',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'E-Mail-Adresse ist erforderlich';
                                }
                                try {
                                  Validators.validateEmail(value);
                                  return null;
                                } catch (e) {
                                  return 'Ungültige E-Mail-Adresse';
                                }
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Password (optional)
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Passwort (optional)',
                                hintText: 'Für Auto-Login',
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

                            // Teacher-specific fields
                            if (_userRole == UserRole.teacher) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Zusätzliche Anmeldedaten für Lehrkräfte',
                                style: AppTextStyles.heading3.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // BBB Password
                              TextFormField(
                                controller: _bbbPasswordController,
                                obscureText: _obscureBBBPassword,
                                decoration: InputDecoration(
                                  labelText: 'BBB-Passwort (optional)',
                                  hintText: 'Falls abweichend',
                                  prefixIcon: const Icon(Icons.videocam),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureBBBPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureBBBPassword = !_obscureBBBPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // WebUntis Email
                              TextFormField(
                                controller: _webuntisEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'WebUntis-Benutzername (optional)',
                                  hintText: 'Falls abweichend',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    try {
                                      Validators.validateEmail(value);
                                      return null;
                                    } catch (e) {
                                      return 'Ungültige E-Mail-Adresse';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // WebUntis Password
                              TextFormField(
                                controller: _webuntisPasswordController,
                                obscureText: _obscureWebUntisPassword,
                                decoration: InputDecoration(
                                  labelText: 'WebUntis-Passwort (optional)',
                                  hintText: 'Falls abweichend',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureWebUntisPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureWebUntisPassword = !_obscureWebUntisPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              '* Pflichtfeld\n\n'
                              'Hinweis: Alle Passwörter werden sicher verschlüsselt gespeichert.',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text(AppStrings.cancel),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _saveCredentials,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Speichern...' : 'Speichern'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
