import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _ttsService = TTSService();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final greeting = _chatService.getGreeting();
    setState(() {
      _messages.add(
        ChatMessage(
          text: greeting,
          role: MessageRole.assistant,
        ),
      );
    });
  }

  Future<void> _onSend(String text, {String? audioUrl}) async {
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text.isEmpty && audioUrl != null ? 'Voice Message' : text,
        role: MessageRole.user,
        audioUrl: audioUrl,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(text, audioUrl: audioUrl);
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(response);
      });
      _scrollToBottom(delay: const Duration(milliseconds: 100));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          role: MessageRole.assistant,
        ));
      });
    }
  }

  void _scrollToBottom({Duration delay = Duration.zero}) {
    Future.delayed(delay, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _clearChat() {
    _ttsService.stop();
    final greeting = _chatService.getGreeting();
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: greeting,
        role: MessageRole.assistant,
      ));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            _Header(onClear: _clearChat),
            _VoiceInfoBanner(tts: _ttsService),
            Expanded(child: _MessageList(
              messages: _messages,
              isTyping: _isTyping,
              scrollController: _scrollController,
            )),
            ChatInput(
              onSend: _onSend,
              enabled: !_isTyping,
            ),
          ],
        ),
      );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClear;
  const _Header({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          // Logo / AI indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7C6CFC), Color(0xFF4A3BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VoiceChat AI',
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online · Voice enabled',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onClear,
            tooltip: 'Clear chat',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceInfoBanner extends StatefulWidget {
  final TTSService tts;
  const _VoiceInfoBanner({required this.tts});

  @override
  State<_VoiceInfoBanner> createState() => _VoiceInfoBannerState();
}

class _VoiceInfoBannerState extends State<_VoiceInfoBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !widget.tts.isSupported) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.accentGlow,
      child: Row(
        children: [
          const Icon(Icons.volume_up_rounded, size: 14, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Voice enabled · Tap 🔊 on any AI message to hear it',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.accentLight,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _dismissed = true),
            icon: const Icon(Icons.close, size: 14, color: AppTheme.accentLight),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0);
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final ScrollController scrollController;

  const _MessageList({
    required this.messages,
    required this.isTyping,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isTyping) {
          return const TypingIndicatorBubble();
        }

        final msg = messages[index];
        // Show avatar only for first in a consecutive group
        final showAvatar = index == 0 ||
            messages[index - 1].role != msg.role;

        return MessageBubble(message: msg, showAvatar: showAvatar);
      },
    );
  }
}
