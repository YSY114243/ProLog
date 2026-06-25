import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Singleton wrapper around [SpeechToText] for voice dictation.
///
/// Usage:
/// ```dart
/// final svc = SpeechService.instance;
/// final ok = await svc.initialize();
/// if (ok) {
///   svc.startListening((text) => myController.text += text);
/// }
/// ```
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _speech.isListening;

  /// Initialises the speech engine. Returns `true` if available.
  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = true;
    return await _speech.initialize(
      onError: (err) => debugPrint('SpeechService error: ${err.errorMsg}'),
      onStatus: (status) => debugPrint('SpeechService status: $status'),
    );
  }

  /// Begins listening and calls [onResult] with the recognised text so far.
  ///
  /// The callback fires **incrementally** — it receives the full recognised
  /// string on each partial/final update.
  Future<void> startListening({
    required void Function(String recognisedWords) onResult,
    String localeId = 'en_US',
  }) async {
    if (!isAvailable) return;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stops active listening.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancels active listening without keeping partial results.
  Future<void> cancel() async {
    await _speech.cancel();
  }
}
