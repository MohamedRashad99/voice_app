import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/app_theme.dart';

/// AudioUrlPlayer uses just_audio to play an audio URL.
/// This widget manages its own AudioPlayer instance tied to a single URL.
/// For messages where audioUrl is provided (e.g., from a TTS backend),
/// this widget renders a mini player with seek, play/pause, and duration.
class AudioUrlPlayer extends StatefulWidget {
  final String url;
  final String messageId;

  const AudioUrlPlayer({
    super.key,
    required this.url,
    required this.messageId,
  });

  @override
  State<AudioUrlPlayer> createState() => _AudioUrlPlayerState();
}

class _AudioUrlPlayerState extends State<AudioUrlPlayer> {
  late final AudioPlayer _player;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    // Defer to post-frame so setState is safe on first call
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPlayer());
  }

  Future<void> _initPlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await _player.setUrl(widget.url);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShell(
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accent,
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildShell(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 14, color: AppTheme.error),
            const SizedBox(width: 6),
            Text(
              'Audio unavailable',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.error.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _initPlayer,
              child: const Icon(Icons.refresh, size: 14, color: AppTheme.accent),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.playing ?? false;
        final processingState = state?.processingState;

        return StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (context, durationSnap) {
            final duration = durationSnap.data ?? Duration.zero;

            return StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                final progress = duration.inMilliseconds > 0
                    ? (position.inMilliseconds / duration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;

                return _buildShell(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Play/Pause button
                      GestureDetector(
                        onTap: () async {
                          if (isPlaying) {
                            await _player.pause();
                          } else {
                            if (processingState == ProcessingState.completed) {
                              await _player.seek(Duration.zero);
                            }
                            await _player.play();
                          }
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent,
                          ),
                          child: Icon(
                            processingState == ProcessingState.loading ||
                                    processingState == ProcessingState.buffering
                                ? Icons.hourglass_empty_rounded
                                : isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Seek bar
                      SizedBox(
                        width: 100,
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10),
                            activeTrackColor: AppTheme.accent,
                            inactiveTrackColor: AppTheme.border,
                            thumbColor: AppTheme.accent,
                            overlayColor: AppTheme.accentGlow,
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (v) {
                              final seekTo = Duration(
                                milliseconds:
                                    (v * duration.inMilliseconds).toInt(),
                              );
                              _player.seek(seekTo);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Duration text
                      Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}
