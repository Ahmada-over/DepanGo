import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step5Navigation extends StatefulWidget {
  final VoidCallback onNext;
  const Step5Navigation({super.key, required this.onNext});

  @override
  State<Step5Navigation> createState() => _Step5NavigationState();
}

class _Step5NavigationState extends State<Step5Navigation> with SingleTickerProviderStateMixin {
  late AnimationController _carController;
  int _eta = 8;

  @override
  void initState() {
    super.initState();
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _carController.addListener(() {
      final newEta = 8 - (_carController.value * 8).round();
      if (newEta != _eta && mounted) {
        setState(() {
          _eta = newEta;
        });
      }
    });

    _carController.forward();
    
    _carController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) widget.onNext();
        });
      }
    });
  }

  @override
  void dispose() {
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _eta == 0 ? "Arrivé" : "En route",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _eta == 0 ? ProTheme.primaryEmerald : ProTheme.textWhite,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _eta == 0 ? "Vous êtes sur place" : "$_eta min restantes",
              key: ValueKey<int>(_eta),
              style: const TextStyle(
                fontSize: 18,
                color: ProTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Route Line
                Positioned(
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: ProTheme.darkCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Animated Route Progress
                Positioned(
                  left: 40,
                  child: AnimatedBuilder(
                    animation: _carController,
                    builder: (context, child) {
                      return Container(
                        height: 4,
                        width: (MediaQuery.of(context).size.width - 128) * _carController.value,
                        decoration: BoxDecoration(
                          color: ProTheme.primaryEmerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
                
                // Client Home
                Positioned(
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ProTheme.darkSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: _eta == 0 ? ProTheme.primaryEmerald : ProTheme.textMuted, width: 2),
                    ),
                    child: Icon(Icons.home, color: _eta == 0 ? ProTheme.primaryEmerald : ProTheme.textMuted, size: 24),
                  ),
                ),
                
                // Pro Car
                AnimatedBuilder(
                  animation: _carController,
                  builder: (context, child) {
                    final double screenWidth = MediaQuery.of(context).size.width - 128; // padding
                    final double leftOffset = 40 + (screenWidth * _carController.value) - 20; // center car
                    return Positioned(
                      left: leftOffset,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ProTheme.primaryEmerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: ProTheme.primaryEmerald.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.drive_eta, color: Colors.white, size: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
