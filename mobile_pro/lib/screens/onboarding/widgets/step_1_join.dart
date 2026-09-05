import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step1Join extends StatefulWidget {
  final VoidCallback onNext;
  const Step1Join({super.key, required this.onNext});

  @override
  State<Step1Join> createState() => _Step1JoinState();
}

class _Step1JoinState extends State<Step1Join> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onNext();
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
            "Développez votre activité avec DepanGo.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Recevez des demandes de clients à proximité lorsque vous êtes disponible.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: ProTheme.textMuted,
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pro Central D Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: ProTheme.primaryEmerald,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "D",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Floating Demands
                ...List.generate(4, (index) {
                  final demands = ["Plomberie", "Clim", "Méca", "Élec"];
                  final positions = [
                    const Offset(-80, -70),
                    const Offset(80, -40),
                    const Offset(-90, 60),
                    const Offset(70, 80),
                  ];
                  
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final progress = ((_controller.value - delay) / 0.5).clamp(0.0, 1.0);
                      
                      return Positioned(
                        left: 150 + (positions[index].dx * progress) - 40,
                        top: 125 + (positions[index].dy * progress) - 20,
                        child: Opacity(
                          opacity: progress,
                          child: Transform.scale(
                            scale: 0.5 + (progress * 0.5),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: ProTheme.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ProTheme.darkBorder),
                      ),
                      child: Text(
                        demands[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: ProTheme.textMuted,
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
