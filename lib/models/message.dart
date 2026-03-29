import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

enum AudioState { idle, loading, playing, paused, error }

class ChatMessage {
  final String id;
  final String text;
  final MessageRole role;
  final DateTime timestamp;

  // Voice/audio fields (only relevant for assistant messages)
  final String? audioUrl;
  AudioState audioState;

  ChatMessage({
    String? id,
    required this.text,
    required this.role,
    DateTime? timestamp,
    this.audioUrl,
    this.audioState = AudioState.idle,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;

  ChatMessage copyWith({
    String? text,
    AudioState? audioState,
    String? audioUrl,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      role: role,
      timestamp: timestamp,
      audioUrl: audioUrl ?? this.audioUrl,
      audioState: audioState ?? this.audioState,
    );
  }
}
