import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Compte à rebours circulaire haute visibilité (Dakar Sunlight Compliant).
/// Conçu pour être lu en moins de 0.5s par un technicien en deux-roues.
class CircularCountdownTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final double size;

  const CircularCountdownTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    // Dégradé néon Dakar : Vert émeraude -> Ambre chaud -> Rouge fluo
    final Color progressColor = progress > 0.45
        ? const Color(0xFF10B981) // Emerald
        : progress > 0.20
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFFEF4444); // Red

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerPainter(progress: progress, progressColor: progressColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$remainingSeconds',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'SEC',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color progressColor;

  _TimerPainter({required this.progress, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Piste de fond sombre
    final trackPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Arc de progression
    final sweepAngle = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Départ à 12h
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.progressColor != progressColor;
}
