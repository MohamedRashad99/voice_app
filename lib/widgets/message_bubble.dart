import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import 'voice_button.dart';
import 'audio_url_player.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AvatarWidget(isUser: false, visible: showAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _BubbleBody(message: message),
                const SizedBox(height: 4),
                _BubbleFooter(message: message),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _AvatarWidget(isUser: true, visible: showAvatar),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(
          begin: 0.15,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _BubbleBody extends StatelessWidget {
  final ChatMessage message;
  const _BubbleBody({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.userBubble : AppTheme.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: Border.all(
          color: isUser
              ? AppTheme.borderActive.withOpacity(0.5)
              : AppTheme.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? AppTheme.accent.withOpacity(0.08)
                : Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 14.5,
              height: 1.6,
            ),
          ),
          // Show audio URL player if message has a URL
          if (message.hasAudio) ...[
            const SizedBox(height: 10),
            AudioUrlPlayer(
              url: message.audioUrl!,
              messageId: message.id,
            ),
          ],
        ],
      ),
    );
  }
}

class _BubbleFooter extends StatelessWidget {
  final ChatMessage message;
  const _BubbleFooter({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isUser) ...[
          VoiceButton(message: message),
          const SizedBox(width: 6),
        ],
        Text(
          timeStr,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final bool isUser;
  final bool visible;
  const _AvatarWidget({required this.isUser, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 30);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isUser
              ? [AppTheme.accent, const Color(0xFF5848CC)]
              : [const Color(0xFF2A2D3E), const Color(0xFF1C1F2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isUser ? AppTheme.borderActive : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 16,
        color: isUser ? Colors.white : AppTheme.accent,
      ),
    );
  }
}

/// Typing indicator bubble shown while AI is generating response
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );
    _animations = _controllers.asMap().entries.map((e) {
      Future.delayed(Duration(milliseconds: e.key * 160), () {
        if (mounted) e.value.repeat(reverse: true);
      });
      return CurvedAnimation(parent: e.value, curve: Curves.easeInOut);
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AvatarWidget(isUser: false, visible: true),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.aiBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _animations[i],
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, -4 * _animations[i].value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent
                                .withOpacity(0.4 + 0.6 * _animations[i].value),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
