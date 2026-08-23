import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step4Route extends StatefulWidget {
  final VoidCallback onNext;
  const Step4Route({Key? key, required this.onNext}) : super(key: key);

  @override
  State<Step4Route> createState() => _Step4RouteState();
}

class _Step4RouteState extends State<Step4Route> with SingleTickerProviderStateMixin {
  late AnimationController _carController;

  @override
  void initState() {
    super.initState();
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
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
          const Text(
            "Professionnel en route",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.timer, size: 16, color: AppTheme.textMuted),
                SizedBox(width: 8),
                Text(
                  "8 min",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                SizedBox(width: 16),
                Icon(Icons.route, size: 16, color: AppTheme.textMuted),
                SizedBox(width: 8),
                Text(
                  "2,4 km",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
              ],
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
                      color: Colors.grey[300],
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
                          color: AppTheme.primaryEmerald,
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
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: const Text("🏠", style: TextStyle(fontSize: 24)),
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
                          color: AppTheme.primaryEmerald,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryEmerald.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Text("🚗", style: TextStyle(fontSize: 20)),
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
