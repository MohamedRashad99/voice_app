import 'dart:async';
import 'dart:math';
import '../models/message.dart';

/// ChatService provides the chat logic.
/// In production, replace _generateResponse with an actual API call
/// (e.g., OpenAI, Anthropic Claude, etc.).
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _random = Random();

  static const List<String> _greetings = [
    'Hello! How can I assist you today?',
    'Hi there! I\'m your AI assistant. What\'s on your mind?',
    'Hey! Ready to help. What can I do for you?',
  ];

  static const Map<String, String> _responses = {
    'hello': 'Hello! Great to meet you. How can I help you today?',
    'hi': 'Hi there! What can I assist you with?',
    'how are you':
        'I\'m doing great, thank you for asking! I\'m here and ready to help you with anything you need.',
    'what can you do':
        'I can answer questions, help with writing, explain concepts, analyze text, and much more. I also have a voice feature — you can tap the speaker icon to hear any of my messages read aloud!',
    'voice message':
        'I received your voice message! While I am currently just a demo frontend and cannot process audio to text natively, I will pretend I heard you clearly. 🎤',
    'voice':
        'Yes! I have a built-in voice feature powered by your browser\'s speech synthesis. Just tap the speaker button on any of my messages to hear it. You can pause, resume, and stop playback anytime.',
    'help':
        'Of course! I\'m here to help. You can ask me anything — questions, explanations, creative writing, analysis, or just a friendly chat. Use the voice button to hear my responses aloud!',
    'bye':
        'Goodbye! It was great chatting with you. Feel free to come back anytime. Take care! 👋',
    'thanks':
        'You\'re very welcome! Happy to help. Is there anything else you\'d like to know?',
    'thank you':
        'You\'re absolutely welcome! Don\'t hesitate to ask if you need anything else.',
    'weather':
        'I don\'t have access to real-time weather data, but I\'d recommend checking a weather service like Weather.com or your phone\'s built-in weather app for accurate forecasts!',
    'flutter':
        'Flutter is Google\'s UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. It uses the Dart programming language and is known for its fast performance and expressive UI. This chatbot is built with Flutter!',
    'just_audio':
        'just_audio is a feature-rich Flutter audio package that supports playback from URLs, assets, files, and more. It works across iOS, Android, Web, and desktop. This chatbot uses it to play audio from URLs with full playback controls.',
  };

  /// Simulate an AI response with a short delay.
  Future<ChatMessage> sendMessage(String userText) async {
    // Simulate network/processing delay
    final delay = 800 + _random.nextInt(700);
    await Future.delayed(Duration(milliseconds: delay));

    final response = _generateResponse(userText.toLowerCase().trim());

    return ChatMessage(
      text: response,
      role: MessageRole.assistant,
      // No pre-recorded audio URL; TTS is used instead via browser Speech API
      // If you have a TTS backend, set audioUrl here, e.g.:
      // audioUrl: 'https://your-tts-api.com/synthesize?text=${Uri.encodeComponent(response)}',
    );
  }

  String _generateResponse(String input) {
    // Exact match first
    if (_responses.containsKey(input)) {
      return _responses[input]!;
    }

    // Partial keyword matching
    for (final entry in _responses.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }

    // Greeting fallback
    if (input.isEmpty) {
      return _greetings[_random.nextInt(_greetings.length)];
    }

    // Generic thoughtful responses
    final generic = [
      'That\'s an interesting question! While I\'m a demo assistant with limited knowledge, I\'d be happy to discuss this further. Could you provide more context?',
      'Great point! In a full implementation, I\'d be connected to a powerful language model to give you a detailed answer. For now, I\'m demonstrating the voice and UI features of this chatbot.',
      'I appreciate your message. This is a Flutter web chatbot demo showcasing real-time chat UI with voice playback using just_audio and browser Speech Synthesis. Ask me about Flutter, voice features, or just say hi!',
      'Interesting! This chatbot is built with Flutter and uses just_audio for audio playback. Try tapping the 🔊 speaker button on any of my messages to hear it read aloud!',
      'I\'m a demo AI assistant running in your browser. My voice feature uses the Web Speech API for text-to-speech, and just_audio for audio URL playback. What else would you like to explore?',
    ];

    return generic[_random.nextInt(generic.length)];
  }

  String getGreeting() {
    return _greetings[_random.nextInt(_greetings.length)];
  }
}
