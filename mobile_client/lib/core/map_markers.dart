import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'theme.dart';

enum MapMarkerType {
  clientDot,
  destination,
  technicianMoto,
  technicianCar,
}

/// Marqueurs cartographiques custom — style épuré, icônes réalistes.
class MapMarkerIcons {
  MapMarkerIcons._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<void> preload() async {
    await Future.wait([
      for (final type in MapMarkerType.values) get(type),
    ]);
  }

  static Future<BitmapDescriptor> get(MapMarkerType type) async {
    final key = type.name;
    if (_cache.containsKey(key)) return _cache[key]!;

    final bytes = await _renderToPng(type, size: 120);
    final icon = BitmapDescriptor.bytes(bytes);
    _cache[key] = icon;
    return icon;
  }

  static Future<BitmapDescriptor> forTransport(String transportMode) {
    return get(
      transportMode == 'voiture'
          ? MapMarkerType.technicianCar
          : MapMarkerType.technicianMoto,
    );
  }

  static Widget flutterMarker(
    MapMarkerType type, {
    double size = 52,
    VoidCallback? onTap,
  }) {
    final child = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MapMarkerPainter(type: type),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }

  static Future<Uint8List> _renderToPng(
    MapMarkerType type, {
    required double size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _MapMarkerPainter(type: type).paint(canvas, Size(size, size));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _MapMarkerPainter extends CustomPainter {
  const _MapMarkerPainter({required this.type});

  final MapMarkerType type;

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case MapMarkerType.clientDot:
        _paintClientDot(canvas, size);
      case MapMarkerType.destination:
        _paintDestinationPin(canvas, size);
      case MapMarkerType.technicianMoto:
        _paintTechnicianBadge(canvas, size, isCar: false);
      case MapMarkerType.technicianCar:
        _paintTechnicianBadge(canvas, size, isCar: true);
    }
  }

  void _paintClientDot(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      size.width * 0.38,
      Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      size.width * 0.22,
      Paint()
        ..color = const Color(0xFF3B82F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      center,
      size.width * 0.12,
      Paint()..color = const Color(0xFF2563EB),
    );
  }

  void _paintDestinationPin(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pinTop = h * 0.08;

    _drawSoftShadow(
      canvas,
      Path()
        ..addOval(Rect.fromCenter(
          center: Offset(w / 2, h * 0.82),
          width: w * 0.28,
          height: h * 0.08,
        )),
      blur: 6,
    );

    final pinPath = Path()
      ..moveTo(w / 2, h * 0.92)
      ..cubicTo(w * 0.18, h * 0.58, w * 0.18, h * 0.22, w / 2, pinTop + w * 0.18)
      ..cubicTo(w * 0.82, h * 0.22, w * 0.82, h * 0.58, w / 2, h * 0.92)
      ..close();

    canvas.drawPath(
      pinPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w / 2, pinTop),
          Offset(w / 2, h * 0.9),
          [AppTheme.primaryEmerald, AppTheme.primaryDark],
        ),
    );

    canvas.drawCircle(
      Offset(w / 2, pinTop + w * 0.22),
      w * 0.19,
      Paint()..color = Colors.white,
    );

    _drawHouseIcon(canvas, Offset(w / 2, pinTop + w * 0.22), w * 0.11);
  }

  void _paintTechnicianBadge(Canvas canvas, Size size, {required bool isCar}) {
    final w = size.width;
    final h = size.height;
    final accent = isCar ? const Color(0xFF2563EB) : AppTheme.primaryEmerald;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.68),
      Radius.circular(w * 0.16),
    );

    _drawSoftShadow(canvas, Path()..addRRect(cardRect), blur: 10);

    canvas.drawRRect(
      cardRect,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final accentRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.08, h * 0.68),
      const Radius.circular(12),
    );
    canvas.drawRRect(accentRect, Paint()..color = accent);

    if (isCar) {
      _drawCarIcon(canvas, Offset(w * 0.56, h * 0.46), w * 0.22, accent);
    } else {
      _drawMotoIcon(canvas, Offset(w * 0.56, h * 0.46), w * 0.24, accent);
    }

    canvas.drawCircle(
      Offset(w * 0.56, h * 0.88),
      w * 0.05,
      Paint()..color = accent,
    );
    canvas.drawCircle(
      Offset(w * 0.56, h * 0.88),
      w * 0.025,
      Paint()..color = Colors.white,
    );
  }

  void _drawSoftShadow(Canvas canvas, Path path, {double blur = 8}) {
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  void _drawHouseIcon(Canvas canvas, Offset center, double s) {
    final paint = Paint()
      ..color = AppTheme.primaryDark
      ..style = PaintingStyle.fill;

    final roof = Path()
      ..moveTo(center.dx, center.dy - s)
      ..lineTo(center.dx + s, center.dy - s * 0.15)
      ..lineTo(center.dx - s, center.dy - s * 0.15)
      ..close();
    canvas.drawPath(roof, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + s * 0.15), width: s * 1.5, height: s * 1.1),
        const Radius.circular(2),
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, center.dy + s * 0.35), width: s * 0.45, height: s * 0.45),
      Paint()..color = Colors.white,
    );
  }

  void _drawMotoIcon(Canvas canvas, Offset center, double s, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.14
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(center.dx - s * 0.55, center.dy + s * 0.35), s * 0.32, paint);
    canvas.drawCircle(Offset(center.dx + s * 0.55, center.dy + s * 0.35), s * 0.32, paint);

    final body = Path()
      ..moveTo(center.dx - s * 0.55, center.dy + s * 0.35)
      ..quadraticBezierTo(center.dx - s * 0.1, center.dy - s * 0.55, center.dx + s * 0.35, center.dy - s * 0.15)
      ..lineTo(center.dx + s * 0.55, center.dy + s * 0.1);
    canvas.drawPath(body, paint);

    canvas.drawLine(
      Offset(center.dx + s * 0.15, center.dy - s * 0.45),
      Offset(center.dx + s * 0.45, center.dy - s * 0.65),
      paint,
    );
  }

  void _drawCarIcon(Canvas canvas, Offset center, double s, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + s * 0.1), width: s * 1.6, height: s * 0.55),
        Radius.circular(s * 0.12),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - s * 0.15), width: s * 0.95, height: s * 0.42),
        Radius.circular(s * 0.1),
      ),
      Paint()..color = color.withValues(alpha: 0.85),
    );

    final wheelPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(center.dx - s * 0.48, center.dy + s * 0.38), s * 0.14, wheelPaint);
    canvas.drawCircle(Offset(center.dx + s * 0.48, center.dy + s * 0.38), s * 0.14, wheelPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - s * 0.18, center.dy - s * 0.15), width: s * 0.22, height: s * 0.18),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + s * 0.18, center.dy - s * 0.15), width: s * 0.22, height: s * 0.18),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _MapMarkerPainter oldDelegate) =>
      oldDelegate.type != type;
}

/// Pin central fixe pour l'écran de sélection d'adresse.
class MapCenterPin extends StatelessWidget {
  final bool isDragging;

  const MapCenterPin({super.key, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, isDragging ? -10 : 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 56,
            child: CustomPaint(
              painter: _MapMarkerPainter(type: MapMarkerType.destination),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isDragging ? 10 : 14,
            height: isDragging ? 4 : 6,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: isDragging ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton flottant uniforme sur les cartes.
class MapFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const MapFloatingButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.textDark, size: 20),
        ),
      ),
    );
  }
}

/// Carte info flottante minimaliste.
class MapInfoChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const MapInfoChip({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryEmerald, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
