import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_content.dart';
import '../services/learning_service.dart';
import 'all_phrases_screen.dart';
import 'lesson_screen.dart';

/// Level map: shows the full curriculum and the lesson progress.
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<LearningService>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        _ProgressHeader(service: progress),
        const SizedBox(height: 12),
        const _ReviewCard(),
        const SizedBox(height: 12),
        ...learningLevels.map(
          (level) => _LevelCard(level: level, service: progress),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF003D33)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Repaso general',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$totalLearningSentences frases',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '10 frases al azar de todos los niveles: si las resolvés, sabés todo el curso.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF004D40),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final reviewLevel = buildReviewLevel(count: 10);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonScreen(
                          level: reviewLevel,
                          lesson: reviewLevel.lessons.first,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Practicar'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AllPhrasesScreen(),
                    ),
                  );
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final LearningService service;

  const _ProgressHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    final nextLesson = service.recommendedLesson;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tu progreso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${service.xp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${service.completedLessons} de ${service.totalLessons} lecciones completadas',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: service.overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            ),
          ),
          if (nextLesson != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D47A1),
                ),
                onPressed: () {
                  final level = learningLevels.firstWhere(
                    (l) => l.lessons.any((lesson) => lesson.id == nextLesson.id),
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(level: level, lesson: nextLesson),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('Continuar: ${nextLesson.title}'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Text(
              '¡Completaste todos los niveles! Seguí practicando con el traductor.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LearningLevel level;
  final LearningService service;

  const _LevelCard({required this.level, required this.service});

  @override
  Widget build(BuildContext context) {
    final completed = service.completedInLevel(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue.withValues(alpha: 0.25),
          child: Text(
            '${level.number}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
          ),
        ),
        title: Text(
          level.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${level.cefr} • $completed/${level.lessons.length} lecciones\n${level.description}',
          style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
        ),
        children: [
          for (final lesson in level.lessons)
            _LessonTile(level: level, lesson: lesson, service: service),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white54,
              size: 20,
            ),
            title: const Text(
              'Ver todas las frases',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            trailing: Text(
              '${level.lessons.fold<int>(0, (sum, lesson) => sum + lesson.sentences.length)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AllPhrasesScreen(level: level),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LearningLevel level;
  final LearningLesson lesson;
  final LearningService service;

  const _LessonTile({
    required this.level,
    required this.lesson,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final done = service.isLessonCompleted(lesson.id);

    return ListTile(
      dense: true,
      leading: Icon(
        done ? Icons.check_circle : Icons.play_circle_outline,
        color: done ? Colors.greenAccent : Colors.lightBlueAccent,
      ),
      title: Text(lesson.title),
      subtitle: Text(
        lesson.goal,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Text(
        done ? '${service.bestScore(lesson.id)}%' : '${lesson.sentences.length} frases',
        style: TextStyle(
          color: done ? Colors.greenAccent : Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LessonScreen(level: level, lesson: lesson),
          ),
        );
      },
    );
  }
}
