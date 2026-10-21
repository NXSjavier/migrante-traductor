import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import '../services/speech_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryService>();
    final speech = context.read<SpeechService>();

    if (history.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Aún no hay traducciones\nen el historial',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Text(
                '${history.items.length} traducciones',
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Borrar historial'),
                      content: const Text('¿Seguro que quieres borrar todo el historial?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () {
                            history.clear();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Borrar', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                label: const Text('Borrar todo', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.items.length,
            itemBuilder: (context, index) {
              final item = history.items[index];
              final time = DateFormat('dd/MM HH:mm').format(item.date);

              return Dismissible(
                key: Key('${item.date.millisecondsSinceEpoch}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => history.remove(index),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.type == 'voice'
                                ? Icons.mic
                                : item.type == 'camera'
                                    ? Icons.camera_alt
                                    : Icons.text_fields,
                            size: 14,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.fromLang.toUpperCase()} → ${item.toLang.toUpperCase()}  •  $time',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 20, color: Colors.lightBlueAccent),
                            onPressed: () => speech.speak(item.translated, language: item.toLang == 'en' ? 'en-US' : 'es-ES'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Colors.white54),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.translated));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copiado'), duration: Duration(seconds: 1)),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item.original, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        item.translated,
                        style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
