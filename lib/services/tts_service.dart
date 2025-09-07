import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts tts = FlutterTts();

  Future<void> speak(String text) async {
    await tts.setVolume(1);
    await tts.setSpeechRate(1);
    await tts.setPitch(1);
    await tts.awaitSpeakCompletion(true);

    if (text.isNotEmpty) {
      await tts.speak(text);
    }
  }

  void stop() => tts.stop();
  void pause() => tts.pause();
}
