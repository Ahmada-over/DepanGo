import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step3Match extends StatefulWidget {
  final VoidCallback onNext;
  const Step3Match({super.key, required this.onNext});

  @override
  State<Step3Match> createState() => _Step3MatchState();
}

class _Step3MatchState extends State<Step3Match> with SingleTickerProviderStateMixin {
  bool _isSearching = true;
  bool _found = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    _runSequence();
  }

  void _runSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _found = true;
    });
    _pulseController.stop();

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radar Pulse
                if (_isSearching)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 200 * _pulseController.value,
                        height: 200 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryEmerald.withValues(alpha: 1 - _pulseController.value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                
                // Client Pin
                const Icon(
                  Icons.location_on,
                  color: AppTheme.textDark,
                  size: 40,
                ),

                // Pro Pins
                ...List.generate(5, (index) {
                  final positions = [
                    const Offset(-80, -60),
                    const Offset(60, -90),
                    const Offset(-100, 40),
                    const Offset(80, 50),
                    const Offset(0, 100),
                  ];
                  
                  final isSelected = _found && index == 3; // Let's say index 3 is selected
                  final hideOthers = _found && !isSelected;

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    left: 150 + positions[index].dx,
                    top: 150 + positions[index].dy,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: hideOthers ? 0.0 : 1.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 400),
                        scale: isSelected ? 1.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryEmerald : Colors.grey[300],
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryEmerald.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isSearching
                  ? "Recherche d'un professionnel disponible..."
                  : "Professionnel trouvé.",
              key: ValueKey<bool>(_isSearching),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _found ? AppTheme.primaryEmerald : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
