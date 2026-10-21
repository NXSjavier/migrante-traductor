import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_content.dart';

/// Stores learning progress: the best quiz score per lesson.
class LearningService extends ChangeNotifier {
  static const String _storageKey = 'learning_progress_v1';
  static const int passScore = 60;

  final Map<String, int> _bestScores = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static final Set<String> _curriculumIds = {
    for (final level in learningLevels)
      for (final lesson in level.lessons) lesson.id,
  };

  /// Only curriculum lessons count: extra practice sessions (like the mixed
  /// review) can store a score without breaking the progress percentage.
  int get completedLessons =>
      _bestScores.keys.where(_curriculumIds.contains).length;

  int get totalLessons => totalLearningLessons;

  /// XP is the sum of the best score of every completed lesson, so it never
  /// drifts from the stored data.
  int get xp => _bestScores.values.fold(0, (sum, score) => sum + score);

  bool isLessonCompleted(String lessonId) => _bestScores.containsKey(lessonId);

  int bestScore(String lessonId) => _bestScores[lessonId] ?? 0;

  int completedInLevel(LearningLevel level) =>
      level.lessons.where((lesson) => isLessonCompleted(lesson.id)).length;

  double levelProgress(LearningLevel level) =>
      level.lessons.isEmpty ? 0 : completedInLevel(level) / level.lessons.length;

  double get overallProgress =>
      totalLessons == 0 ? 0 : (completedLessons / totalLessons).clamp(0.0, 1.0);

  /// The first lesson that has not been passed yet, used by "Continuar".
  LearningLesson? get recommendedLesson {
    for (final level in learningLevels) {
      for (final lesson in level.lessons) {
        if (!isLessonCompleted(lesson.id)) return lesson;
      }
    }
    return null;
  }

  LearningLesson? lessonById(String id) {
    for (final level in learningLevels) {
      for (final lesson in level.lessons) {
        if (lesson.id == id) return lesson;
      }
    }
    return null;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final scores = decoded['scores'] as Map<String, dynamic>? ?? {};
        _bestScores
          ..clear()
          ..addAll(scores.map((key, value) => MapEntry(key, (value as num).toInt())));
      }
    } catch (e) {
      debugPrint('Could not load learning progress: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> completeLesson(String lessonId, int score) async {
    if (score < passScore) return;

    final previous = _bestScores[lessonId] ?? 0;
    if (score <= previous) return;

    _bestScores[lessonId] = score;
    await _save();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _bestScores.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({'scores': _bestScores});
    await prefs.setString(_storageKey, payload);
  }
}
