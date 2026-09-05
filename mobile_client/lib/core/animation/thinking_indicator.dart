import 'package:flutter/material.dart';

/// Indicateur "Analyse en cours..." affichant 3 petits points animés en cascade.
class ThinkingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const ThinkingIndicator({
    super.key,
    this.color,
    this.size = 6.0,
  });

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  late Animation<double> _dot1Opacity;
  late Animation<double> _dot1Translate;
  
  late Animation<double> _dot2Opacity;
  late Animation<double> _dot2Translate;
  
  late Animation<double> _dot3Opacity;
  late Animation<double> _dot3Translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1Opacity = _createOpacityAnimation(0.0, 0.5);
    _dot1Translate = _createTranslateAnimation(0.0, 0.5);

    _dot2Opacity = _createOpacityAnimation(0.2, 0.7);
    _dot2Translate = _createTranslateAnimation(0.2, 0.7);

    _dot3Opacity = _createOpacityAnimation(0.4, 0.9);
    _dot3Translate = _createTranslateAnimation(0.4, 0.9);
  }

  Animation<double> _createOpacityAnimation(double begin, double end) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeInOut),
      ),
    );
  }

  Animation<double> _createTranslateAnimation(double begin, double end) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Animation<double> opacity, Animation<double> translate, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, translate.value),
          child: Opacity(
            opacity: opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Theme.of(context).primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_dot1Opacity, _dot1Translate, effectiveColor),
        _buildDot(_dot2Opacity, _dot2Translate, effectiveColor),
        _buildDot(_dot3Opacity, _dot3Translate, effectiveColor),
      ],
    );
  }
}
