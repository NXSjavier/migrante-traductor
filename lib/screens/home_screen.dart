import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';
import '../services/speech_service.dart';
import 'text_translate_screen.dart';
import 'voice_translate_screen.dart';
import 'camera_translate_screen.dart';
import 'phrases_screen.dart';
import 'history_screen.dart';
import 'learning_screen.dart';
import '../widgets/model_download_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TextTranslateScreen(),
    VoiceTranslateScreen(),
    CameraTranslateScreen(),
    PhrasesScreen(),
    LearningScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TranslationService>().initialize();
      context.read<SpeechService>().initialize();
    });
  }

  void _openDownloadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ModelDownloadDialog(),
    );
  }

  void _showLanguagePicker() {
    final service = context.read<TranslationService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Elige idiomas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Hay ${service.languages.length} idiomas disponibles',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Idioma de origen:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: service.languages.entries.map((e) {
                  final selected = service.sourceLanguage == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) async {
                      await service.setLanguages(e.key, service.targetLanguage);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    selectedColor: Colors.blue.withOpacity(0.4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Idioma destino:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: service.languages.entries.map((e) {
                  final selected = service.targetLanguage == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) async {
                      await service.setLanguages(service.sourceLanguage, e.key);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    selectedColor: Colors.blue.withOpacity(0.4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0A0A0A),
              Color(0xFF0D1B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.translate, color: Colors.lightBlueAccent, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Migrante Traductor',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const Text(
                            'Offline • Voz natural • Cámara',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Botón idiomas
                    IconButton(
                      icon: const Icon(Icons.language, color: Colors.white70),
                      onPressed: _showLanguagePicker,
                      tooltip: 'Cambiar idiomas',
                    ),
                    // Botón descargar modelos
                    Consumer<TranslationService>(
                      builder: (context, service, _) {
                        if (service.isModelDownloaded) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.cloud_done, color: Colors.greenAccent, size: 22),
                          );
                        }
                        return IconButton(
                          icon: service.isDownloading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                                )
                              : const Icon(Icons.cloud_download, color: Colors.orangeAccent),
                          onPressed: service.isDownloading ? null : _openDownloadDialog,
                          tooltip: 'Descargar modelos offline',
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Banner descarga
              Consumer<TranslationService>(
                builder: (context, service, _) {
                  if (service.isModelDownloaded) return const SizedBox.shrink();

                  final hasError = service.error != null;
                  final color = hasError ? Colors.redAccent : Colors.orangeAccent;
                  final message = service.isDownloading
                      ? (service.downloadStatus ?? 'Descargando idiomas...')
                      : hasError
                          ? 'No se pudieron descargar los idiomas. Tocá para ver el motivo.'
                          : 'Tocá acá o en la nube para descargar los idiomas y usar sin internet';

                  return GestureDetector(
                    onTap: service.isDownloading ? null : _openDownloadDialog,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasError ? Icons.error_outline : Icons.info_outline,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: TextStyle(color: color, fontSize: 12),
                            ),
                          ),
                          if (!service.isDownloading)
                            Icon(Icons.chevron_right, color: color, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Contenido
              Expanded(child: _screens[_currentIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF111111),
        indicatorColor: Colors.blue.withOpacity(0.25),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.text_fields),
            selectedIcon: Icon(Icons.text_fields, color: Colors.lightBlueAccent),
            label: 'Texto',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic),
            selectedIcon: Icon(Icons.mic, color: Colors.lightBlueAccent),
            label: 'Voz',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            selectedIcon: Icon(Icons.camera_alt, color: Colors.lightBlueAccent),
            label: 'Cámara',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.lightBlueAccent),
            label: 'Frases',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: Colors.lightBlueAccent),
            label: 'Aprender',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Colors.lightBlueAccent),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
