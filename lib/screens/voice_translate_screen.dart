import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';

class VoiceTranslateScreen extends StatefulWidget {
  const VoiceTranslateScreen({super.key});

  @override
  State<VoiceTranslateScreen> createState() => _VoiceTranslateScreenState();
}

class _VoiceTranslateScreenState extends State<VoiceTranslateScreen> {
  String _recognizedText = '';
  String _translatedText = '';
  bool _isTranslating = false;
  String _lastTranslatedWords = '';

  SpeechService? _speechService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speechService = context.read<SpeechService>();
      _speechService!.addListener(_onSpeechChanged);
    });
  }

  @override
  void dispose() {
    _speechService?.removeListener(_onSpeechChanged);
    super.dispose();
  }

  /// Translates as soon as the recognizer stops, either because the user
  /// pressed stop or because it detected silence on its own.
  void _onSpeechChanged() {
    if (!mounted) return;

    final speech = _speechService!;
    if (speech.isListening || _isTranslating) return;

    final words = speech.lastWords.trim();
    if (words.isEmpty || words == _lastTranslatedWords) return;

    _lastTranslatedWords = words;
    _doTranslate(words);
  }

  Future<void> _toggleListening() async {
    final speech = context.read<SpeechService>();
    final translation = context.read<TranslationService>();

    if (speech.isListening) {
      await speech.stopListening();
      return;
    }

    if (!speech.isAvailable) {
      _showMessage(
        'El reconocimiento de voz no está disponible en este dispositivo.\n'
        'Instalá o actualizá la app "Google" y volvé a intentar.',
      );
      return;
    }

    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _lastTranslatedWords = '';
    });

    await speech.startListening(
      localeId: SpeechService.localeFor(translation.sourceLanguage),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _doTranslate(String text) async {
    if (!mounted) return;

    final translation = context.read<TranslationService>();
    final speech = context.read<SpeechService>();

    setState(() {
      _recognizedText = text;
      _isTranslating = true;
    });

    try {
      final result = await translation.translate(text);
      if (!mounted) return;

      setState(() => _translatedText = result);

      context.read<HistoryService>().add(
            original: text,
            translated: result,
            fromLang: translation.sourceLanguage,
            toLang: translation.targetLanguage,
            type: 'voice',
          );

      if (speech.autoSpeak) {
        final lang = translation.targetLanguage == 'en'
            ? 'en-US'
            : translation.targetLanguage == 'es'
                ? 'es-ES'
                : SpeechService.localeFor(translation.targetLanguage);
        await speech.speak(result, language: lang);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error al traducir: $e');
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speech = context.watch<SpeechService>();
    final translation = context.watch<TranslationService>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${translation.languages[translation.sourceLanguage]} → '
                    '${translation.languages[translation.targetLanguage]}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => translation.swapLanguages(),
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: Colors.lightBlueAccent,
                    size: 22,
                  ),
                  tooltip: 'Invertir idiomas',
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.record_voice_over,
                      size: 18,
                      color: Colors.white54,
                    ),
                    Switch(
                      value: speech.autoSpeak,
                      onChanged: (value) => speech.setAutoSpeak(value),
                      activeColor: Colors.lightBlueAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            speech.autoSpeak
                ? 'Voz automática: ACTIVADA (habla natural)'
                : 'Voz automática: desactivada',
            style: TextStyle(
              color: speech.autoSpeak ? Colors.greenAccent : Colors.white38,
              fontSize: 12,
            ),
          ),
          if (speech.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                speech.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: speech.isListening
                    ? Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.6),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speech.isListening
                        ? '🔴 Escuchando en tiempo real...'
                        : 'Texto reconocido',
                    style: TextStyle(
                      color: speech.isListening
                          ? Colors.redAccent
                          : Colors.white54,
                      fontSize: 13,
                      fontWeight: speech.isListening
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        speech.isListening
                            ? (speech.lastWords.isEmpty
                                ? 'Hablá ahora...'
                                : speech.lastWords)
                            : (_recognizedText.isEmpty
                                ? 'Tocá el micrófono y hablá.\n'
                                    'Al callarte se traduce solo.'
                                : _recognizedText),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        const Text(
                          'Traducción',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (_translatedText.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              speech.isSpeaking
                                  ? Icons.stop_circle
                                  : Icons.volume_up,
                              color: Colors.lightBlueAccent,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              if (speech.isSpeaking) {
                                speech.stopSpeaking();
                              } else {
                                speech.speak(
                                  _translatedText,
                                  language: translation.targetLanguage == 'en'
                                      ? 'en-US'
                                      : translation.targetLanguage == 'es'
                                          ? 'es-ES'
                                          : SpeechService.localeFor(
                                              translation.targetLanguage,
                                            ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _isTranslating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _translatedText.isEmpty
                                  ? 'La traducción aparece acá y se habla sola '
                                      'si la voz automática está activada'
                                  : _translatedText,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.4,
                                color: _translatedText.isEmpty
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: speech.isListening
                    ? Colors.redAccent
                    : const Color(0xFF1E88E5),
                boxShadow: [
                  BoxShadow(
                    color: (speech.isListening
                            ? Colors.redAccent
                            : Colors.blue)
                        .withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                speech.isListening ? Icons.stop : Icons.mic,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            speech.isListening ? 'Tocá para detener y traducir' : 'Tocá para hablar',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
