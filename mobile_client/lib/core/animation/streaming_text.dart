import 'package:flutter/material.dart';
import 'haptic_service.dart';
import 'typing_cursor.dart';

class _TextChunk {
  final String text;
  final bool isNew;
  
  _TextChunk(this.text, {this.isNew = false});
}

/// Affiche du texte en cours de streaming avec animation sur les nouveaux blocs.
/// Utilise un ValueNotifier pour éviter de reconstruire toute la page.
class StreamingText extends StatefulWidget {
  final ValueNotifier<String> textNotifier;
  final ValueNotifier<bool> isStreamingNotifier;
  final TextStyle? style;
  final Color? cursorColor;

  const StreamingText({
    super.key,
    required this.textNotifier,
    required this.isStreamingNotifier,
    this.style,
    this.cursorColor,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  List<_TextChunk> _chunks = [];
  String _lastProcessedText = "";

  @override
  void initState() {
    super.initState();
    _processNewText(widget.textNotifier.value);
    widget.textNotifier.addListener(_onTextChanged);
    widget.isStreamingNotifier.addListener(_onStreamingChanged);
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textNotifier != widget.textNotifier) {
      oldWidget.textNotifier.removeListener(_onTextChanged);
      widget.textNotifier.addListener(_onTextChanged);
      _chunks.clear();
      _lastProcessedText = "";
      _processNewText(widget.textNotifier.value);
    }
    if (oldWidget.isStreamingNotifier != widget.isStreamingNotifier) {
      oldWidget.isStreamingNotifier.removeListener(_onStreamingChanged);
      widget.isStreamingNotifier.addListener(_onStreamingChanged);
    }
  }

  @override
  void dispose() {
    widget.textNotifier.removeListener(_onTextChanged);
    widget.isStreamingNotifier.removeListener(_onStreamingChanged);
    super.dispose();
  }

  void _onStreamingChanged() {
    setState(() {}); // Pour mettre à jour l'affichage du curseur
    
    // Haptic feedback à la fin de la génération
    if (!widget.isStreamingNotifier.value) {
      HapticService.finishGeneration();
      
      // Figer tous les chunks quand c'est fini
      if (_chunks.isNotEmpty && _chunks.last.isNew) {
        final last = _chunks.removeLast();
        _chunks.add(_TextChunk(last.text, isNew: false));
        if (mounted) setState(() {});
      }
    } else {
      HapticService.startGeneration();
    }
  }

  void _onTextChanged() {
    final currentFullText = widget.textNotifier.value;
    if (currentFullText == _lastProcessedText) return;
    
    // Gérer les remplacements complets ou les erreurs de delta
    if (!currentFullText.startsWith(_lastProcessedText)) {
      _chunks = [_TextChunk(currentFullText, isNew: true)];
      _lastProcessedText = currentFullText;
      if (mounted) setState(() {});
      return;
    }

    final delta = currentFullText.substring(_lastProcessedText.length);
    if (delta.isEmpty) return;

    _processNewText(currentFullText);
    HapticService.streamingTick();
  }

  void _processNewText(String fullText) {
    if (fullText.isEmpty) return;
    
    final delta = fullText.substring(_lastProcessedText.length);
    if (delta.isEmpty) return;

    // Figer l'ancien chunk "nouveau"
    if (_chunks.isNotEmpty && _chunks.last.isNew) {
      final last = _chunks.removeLast();
      _chunks.add(_TextChunk(last.text, isNew: false));
    }

    // Regrouper l'ancien texte statique s'il y en a plusieurs
    if (_chunks.length > 1) {
      final staticText = _chunks.where((c) => !c.isNew).map((c) => c.text).join('');
      _chunks.removeWhere((c) => !c.isNew);
      if (staticText.isNotEmpty) {
        _chunks.insert(0, _TextChunk(staticText, isNew: false));
      }
    }

    // Ajouter le nouveau delta
    _chunks.add(_TextChunk(delta, isNew: true));
    
    _lastProcessedText = fullText;
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ?? Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final isStreaming = widget.isStreamingNotifier.value;

    return Text.rich(
      TextSpan(
        children: [
          ..._chunks.map((chunk) {
            if (chunk.isNew && isStreaming) {
              return WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(chunk.text), // Key cruciale pour animer seulement la nouveauté
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 3.0 * (1.0 - value)),
                        child: Text(chunk.text, style: defaultStyle),
                      ),
                    );
                  },
                ),
              );
            } else {
              return TextSpan(
                text: chunk.text,
                style: defaultStyle,
              );
            }
          }),
          // Curseur final
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: TypingCursor(
              isVisible: isStreaming,
              color: widget.cursorColor ?? defaultStyle.color,
              height: (defaultStyle.fontSize ?? 16.0) * 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
