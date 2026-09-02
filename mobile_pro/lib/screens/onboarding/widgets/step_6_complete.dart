import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step6Complete extends StatefulWidget {
  final VoidCallback onStart;
  const Step6Complete({super.key, required this.onStart});

  @override
  State<Step6Complete> createState() => _Step6CompleteState();
}

class _Step6CompleteState extends State<Step6Complete> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  bool _showRating = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showRating = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ProTheme.primaryEmerald,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ProTheme.primaryEmerald.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "Intervention terminée",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Vous avez réalisé votre mission avec succès.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: ProTheme.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedOpacity(
            opacity: _showRating ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProTheme.amber.withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: ProTheme.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "4.8",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ProTheme.textWhite,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    "+ 1 intervention",
                    style: TextStyle(
                      color: ProTheme.primaryEmerald,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProTheme.primaryEmerald,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Commencer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
