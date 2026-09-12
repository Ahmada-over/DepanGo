import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shimmer/shimmer.dart';
import '../services/pro_haptic_service.dart';

/// Bouton coulissant ergonomique "Slide to Confirm / Accept".
/// Élimine les clics accidentels sur moto/chantier et assure un retour tactile immersif.
class SlideToAccept extends StatefulWidget {
  final Future<void> Function() onConfirmed;
  final String label;
  final Color activeColor;

  const SlideToAccept({
    super.key,
    required this.onConfirmed,
    this.label = "GLISSER POUR ACCEPTER",
    this.activeColor = const Color(0xFF10B981), // Emerald 500
  });

  @override
  State<SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<SlideToAccept>
    with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  bool _isConfirmed = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  double _lastHapticTick = 0.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isConfirmed) return;
    final delta = details.primaryDelta ?? 0;
    final nextValue = (_dragValue + delta).clamp(0.0, maxDrag);

    // Retour haptique subtil tous les 20 pixels de glissement
    if ((nextValue - _lastHapticTick).abs() >= 22) {
      _lastHapticTick = nextValue;
      ProHapticService.instance.onSliderDragProgress();
    }

    setState(() => _dragValue = nextValue);
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;
    if (_dragValue >= maxDrag * 0.82) {
      // Seuil franchi : confirmation
      setState(() {
        _dragValue = maxDrag;
        _isConfirmed = true;
      });
      ProHapticService.instance.onSliderConfirmed();
      widget.onConfirmed();
    } else {
      // Retour élastique
      _resetAnimation = Tween<double>(begin: _dragValue, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOutBack),
      )..addListener(() => setState(() => _dragValue = _resetAnimation.value));
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = 60.0;
    const double knobSize = 50.0;
    const double padding = 5.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - knobSize - (padding * 2);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Slate 900
            borderRadius: BorderRadius.circular(999), // Token pill
            border: Border.all(color: const Color(0xFF334155), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Piste verte progressive
              Container(
                width: _dragValue + knobSize + padding,
                height: height,
                decoration: BoxDecoration(
                  color: widget.activeColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // 2. Texte d'incitation avec Shimmer
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragValue / maxDrag) * 1.5).clamp(0.0, 1.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: widget.activeColor,
                    period: const Duration(milliseconds: 1800),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.chevrons_right,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Poignée de glissement (Knob) >= 50px
              Positioned(
                left: padding + _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => _handleDragUpdate(d, maxDrag),
                  onHorizontalDragEnd: (d) => _handleDragEnd(d, maxDrag),
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.activeColor,
                          widget.activeColor.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isConfirmed
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              LucideIcons.arrow_right,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
