import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

/// AudioPlayerService wraps just_audio's AudioPlayer for use in the chatbot.
/// Each chatbot message can have an audio URL; this service manages a single
/// shared player (one playing at a time) and exposes streams for UI state.
class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  String? _currentMessageId;
  bool _isLoading = false;
  bool _hasError = false;

  String? get currentMessageId => _currentMessageId;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  PlayerState get playerState => _player.playerState;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _player.volumeStream;

  Duration? get duration => _player.duration;
  Duration get position => _player.position;
  double get volume => _player.volume;

  bool get isPlaying => _player.playing;

  bool isPlayingMessage(String messageId) =>
      _currentMessageId == messageId && _player.playing;

  bool isLoadingMessage(String messageId) =>
      _currentMessageId == messageId && _isLoading;

  ProcessingState get processingState => _player.processingState;

  AudioPlayerService() {
    // Listen for completion to auto-reset state
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _currentMessageId = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Play audio from a URL for a specific message.
  /// Stops any currently playing audio first.
  Future<void> playFromUrl(String messageId, String url) async {
    try {
      // If same message is paused, resume
      if (_currentMessageId == messageId &&
          _player.processingState != ProcessingState.idle &&
          !_player.playing) {
        await _player.play();
        notifyListeners();
        return;
      }

      // Stop previous audio
      await _player.stop();

      _currentMessageId = messageId;
      _isLoading = true;
      _hasError = false;
      notifyListeners();

      await _player.setUrl(url);
      _isLoading = false;
      notifyListeners();

      await _player.play();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _currentMessageId = null;
      notifyListeners();
      debugPrint('AudioPlayerService error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentMessageId = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
