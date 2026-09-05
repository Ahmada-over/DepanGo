import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step3Request extends StatefulWidget {
  final VoidCallback onNext;
  const Step3Request({super.key, required this.onNext});

  @override
  State<Step3Request> createState() => _Step3RequestState();
}

class _Step3RequestState extends State<Step3Request> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
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
            "Nouvelle demande",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 40),
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ProTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProTheme.primaryEmerald.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: ProTheme.primaryEmerald.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ProTheme.primaryEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "❄️ Climatisation",
                          style: TextStyle(
                            color: ProTheme.primaryEmerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        "2,4 km",
                        style: TextStyle(
                          color: ProTheme.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "\"Ma climatisation ne refroidit plus.\"",
                    style: TextStyle(
                      fontSize: 16,
                      color: ProTheme.textWhite,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: ProTheme.darkBorder),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Refuser", style: TextStyle(color: ProTheme.textMuted)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: widget.onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProTheme.primaryEmerald,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Accepter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
