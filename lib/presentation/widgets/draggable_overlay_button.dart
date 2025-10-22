/// BBZCloud Mobile - Draggable Overlay Button
/// 
/// Floating button for quick app switching
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bbzcloud_mobil/core/theme/app_theme.dart';
import 'package:bbzcloud_mobil/presentation/providers/webview_stack_provider.dart';

const String _positionKey = 'overlay_button_position';

class DraggableOverlayButton extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableOverlayButton({
    super.key,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  ConsumerState<DraggableOverlayButton> createState() => _DraggableOverlayButtonState();
}

class _DraggableOverlayButtonState extends ConsumerState<DraggableOverlayButton> {
  double _topPosition = 80.0;
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPosition = prefs.getDouble(_positionKey);
      if (savedPosition != null && mounted) {
        setState(() {
          _topPosition = savedPosition;
        });
      }
    } catch (e) {
      // Ignore errors, use default position
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_positionKey, _topPosition);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final webViewCount = ref.watch(activeWebViewCountProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Constrain position to screen boundaries
    final minY = 10.0;
    final maxY = screenHeight - 70.0; // Button height + padding
    final constrainedY = _topPosition.clamp(minY, maxY);

    return Positioned(
      left: 0,
      top: constrainedY,
      child: GestureDetector(
        onTap: _isDragging ? null : widget.onTap,
        onLongPress: _isDragging ? null : widget.onLongPress,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _topPosition += details.delta.dy;
            _topPosition = _topPosition.clamp(minY, maxY);
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          _savePosition();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
            _isDragging ? 8.0 : 0.0,
            0.0,
            0.0,
          ),
          child: Material(
            elevation: _isDragging ? 12.0 : 8.0,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.only(right: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                  if (webViewCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$webViewCount',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
