/// BBZCloud Mobile - Custom App Dialog
/// 
/// Dialog for adding/editing custom apps
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/data/models/custom_app.dart';
import 'package:bbzcloud_mobil/presentation/providers/apps_provider.dart';
import 'package:bbzcloud_mobil/presentation/providers/user_provider.dart';

class CustomAppDialog extends ConsumerStatefulWidget {
  final CustomApp? existingApp;

  const CustomAppDialog({
    super.key,
    this.existingApp,
  });

  @override
  ConsumerState<CustomAppDialog> createState() => _CustomAppDialogState();
}

class _CustomAppDialogState extends ConsumerState<CustomAppDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  
  late Color _selectedColor;
  late IconData _selectedIcon;
  bool _isLoading = false;

  // Available colors
  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  // Available icons
  final List<IconData> _icons = [
    Icons.language,
    Icons.cloud,
    Icons.school,
    Icons.book,
    Icons.video_library,
    Icons.chat,
    Icons.calendar_today,
    Icons.assignment,
    Icons.folder,
    Icons.dashboard,
    Icons.science,
    Icons.calculate,
    Icons.brush,
    Icons.music_note,
    Icons.sports,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingApp?.title ?? '',
    );
    _urlController = TextEditingController(
      text: widget.existingApp?.url ?? '',
    );
    _selectedColor = widget.existingApp?.color ?? _colors[0];
    _selectedIcon = widget.existingApp?.icon ?? _icons[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingApp != null;

    return AlertDialog(
      title: Text(isEditing ? 'App bearbeiten' : 'Neue App hinzufügen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Meine App',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte einen Namen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // URL Field
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte eine URL eingeben';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return 'URL muss mit http:// oder https:// beginnen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color Selection
              Text(
                'Farbe',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Icon Selection
              Text(
                'Icon',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? _selectedColor
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? _selectedColor : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: _isLoading ? null : () => _handleDelete(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userState = ref.read(userProvider);
      final userId = userState.value?.id;

      final app = CustomApp(
        id: widget.existingApp?.id ?? '',
        title: _titleController.text.trim(),
        url: _urlController.text.trim(),
        color: _selectedColor,
        icon: _selectedIcon,
        userId: userId,
        createdAt: widget.existingApp?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingApp != null) {
        await ref.read(customAppsProvider.notifier).updateApp(app);
      } else {
        await ref.read(customAppsProvider.notifier).addApp(app);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingApp != null
                  ? 'App aktualisiert'
                  : 'App hinzugefügt',
            ),
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

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App löschen?'),
        content: Text(
          'Möchten Sie "${widget.existingApp?.title}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.existingApp != null) {
      try {
        await ref.read(customAppsProvider.notifier).deleteApp(
              widget.existingApp!.id,
            );
        
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App gelöscht'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
