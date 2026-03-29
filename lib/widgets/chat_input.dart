import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:record/record.dart';
import '../theme/app_theme.dart';

class ChatInput extends StatefulWidget {
  final void Function(String, {String? audioUrl}) onSend;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isRecording = false;
  late final AudioRecorder _audioRecorder;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send({String? audioUrl}) {
    final text = _controller.text.trim();
    if (text.isEmpty && audioUrl == null) return;
    if (!widget.enabled) return;

    widget.onSend(text, audioUrl: audioUrl);
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // stop() returns a blob URL on web (e.g. blob:http://localhost:...)
      final blobUrl = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (blobUrl != null && blobUrl.isNotEmpty) {
        _send(audioUrl: blobUrl);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        // On web, do NOT pass a path — the recorder returns a blob URL automatically.
        // On web, AudioEncoder.aacLc falls back to opus/webm automatically.
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            numChannels: 1,
          ),
          path: '', // empty = use in-memory blob on web
        );
        setState(() => _isRecording = true);
      }
    }
  }

  void _onButtonPressed() {
    if (!widget.enabled) return;
    if (_hasText) {
      _send();
    } else {
      _toggleRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canInteract = widget.enabled;
    final bool isActiveAction = _hasText || _isRecording;

    IconData buttonIcon;
    if (_hasText) {
      buttonIcon = Icons.arrow_upward_rounded;
    } else {
      buttonIcon = _isRecording ? Icons.stop_rounded : Icons.mic_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  if (_hasText) _send();
                }
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: canInteract && !_isRecording,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: _isRecording
                      ? '🎙 Recording... tap stop to send'
                      : (canInteract ? 'Type a message...' : 'AI is thinking...'),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: _isRecording ? AppTheme.error : AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  suffixIcon: _hasText
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              size: 16, color: AppTheme.textMuted),
                          onPressed: _controller.clear,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: canInteract ? _onButtonPressed : null,
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (isActiveAction && canInteract && !_isRecording)
                      ? const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF5848CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !canInteract
                      ? AppTheme.surfaceElevated
                      : _isRecording
                          ? AppTheme.error.withOpacity(0.85)
                          : (isActiveAction ? null : AppTheme.surfaceElevated),
                  boxShadow: (isActiveAction && canInteract)
                      ? [
                          BoxShadow(
                            color: _isRecording
                                ? AppTheme.error.withOpacity(0.4)
                                : AppTheme.accent.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  buttonIcon,
                  size: 20,
                  color: (isActiveAction && canInteract)
                      ? Colors.white
                      : AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
