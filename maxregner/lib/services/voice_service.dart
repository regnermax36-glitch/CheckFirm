import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  Future<bool> init() async {
    bool speechEnabled = await _speechToText.initialize();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    return speechEnabled;
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  void listen(Function(String) onResult) async {
    if (await _speechToText.hasPermission) {
      await _speechToText.listen(onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      });
    }
  }

  void stopListening() async {
    await _speechToText.stop();
  }

  bool get isListening => _speechToText.isListening;
}
