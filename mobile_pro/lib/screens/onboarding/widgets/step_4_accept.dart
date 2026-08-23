import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step4Accept extends StatefulWidget {
  final VoidCallback onNext;
  const Step4Accept({Key? key, required this.onNext}) : super(key: key);

  @override
  State<Step4Accept> createState() => _Step4AcceptState();
}

class _Step4AcceptState extends State<Step4Accept> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: ProTheme.primaryEmerald, size: 30),
              const SizedBox(width: 12),
              const Text(
                "Mission acceptée",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ProTheme.textWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _fadeController,
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProTheme.darkBorder),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Map Background Line
                  Positioned(
                    child: Container(
                      width: 160,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ProTheme.primaryEmerald.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Pro Position
                  Positioned(
                    left: 40,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ProTheme.primaryEmerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.drive_eta, color: Colors.white, size: 20),
                    ),
                  ),
                  // Client Position
                  Positioned(
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ProTheme.darkSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: ProTheme.textMuted, width: 2),
                      ),
                      child: const Icon(Icons.home, color: ProTheme.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeController,
            child: Column(
              children: [
                const Text(
                  "Direction client",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ProTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "2,4 km • 8 min",
                  style: TextStyle(
                    fontSize: 16,
                    color: ProTheme.primaryEmerald,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
