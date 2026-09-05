import 'package:flutter/material.dart';

/// Applique une subtile animation d'apparition pour les bulles de messages.
/// opacity: 0 -> 1, scale: 0.97 -> 1, translateY: 6 -> 0
class MessageEntranceAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const MessageEntranceAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        // value va de 0.0 à 1.0
        final opacity = value;
        final scale = 0.97 + (0.03 * value);
        final translateY = 6.0 * (1.0 - value);

        return Opacity(
          opacity: opacity,
          child: Transform(
            transform: Matrix4.identity()
              ..translate(0.0, translateY)
              ..scale(scale, scale),
            alignment: Alignment.center,
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}
