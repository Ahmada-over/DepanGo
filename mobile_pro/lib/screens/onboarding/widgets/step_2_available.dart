import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step2Available extends StatefulWidget {
  final VoidCallback onNext;
  const Step2Available({Key? key, required this.onNext}) : super(key: key);

  @override
  State<Step2Available> createState() => _Step2AvailableState();
}

class _Step2AvailableState extends State<Step2Available> with SingleTickerProviderStateMixin {
  bool _isAvailable = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _isAvailable = true;
      });
      _pulseController.repeat(reverse: false);
    });

    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) widget.onNext();
    });
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
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isAvailable)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 150 * _pulseController.value,
                        height: 150 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ProTheme.primaryEmerald.withOpacity(1 - _pulseController.value),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isAvailable ? ProTheme.primaryEmerald : ProTheme.darkCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAvailable ? ProTheme.primaryEmerald : ProTheme.darkBorder,
                      width: 4,
                    ),
                    boxShadow: _isAvailable
                        ? [
                            BoxShadow(
                              color: ProTheme.primaryEmerald.withOpacity(0.5),
                              blurRadius: 20,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.power_settings_new,
                    size: 40,
                    color: _isAvailable ? Colors.white : ProTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isAvailable ? "DISPONIBLE" : "HORS LIGNE",
              key: ValueKey<bool>(_isAvailable),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isAvailable ? ProTheme.primaryEmerald : ProTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Vous pouvez recevoir des demandes",
            style: TextStyle(
              fontSize: 16,
              color: ProTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
