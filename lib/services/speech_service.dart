import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isAvailable = false;
  bool _autoSpeak = true; // Opción de hablar la traducción automáticamente
  String _lastWords = '';
  String? _error;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isAvailable => _isAvailable;
  bool get autoSpeak => _autoSpeak;
  String get lastWords => _lastWords;
  String? get error => _error;

  void setAutoSpeak(bool value) {
    _autoSpeak = value;
    notifyListeners();
  }

  /// Maps an app language code to the locale id used by speech recognition.
  static String localeFor(String code) {
    switch (code) {
      case 'es':
        return 'es_ES';
      case 'en':
        return 'en_US';
      case 'pt':
        return 'pt_BR';
      case 'fr':
        return 'fr_FR';
      case 'de':
        return 'de_DE';
      case 'it':
        return 'it_IT';
      case 'zh':
        return 'zh_CN';
      case 'ja':
        return 'ja_JP';
      case 'ko':
        return 'ko_KR';
      case 'ru':
        return 'ru_RU';
      case 'ar':
        return 'ar_SA';
      case 'hi':
        return 'hi_IN';
      default:
        return 'en_US';
    }
  }

  Future<void> initialize() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _error = 'Se necesita permiso de micrófono';
        notifyListeners();
        return;
      }

      _isAvailable = await _speech.initialize(
        onError: (error) {
          _error = error.errorMsg;
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_isAvailable) {
        _error = 'El reconocimiento de voz no está disponible. '
            'Instalá o actualizá la app "Google" y volvé a intentar.';
        notifyListeners();
        return;
      }

      // Configuración de voz más natural
      await _tts.setSpeechRate(0.42); // Un poco más lento = más natural
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Intentar usar voz de mejor calidad si está disponible
      try {
        final voices = await _tts.getVoices;
        if (voices != null) {
          // Buscar voces de alta calidad
          final betterVoice = voices.firstWhere(
            (v) =>
                (v['name']?.toString().toLowerCase().contains('enhanced') == true ||
                    v['name']?.toString().toLowerCase().contains('neural') == true ||
                    v['name']?.toString().toLowerCase().contains('premium') == true) &&
                (v['locale']?.toString().startsWith('en') == true ||
                    v['locale']?.toString().startsWith('es') == true),
            orElse: () => voices.firstWhere(
              (v) => v['locale']?.toString().startsWith('en') == true,
              orElse: () => voices.first,
            ),
          );
          if (betterVoice != null) {
            await _tts.setVoice({
              'name': betterVoice['name'],
              'locale': betterVoice['locale'],
            });
          }
        }
      } catch (_) {
        // Si falla, usa la voz por defecto
      }

      _tts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _error = msg;
        notifyListeners();
      });

      notifyListeners();
    } catch (e) {
      _error = 'Error al inicializar voz: $e';
      notifyListeners();
    }
  }

  Future<void> startListening({String localeId = 'es_ES'}) async {
    if (!_isAvailable || _isListening) return;

    _lastWords = '';
    _error = null;
    _isListening = true;
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          notifyListeners();
        },
        localeId: localeId,
        listenMode: stt.ListenMode.dictation, // Mejor para tiempo real
        cancelOnError: true,
        partialResults: true, // Resultados parciales en tiempo real
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      _isListening = false;
      _error = 'No se pudo iniciar el micrófono: $e';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (text.trim().isEmpty) return;

    // Ajustar idioma de la voz
    String ttsLang = language;
    if (language.startsWith('es')) ttsLang = 'es-ES';
    if (language.startsWith('en')) ttsLang = 'en-US';
    if (language.startsWith('pt')) ttsLang = 'pt-BR';
    if (language.startsWith('fr')) ttsLang = 'fr-FR';
    if (language.startsWith('de')) ttsLang = 'de-DE';
    if (language.startsWith('it')) ttsLang = 'it-IT';
    if (language.startsWith('ja')) ttsLang = 'ja-JP';
    if (language.startsWith('ko')) ttsLang = 'ko-KR';
    if (language.startsWith('zh')) ttsLang = 'zh-CN';
    if (language.startsWith('ru')) ttsLang = 'ru-RU';
    if (language.startsWith('ar')) ttsLang = 'ar-SA';
    if (language.startsWith('hi')) ttsLang = 'hi-IN';

    try {
      await _tts.setLanguage(ttsLang);
      await _tts.setSpeechRate(0.42); // Natural
      await _tts.speak(text);
    } catch (e) {
      _error = 'No se pudo reproducir el audio: $e';
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
