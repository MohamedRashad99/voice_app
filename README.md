# 🎙️ Flutter Voice Chatbot (Web)

A Flutter web chatbot with a **dual voice feature**:
1. **TTS Voice** — Browser Speech Synthesis API via `dart:js_interop` (no backend needed)
2. **Audio URL Player** — `just_audio ^0.10.5` for playing remote audio URLs (e.g., from a TTS API)

---

## ✨ Features

- 💬 Real-time chat UI with animated message bubbles
- 🔊 **Voice button** on every AI message (tap to speak, pause, resume, stop)
- 🎵 **just_audio player** embedded in messages when `audioUrl` is set
- ⌨️ Typing indicator animation
- 🌙 Dark theme with accent glow
- 📱 Responsive layout for web

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK **3.x** with web support enabled
- Dart SDK **3.x**
- Chrome / Edge browser (for Web Speech API)

### Install & Run

```bash
# 1. Clone / copy this project
cd flutter_voice_chatbot

# 2. Install dependencies
flutter pub get

# 3. Run on web (Chrome required for SpeechSynthesis + just_audio_web)
flutter run -d chrome
```

### Build for Production

```bash
flutter build web --release
# Output in: build/web/
```

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── message.dart             # ChatMessage model + AudioState enum
├── services/
│   ├── tts_service.dart         # Browser SpeechSynthesis wrapper (dart:js_interop)
│   ├── audio_service.dart       # just_audio AudioPlayer service (ChangeNotifier)
│   └── chat_service.dart        # Chat logic & mock AI responses
├── theme/
│   └── app_theme.dart           # Dark theme, colors, typography
├── widgets/
│   ├── voice_button.dart        # TTS play/pause/resume/stop button
│   ├── audio_url_player.dart    # just_audio URL player widget (seek bar, duration)
│   ├── message_bubble.dart      # Chat message bubble + typing indicator
│   └── chat_input.dart          # Text input + send button
└── screens/
    └── chat_screen.dart         # Main screen (header, messages, input)
```

---

## 🎙️ Voice Feature Details

### Voice Button (TTS)
Every AI message has a **speaker icon** below the bubble.

| State    | Icon               | Action              |
|----------|--------------------|---------------------|
| Idle     | 🔊 Volume icon     | Tap to speak        |
| Playing  | ⏸️ Pause icon (pulsing) | Tap to pause   |
| Paused   | ▶️ Play icon       | Tap to resume       |
| Error    | 🔄 Retry icon      | Tap to retry        |

Uses `window.speechSynthesis` (available in all modern browsers).

### Audio URL Player (just_audio)
If a `ChatMessage.audioUrl` is set, a **mini audio player** appears inside the bubble with:
- Play/Pause button
- Seek slider
- `MM:SS / MM:SS` duration display

To enable, in `chat_service.dart`, set `audioUrl` when creating assistant messages:
```dart
return ChatMessage(
  text: response,
  role: MessageRole.assistant,
  audioUrl: 'https://your-tts-api.com/speak?text=${Uri.encodeComponent(response)}',
);
```

---

## 📦 Key Dependencies

| Package            | Version  | Purpose                          |
|--------------------|----------|----------------------------------|
| `just_audio`       | ^0.10.5  | Audio playback from URLs         |
| `just_audio_web`   | ^0.4.16  | Flutter Web implementation       |
| `provider`         | ^6.1.2   | State management                 |
| `flutter_animate`  | ^4.5.0   | Message animations               |
| `google_fonts`     | ^6.2.1   | Typography                       |
| `intl`             | ^0.19.0  | Timestamp formatting             |
| `uuid`             | ^4.4.0   | Unique message IDs               |

---

## 🔧 Customization

### Connect to a Real AI
In `lib/services/chat_service.dart`, replace `_generateResponse()` with an HTTP call:
```dart
final response = await http.post(
  Uri.parse('https://api.openai.com/v1/chat/completions'),
  headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
  body: jsonEncode({...}),
);
```

### Use a TTS Backend with just_audio
In `sendMessage()`, set `audioUrl` to the TTS endpoint URL. `AudioUrlPlayer` will
automatically pick it up and render a seekable player.

---

## 📝 Notes on just_audio Web

- `just_audio_web` uses the HTML5 `<audio>` element internally
- Supports MP3, OGG, WAV, AAC from remote URLs
- CORS headers must be set on the audio server
- Seeking works if the server supports HTTP range requests
- Volume control is supported on web

---

## 📄 License

MIT — free to use and modify.
