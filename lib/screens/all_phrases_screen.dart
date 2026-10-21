import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_content.dart';
import '../services/speech_service.dart';

/// Browse every phrase of the course with audio, optionally limited to a level.
class AllPhrasesScreen extends StatelessWidget {
  final LearningLevel? level;

  const AllPhrasesScreen({super.key, this.level});

  @override
  Widget build(BuildContext context) {
    final levels = level == null ? learningLevels : [level!];

    return Scaffold(
      appBar: AppBar(
        title: Text(level == null ? 'Todas las frases' : level!.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (level == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${totalLearningSentences} frases con audio en español e inglés',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            for (final current in levels) ...[
              if (level == null) ...[
                const SizedBox(height: 8),
                Text(
                  '${current.number}. ${current.title} · ${current.cefr}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              for (final lesson in current.lessons) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                for (final sentence in lesson.sentences)
                  _PhraseCard(sentence: sentence),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  final LearningSentence sentence;

  const _PhraseCard({required this.sentence});

  @override
  Widget build(BuildContext context) {
    final speech = context.read<SpeechService>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sentence.spanish,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () =>
                    speech.speak(sentence.spanish, language: 'es-ES'),
                icon: const Icon(
                  Icons.volume_up,
                  size: 18,
                  color: Colors.white54,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Escuchar en español',
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  sentence.english,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    speech.speak(sentence.english, language: 'en-US'),
                icon: const Icon(
                  Icons.volume_up,
                  size: 18,
                  color: Colors.lightBlueAccent,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Escuchar en inglés',
              ),
            ],
          ),
          if (sentence.tip != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                sentence.tip!,
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
