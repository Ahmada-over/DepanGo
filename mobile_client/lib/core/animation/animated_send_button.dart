import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'haptic_service.dart';

/// Bouton d'envoi qui se transforme en bouton Stop pendant la génération.
/// Intègre des micro-interactions de scale au tap et du haptic feedback.
class AnimatedSendButton extends StatefulWidget {
  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isEnabled;

  const AnimatedSendButton({
    super.key,
    required this.isGenerating,
    required this.onSend,
    required this.onStop,
    this.isEnabled = true,
  });

  @override
  State<AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<AnimatedSendButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      _scaleController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled) {
      _scaleController.forward();
      HapticService.buttonPress();
      if (widget.isGenerating) {
        widget.onStop();
      } else {
        widget.onSend();
      }
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled) {
      _scaleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final disabledColor = Colors.grey[400]!;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleController,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.isEnabled ? primaryColor : disabledColor,
            shape: BoxShape.circle,
            boxShadow: widget.isEnabled && !widget.isGenerating
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: widget.isGenerating
                ? const Icon(
                    LucideIcons.square,
                    key: ValueKey('stop_icon'),
                    color: Colors.white,
                    size: 24,
                  )
                : const Icon(
                    LucideIcons.arrow_up,
                    key: ValueKey('send_icon'),
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}
