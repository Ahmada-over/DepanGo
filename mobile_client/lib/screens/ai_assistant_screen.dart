import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../core/theme.dart';
import '../core/animation/haptic_service.dart';
import '../core/animation/thinking_indicator.dart';
import '../core/animation/animated_send_button.dart';
import '../core/animation/message_entrance_animation.dart';
import '../core/animation/streaming_text.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final ValueNotifier<String> contentNotifier;
  final ValueNotifier<bool> isGeneratingNotifier;
  
  ChatMessage({
    required this.id,
    required this.isUser,
    required String initialContent,
    bool isGenerating = false,
  }) : 
       contentNotifier = ValueNotifier(initialContent),
       isGeneratingNotifier = ValueNotifier(isGenerating);
       
  void dispose() {
    contentNotifier.dispose();
    isGeneratingNotifier.dispose();
  }
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  
  bool _isGenerating = false;
  bool _isThinking = false;
  
  Timer? _streamingTimer;
  ChatMessage? _currentAiMessage;

  // Configuration du scroll automatique
  bool _userHasScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Message de bienvenue initial
    _messages.add(ChatMessage(
      id: 'welcome',
      isUser: false,
      initialContent: "Bonjour ! Je suis l'assistant IA de DepanGo. Comment puis-je vous aider avec votre problème à la maison aujourd'hui ?",
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _streamingTimer?.cancel();
    for (var msg in _messages) {
      msg.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Si l'utilisateur est remonté de plus de 50 pixels par rapport au bas,
    // on désactive le scroll automatique.
    if (maxScroll - currentScroll > 50) {
      _userHasScrolledUp = true;
    } else {
      _userHasScrolledUp = false;
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients || _userHasScrolledUp) return;
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _forceScrollToBottom() {
    _userHasScrolledUp = false;
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toString(),
        isUser: true,
        initialContent: text,
      ));
      _isGenerating = true;
      _isThinking = true;
    });
    
    // Reset scroll tracking and force scroll to bottom for the user message
    _forceScrollToBottom();

    HapticService.startGeneration();

    // Simuler le délai réseau (Thinking state)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted || !_isGenerating) return; // Si arrêté pendant l'attente

    setState(() {
      _isThinking = false;
      _currentAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        initialContent: "",
        isGenerating: true,
      );
      _messages.add(_currentAiMessage!);
    });

    _forceScrollToBottom();

    // Simuler le streaming depuis le backend
    final responseMock = "Je comprends. Laissez-moi analyser la situation... \n\n"
        "Il semblerait qu'il s'agisse d'un problème électrique général. "
        "Avant de faire intervenir un professionnel, veuillez vérifier si le disjoncteur principal n'a pas sauté. "
        "Si ce n'est pas le cas, nous pouvons vous envoyer un électricien qualifié immédiatement.";
        
    final words = responseMock.split(' ');
    int wordIndex = 0;

    _streamingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted || !_isGenerating || _currentAiMessage == null) {
        timer.cancel();
        return;
      }

      if (wordIndex < words.length) {
        final currentText = _currentAiMessage!.contentNotifier.value;
        _currentAiMessage!.contentNotifier.value = currentText + (wordIndex == 0 ? '' : ' ') + words[wordIndex];
        wordIndex++;
        
        // Auto scroll pendant le streaming
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        _finishGeneration();
      }
    });
  }

  void _handleStop() {
    if (!_isGenerating) return;
    _finishGeneration();
  }

  void _finishGeneration() {
    _streamingTimer?.cancel();
    if (_currentAiMessage != null) {
      _currentAiMessage!.isGeneratingNotifier.value = false;
    }
    setState(() {
      _isGenerating = false;
      _isThinking = false;
      _currentAiMessage = null;
    });
    HapticService.finishGeneration();
  }

  Widget _buildMessage(ChatMessage message) {
    return MessageEntranceAnimation(
      key: ValueKey(message.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isUser) ...[
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryEmerald,
                child: Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isUser ? AppTheme.primaryEmerald : Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 20),
                  ),
                ),
                child: message.isUser
                    ? Text(
                        message.contentNotifier.value,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      )
                    : StreamingText(
                        textNotifier: message.contentNotifier,
                        isStreamingNotifier: message.isGeneratingNotifier,
                        style: TextStyle(color: Colors.grey[800], fontSize: 16, height: 1.4),
                        cursorColor: AppTheme.primaryEmerald,
                      ),
              ),
            ),
            
            if (message.isUser) const SizedBox(width: 24), // Balance spacing
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Assistant IA', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 20, top: 10),
                itemCount: _messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _buildMessage(_messages[index]);
                  } else {
                    // Thinking Indicator
                    return MessageEntranceAnimation(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryEmerald,
                              child: Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: const ThinkingIndicator(color: AppTheme.primaryEmerald, size: 8),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: const InputDecoration(
                          hintText: "Décrivez votre problème...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSendButton(
                    isGenerating: _isGenerating,
                    isEnabled: true, // Peut être lié à _textController.text.isNotEmpty si besoin
                    onSend: _handleSend,
                    onStop: _handleStop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
