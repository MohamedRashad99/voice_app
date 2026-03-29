import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/message.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// VoiceButton handles TTS playback for a single chat message.
/// It manages its own local state (idle / loading / playing / paused / error)
/// and drives the browser's SpeechSynthesis API through [TTSService].
class VoiceButton extends StatefulWidget {
  final ChatMessage message;

  const VoiceButton({super.key, required this.message});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  final _tts = TTSService();
  AudioState _audioState = AudioState.idle;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Stop TTS when widget disposes (e.g., widget removed from tree)
    if (_audioState == AudioState.playing || _audioState == AudioState.loading) {
      _tts.stop();
    }
    super.dispose();
  }

  Future<void> _onTap() async {
    if (!_tts.isSupported) {
      _showUnsupportedSnackbar();
      return;
    }

    switch (_audioState) {
      case AudioState.idle:
      case AudioState.error:
        await _startSpeech();
        break;
      case AudioState.playing:
        _pauseSpeech();
        break;
      case AudioState.paused:
        _resumeSpeech();
        break;
      case AudioState.loading:
        // Do nothing while loading
        break;
    }
  }

  Future<void> _startSpeech() async {
    if (!mounted) return;
    setState(() => _audioState = AudioState.loading);

    try {
      // Brief yield so loading state renders before speech starts
      await Future.microtask(() {});
      if (!mounted) return;
      setState(() => _audioState = AudioState.playing);

      await _tts.speak(
        widget.message.text,
        rate: 0.95,
        pitch: 1.05,
      );
      // Speech completed naturally
      if (mounted) setState(() => _audioState = AudioState.idle);
    } catch (e) {
      if (mounted) setState(() => _audioState = AudioState.error);
    }
  }

  void _pauseSpeech() {
    _tts.pause();
    setState(() => _audioState = AudioState.paused);
  }

  void _resumeSpeech() {
    _tts.resume();
    setState(() => _audioState = AudioState.playing);
  }

  void _showUnsupportedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice not supported in this browser.'),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildIcon() {
    switch (_audioState) {
      case AudioState.loading:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent,
          ),
        );
      case AudioState.playing:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Icon(
              Icons.pause_rounded,
              size: 17,
              color: Color.lerp(
                  AppTheme.accent, AppTheme.accentLight, _pulseController.value),
            );
          },
        );
      case AudioState.paused:
        return const Icon(
          Icons.play_arrow_rounded,
          size: 17,
          color: AppTheme.accentLight,
        );
      case AudioState.error:
        return const Icon(
          Icons.refresh_rounded,
          size: 17,
          color: AppTheme.warning,
        );
      case AudioState.idle:
        return const Icon(
          Icons.volume_up_rounded,
          size: 17,
          color: AppTheme.textSecondary,
        );
    }
  }

  String _tooltip() {
    switch (_audioState) {
      case AudioState.idle:
        return 'Listen to this message';
      case AudioState.loading:
        return 'Loading audio...';
      case AudioState.playing:
        return 'Pause';
      case AudioState.paused:
        return 'Resume';
      case AudioState.error:
        return 'Retry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive =
        _audioState == AudioState.playing || _audioState == AudioState.paused;

    return Tooltip(
      message: _tooltip(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? AppTheme.accentGlow : Colors.transparent,
          border: Border.all(
            color: isActive ? AppTheme.accent : AppTheme.border,
            width: 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(99),
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: _buildIcon(),
            ),
          ),
        ),
      )
          .animate(target: isActive ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08)),
    );
  }
}
