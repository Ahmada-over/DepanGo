import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shimmer/shimmer.dart';
import '../core/design_tokens.dart';
import '../core/theme.dart';
import '../services/client_haptic_service.dart';

/// Bouton coulissant gestuel pour la validation contractuelle côté Client.
/// Remplace un simple bouton d'acceptation de devis par un geste délibéré et sécurisé.
class SlideToConfirm extends StatefulWidget {
  final Future<void> Function() onConfirmed;
  final String label;
  final String? sublabel;
  final Color activeColor;
  final Color backgroundColor;
  final IconData icon;

  const SlideToConfirm({
    super.key,
    required this.onConfirmed,
    required this.label,
    this.sublabel,
    this.activeColor = AppTheme.primaryEmerald,
    this.backgroundColor = const Color(0xFFF1F5F9), // Slate 100
    this.icon = LucideIcons.arrow_right,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
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
      duration: AppMotion.standard,
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

    // Retour haptique régulier
    if ((nextValue - _lastHapticTick).abs() >= 20) {
      _lastHapticTick = nextValue;
      ClientHapticService.instance.onSoftPulse();
    }

    setState(() => _dragValue = nextValue);
  }

  void _handleDragEnd(DragEndDetails details, double maxDrag) {
    if (_isConfirmed) return;
    if (_dragValue >= maxDrag * 0.82) {
      setState(() {
        _dragValue = maxDrag;
        _isConfirmed = true;
      });
      ClientHapticService.instance.onConfirmed();
      widget.onConfirmed();
    } else {
      _resetAnimation = Tween<double>(begin: _dragValue, end: 0.0).animate(
        CurvedAnimation(parent: _resetController, curve: AppMotion.spring),
      )..addListener(() => setState(() => _dragValue = _resetAnimation.value));
      _resetController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double height = AppTouchTarget.prominent; // 60px
    const double knobSize = 50.0;
    const double padding = 5.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - knobSize - (padding * 2);

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Piste de remplissage progressive
              Container(
                width: _dragValue + knobSize + padding,
                height: height,
                decoration: BoxDecoration(
                  color: widget.activeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),

              // 2. Libellé et shimmer d'incitation
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragValue / maxDrag) * 1.5).clamp(0.0, 1.0),
                  child: Shimmer.fromColors(
                    baseColor: const Color(0xFF0F172A),
                    highlightColor: widget.activeColor,
                    period: const Duration(milliseconds: 2000),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              LucideIcons.chevrons_right,
                              size: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ],
                        ),
                        if (widget.sublabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.sublabel!,
                            style: TextStyle(
                              color: widget.activeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Poignée coulissante (Knob 50px)
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
                          color: widget.activeColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isConfirmed
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 22,
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
