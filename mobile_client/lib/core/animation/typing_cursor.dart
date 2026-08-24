import 'package:flutter/material.dart';

/// Curseur clignotant affiché à la fin du texte généré par l'IA.
/// Animé avec un Fade subtil (opacity 1.0 -> 0.3).
class TypingCursor extends StatefulWidget {
  final Color? color;
  final double width;
  final double height;
  final bool isVisible;

  const TypingCursor({
    super.key,
    this.color,
    this.width = 6.0,
    this.height = 18.0,
    this.isVisible = true,
  });

  @override
  State<TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<TypingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Animation de pulsation douce (pas de on/off brutal)
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TypingCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.repeat(reverse: true);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: widget.color ?? Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(1.0),
          ),
        ),
      ),
    );
  }
}
