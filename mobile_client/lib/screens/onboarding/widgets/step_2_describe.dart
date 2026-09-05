import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class Step2Describe extends StatefulWidget {
  final VoidCallback onNext;
  const Step2Describe({super.key, required this.onNext});

  @override
  State<Step2Describe> createState() => _Step2DescribeState();
}

class _Step2DescribeState extends State<Step2Describe> {
  String _typedText = "";
  final String _fullText = "Ma climatisation ne refroidit plus...";
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    for (int i = 0; i <= _fullText.length; i++) {
      if (!mounted) return;
      setState(() {
        _typedText = _fullText.substring(0, i);
      });
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _showResult = true;
    });

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Décrivez votre problème",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typedText.isEmpty ? " " : _typedText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildActionIcon(Icons.mic, "Parler"),
                        const SizedBox(width: 16),
                        _buildActionIcon(Icons.camera_alt, "Photo"),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          AnimatedOpacity(
            opacity: _showResult ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.arrow_downward, color: Colors.grey),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "❄️ Climatisation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Réparation",
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
