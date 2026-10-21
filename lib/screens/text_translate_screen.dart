import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';

class TextTranslateScreen extends StatefulWidget {
  const TextTranslateScreen({super.key});

  @override
  State<TextTranslateScreen> createState() => _TextTranslateScreenState();
}

class _TextTranslateScreenState extends State<TextTranslateScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _translatedText = '';
  bool _isTranslating = false;

  Timer? _debounce;
  Timer? _historyTimer;
  String _lastTranslatedInput = '';
  String _lastSavedInput = '';
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _historyTimer?.cancel();
    _inputController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final text = _inputController.text.trim();

    if (text.isEmpty) {
      _requestId++;
      setState(() {
        _translatedText = '';
        _isTranslating = false;
        _lastTranslatedInput = '';
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _autoTranslate(text),
    );
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _translatedText.isNotEmpty) {
      _commitHistory(_inputController.text.trim(), _translatedText);
    }
  }

  Future<void> _autoTranslate(String text) async {
    final service = context.read<TranslationService>();
    if (text == _lastTranslatedInput) return;

    final requestId = ++_requestId;
    setState(() => _isTranslating = true);

    try {
      final result = await service.translate(text);

      // Ignore stale answers when the user kept typing.
      if (!mounted || requestId != _requestId) return;
      if (_inputController.text.trim() != text) return;

      setState(() {
        _translatedText = result;
        _lastTranslatedInput = text;
      });
      _scheduleHistorySave(text, result);
    } catch (_) {
      // TranslationService keeps the reason in `error`; keep the last result.
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isTranslating = false);
      }
    }
  }

  Future<void> _translateNow() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _debounce?.cancel();

    final service = context.read<TranslationService>();

    if (text == _lastTranslatedInput && _translatedText.isNotEmpty) {
      _commitHistory(text, _translatedText);
      return;
    }

    final requestId = ++_requestId;
    setState(() => _isTranslating = true);

    try {
      final result = await service.translate(text);
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _translatedText = result;
        _lastTranslatedInput = text;
      });
      _commitHistory(text, result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isTranslating = false);
      }
    }
  }

  void _scheduleHistorySave(String original, String translated) {
    _historyTimer?.cancel();
    _historyTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_inputController.text.trim() != original) return;
      _commitHistory(original, translated);
    });
  }

  void _commitHistory(String original, String translated) {
    if (original.isEmpty || translated.isEmpty) return;
    if (_lastSavedInput == original) return;

    _lastSavedInput = original;
    final service = context.read<TranslationService>();
    context.read<HistoryService>().add(
          original: original,
          translated: translated,
          fromLang: service.sourceLanguage,
          toLang: service.targetLanguage,
          type: 'text',
        );
  }

  @override
  Widget build(BuildContext context) {
    final translationService = context.watch<TranslationService>();
    final speechService = context.watch<SpeechService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final available = constraints.maxHeight;

        // Fixed card heights keep the writing area visible when the keyboard
        // covers the screen; the whole page scrolls instead of collapsing.
        final inputHeight = (keyboardOpen ? available * 0.40 : available * 0.34)
            .clamp(160.0, 300.0)
            .toDouble();
        final resultHeight = (keyboardOpen ? available * 0.28 : available * 0.30)
            .clamp(120.0, 260.0)
            .toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LanguageSelector(
                sourceLabel: translationService.languages[
                        translationService.sourceLanguage] ??
                    'Español',
                targetLabel: translationService.languages[
                        translationService.targetLanguage] ??
                    'English',
                onSwap: () {
                  translationService.swapLanguages();
                  setState(() {
                    _translatedText = '';
                    _lastTranslatedInput = '';
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                translationService.isModelDownloaded
                    ? 'Traducción automática offline mientras escribís'
                    : 'Traducción automática por internet (modelos offline sin descargar)',
                style: TextStyle(
                  fontSize: 11,
                  color: translationService.isModelDownloaded
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: inputHeight,
                child: _buildInputCard(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isTranslating ? null : _translateNow,
                icon: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.translate),
                label: Text(_isTranslating ? 'Traduciendo...' : 'Traducir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: resultHeight,
                child: _buildResultCard(translationService, speechService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                const Text(
                  'Escribe aquí...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _inputController.clear();
                    setState(() {
                      _translatedText = '';
                      _lastTranslatedInput = '';
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                  tooltip: 'Borrar',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _inputController.text = data!.text!;
                    }
                  },
                  icon: const Icon(Icons.paste, color: Colors.white54, size: 20),
                  tooltip: 'Pegar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              keyboardAppearance: Brightness.dark,
              cursorColor: Colors.lightBlueAccent,
              scrollPadding: const EdgeInsets.only(bottom: 180),
              style: const TextStyle(
                fontSize: 18,
                height: 1.35,
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: 'Escribí el texto que querés traducir',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    TranslationService translationService,
    SpeechService speechService,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
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
                  style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                ),
                const Spacer(),
                if (_isTranslating)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                if (!_isTranslating && _translatedText.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(
                      speechService.isSpeaking
                          ? Icons.stop
                          : Icons.volume_up,
                      color: Colors.lightBlueAccent,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (speechService.isSpeaking) {
                        speechService.stopSpeaking();
                      } else {
                        final lang =
                            translationService.targetLanguage == 'en'
                                ? 'en-US'
                                : 'es-ES';
                        speechService.speak(_translatedText, language: lang);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      color: Colors.lightBlueAccent,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _translatedText),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copiado al portapapeles'),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _translatedText.isEmpty
                    ? (translationService.error ??
                        'La traducción aparecerá aquí sola')
                    : _translatedText,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: _translatedText.isEmpty
                      ? (translationService.error != null
                          ? Colors.redAccent
                          : Colors.white38)
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String sourceLabel;
  final String targetLabel;
  final VoidCallback onSwap;

  const _LanguageSelector({
    required this.sourceLabel,
    required this.targetLabel,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _LanguageChip(label: sourceLabel)),
          IconButton(
            onPressed: onSwap,
            icon: const Icon(
              Icons.swap_horiz,
              color: Colors.lightBlueAccent,
            ),
            tooltip: 'Invertir idiomas',
          ),
          Expanded(child: _LanguageChip(label: targetLabel)),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;

  const _LanguageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
