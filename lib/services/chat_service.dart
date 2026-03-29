import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/message.dart';

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

  // ── Fetch blob URL bytes (works on Flutter Web) ────────────────────────────────
  Future<List<int>> _fetchBlobBytes(String blobUrl) async {
    final response = await Dio().get<List<int>>(
      blobUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Recorded audio is empty.');
    }
    return bytes;
  }

  /// Sends a user text or voice message to the API.
  Future<ChatMessage> sendMessage(String userText, {String? audioUrl}) async {
    String responseText;

    try {
      final dio = Dio();
      Response response;

      if (audioUrl != null && audioUrl.isNotEmpty) {
        // ── Voice message path ──────────────────────────────────────────────────
        // On Flutter Web, the `record` package returns a blob:// URL.
        // We read the bytes directly via the browser's native Fetch API.
        final audioBytes = await _fetchBlobBytes(audioUrl);

        // Detect format from URL; default to webm (opus) which browsers produce.
        String filename = 'voice_note.webm';
        if (audioUrl.contains('.wav')) {
          filename = 'voice_note.wav';
        } else if (audioUrl.contains('.mp3')) {
          filename = 'voice_note.mp3';
        } else if (audioUrl.contains('.m4a') || audioUrl.contains('aac')) {
          filename = 'voice_note.m4a';
        }

        final formData = FormData.fromMap({
          // The API expects a single file field named "file".
          'file': MultipartFile.fromBytes(audioBytes, filename: filename),
          'execute': true,
          'max_rows': 100,
        });

        response = await dio.post(
          'https://ai.erpultimate.com:8000/api/query/voice',
          options: Options(
            headers: {'Accept': 'application/json'},
            contentType: 'multipart/form-data',
          ),
          data: formData,
        );
      } else {
        // ── Text message path ───────────────────────────────────────────────────
        response = await dio.post(
          'https://ai.erpultimate.com:8000/api/query',
          options: Options(headers: {'Content-Type': 'application/json'}),
          data: json.encode({
            'question': userText,
            'execute': true,
            'max_rows': 100,
          }),
        );
      }

      // ── Parse response ────────────────────────────────────────────────────────
      final responseData = response.data;
      if (responseData is Map) {
        final buffer = StringBuffer();

        // 1. Data table rows (if any)
        final data = responseData['data'];
        if (data is List && data.isNotEmpty) {
          // Build a simple readable table from the list of row-maps
          final rows = data.cast<Map>();
          final columns = rows.first.keys.toList();

          // Header
          buffer.writeln('📊 **Results:**');
          for (final row in rows) {
            for (final col in columns) {
              final value = row[col];
              // Format numbers nicely
              String formatted;
              if (value is num) {
                formatted = value
                    .toStringAsFixed(2)
                    .replaceAllMapped(
                      RegExp(r'\B(?=(\d{3})+(?!\d))'),
                      (_) => ',',
                    );
              } else {
                formatted = value?.toString() ?? '-';
              }
              buffer.writeln('• $col: $formatted');
            }
          }
          buffer.writeln();
        }

        // 2. AI insight
        final insight = responseData['ai_insight'];
        if (insight != null && insight.toString().trim().isNotEmpty) {
          buffer.writeln('💡 $insight');
        }

        responseText = buffer.toString().trim().isNotEmpty
            ? buffer.toString().trim()
            : 'No data returned.';
      } else {
        responseText = responseData.toString();
      }
    } catch (e) {
      responseText = '⚠️ Error: $e';
    }

    return ChatMessage(text: responseText, role: MessageRole.assistant);
  }

  String getGreeting() => _greetings[_random.nextInt(_greetings.length)];
}
