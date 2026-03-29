import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  web.SpeechSynthesis? get _synth {
    try {
      return web.window.speechSynthesis;
    } catch (_) {
      return null;
    }
  }

  bool get isSupported {
    return _synth != null;
  }

  List<({String name, String lang})> getVoices() {
    try {
      final s = _synth;
      if (s == null) return [];
      final voices = s.getVoices().toDart;
      final out = <({String name, String lang})>[];
      for (final v in voices) {
        out.add((name: v.name, lang: v.lang));
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  Future<void> speak(
    String text, {
    String? voiceNameFilter,
    double rate = 0.95,
    double pitch = 1.05,
    double volume = 1.0,
  }) {
    final completer = Completer<void>();
    final synth = _synth;

    if (!isSupported || synth == null) {
      completer.completeError('SpeechSynthesis not available.');
      return completer.future;
    }

    synth.cancel();

    final utt = web.SpeechSynthesisUtterance(text);
    utt.rate = rate;
    utt.pitch = pitch;
    utt.volume = volume;

    if (voiceNameFilter != null) {
      try {
        final voices = synth.getVoices().toDart;
        for (final v in voices) {
          if (v.name.toLowerCase().contains(voiceNameFilter.toLowerCase())) {
            utt.voice = v;
            break;
          }
        }
      } catch (_) {}
    }

    utt.onend = ((web.Event event) {
      if (!completer.isCompleted) completer.complete();
    }).toJS;

    utt.onerror = ((web.Event event) {
      if (completer.isCompleted) return;
      String msg = 'speech-error';
      try {
        final jsObj = event as JSObject;
        msg = jsObj.getProperty('error'.toJS).dartify()?.toString() ?? 'speech-error';
      } catch (_) {}
      
      if (msg == 'interrupted' || msg == 'canceled') {
        completer.complete();
      } else {
        completer.completeError(msg);
      }
    }).toJS;

    synth.speak(utt);
    return completer.future;
  }

  void pause()  { try { _synth?.pause();  } catch (_) {} }
  void resume() { try { _synth?.resume(); } catch (_) {} }
  void stop()   { try { _synth?.cancel(); } catch (_) {} }

  bool get isSpeaking => _synth?.speaking ?? false;
  bool get isPaused   => _synth?.paused ?? false;
}
