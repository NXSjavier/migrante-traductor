import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';

class CameraTranslateScreen extends StatefulWidget {
  const CameraTranslateScreen({super.key});

  @override
  State<CameraTranslateScreen> createState() => _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends State<CameraTranslateScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  File? _imageFile;
  String _recognizedText = '';
  String _translatedText = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;

    if (source == ImageSource.camera) {
      // The manifest declares CAMERA, so Android requires the runtime grant
      // before launching the camera intent.
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (!status.isGranted) {
        _showMessage(
          status.isPermanentlyDenied
              ? 'Permiso de cámara bloqueado. Activalo en Ajustes > Apps > '
                  'Migrante Traductor > Permisos.'
              : 'Necesitamos permiso de cámara para sacar la foto.',
        );
        return;
      }
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (!mounted || picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _recognizedText = '';
        _translatedText = '';
        _isProcessing = true;
      });

      await _processImage(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMessage(
        source == ImageSource.camera
            ? 'No se pudo abrir la cámara: $e'
            : 'No se pudo abrir la galería: $e',
      );
    }
  }

  Future<void> _processImage(File image) async {
    final translationService = context.read<TranslationService>();

    try {
      final inputImage = InputImage.fromFile(image);
      final recognized = await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      final text = recognized.text.trim();
      if (text.isEmpty) {
        setState(() {
          _recognizedText = 'No se detectó texto en la imagen. '
              'Probá con más luz y la cámara más cerca.';
          _isProcessing = false;
        });
        return;
      }

      setState(() => _recognizedText = text);

      final translated = await translationService.translate(text);
      if (!mounted) return;

      setState(() {
        _translatedText = translated;
        _isProcessing = false;
      });

      context.read<HistoryService>().add(
            original: text,
            translated: translated,
            fromLang: translationService.sourceLanguage,
            toLang: translationService.targetLanguage,
            type: 'camera',
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizedText = 'Error al procesar la imagen: $e';
        _isProcessing = false;
      });
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _imageFile!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          if (_isProcessing) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Text(
              'Leyendo y traduciendo la imagen...',
              style: TextStyle(color: Colors.white70),
            ),
          ],

          const SizedBox(height: 14),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Texto detectado',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _recognizedText.isEmpty
                            ? 'Tomá una foto de un letrero, menú o documento'
                            : _recognizedText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _recognizedText.isEmpty
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
          const SizedBox(height: 12),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
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
                                  ? Icons.stop
                                  : Icons.volume_up,
                              color: Colors.lightBlueAccent,
                              size: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              if (speech.isSpeaking) {
                                speech.stopSpeaking();
                              } else {
                                speech.speak(
                                  _translatedText,
                                  language:
                                      translation.targetLanguage == 'en'
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
                      child: Text(
                        _translatedText.isEmpty
                            ? 'La traducción aparecerá aquí'
                            : _translatedText,
                        style: TextStyle(
                          fontSize: 16,
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
        ],
      ),
    );
  }
}
