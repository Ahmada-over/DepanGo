import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step1Problem extends StatefulWidget {
  final VoidCallback onNext;
  const Step1Problem({Key? key, required this.onNext}) : super(key: key);

  @override
  State<Step1Problem> createState() => _Step1ProblemState();
}

class _Step1ProblemState extends State<Step1Problem> with SingleTickerProviderStateMixin {
  final List<String> services = [
    "Plomberie",
    "Électricité",
    "Climatisation",
    "Automobile",
    "Entretien"
  ];
  
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
    
    // Auto-advance after animation + a small delay
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        widget.onNext();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Un problème ?",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Central icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.build_circle_rounded,
                    color: AppTheme.primaryEmerald,
                    size: 40,
                  ),
                ),
                // Floating services
                ...List.generate(services.length, (index) {
                  // Calculate positions in a circle
                  final double angle = (index * (360 / services.length)) * 3.14159 / 180;
                  final double radius = 100.0;
                  
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final progress = ((_controller.value - delay) / 0.5).clamp(0.0, 1.0);
                      
                      return Transform.translate(
                        offset: Offset(
                          radius * 0.9 * (index == 0 ? 0 : (index == 1 ? 1 : (index == 2 ? 0.5 : (index == 3 ? -1 : -0.5)))),
                          radius * 0.9 * (index == 0 ? -1 : (index == 1 ? -0.2 : (index == 2 ? 0.8 : (index == 3 ? 0.2 : 0.8))))
                        ),
                        child: Opacity(
                          opacity: progress,
                          child: Transform.scale(
                            scale: 0.8 + (progress * 0.2),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        services[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
