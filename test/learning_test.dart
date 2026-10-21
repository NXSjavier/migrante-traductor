import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:migrante_traductor/models/learning_content.dart';
import 'package:migrante_traductor/services/learning_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curriculum has 8 levels, 4 lessons each and no duplicate ids', () {
    expect(learningLevels.length, 8);

    final ids = <String>{};
    for (final level in learningLevels) {
      expect(level.lessons.length, 4, reason: 'level ${level.number}');

      for (final lesson in level.lessons) {
        expect(lesson.sentences.length, greaterThanOrEqualTo(5));
        expect(
          ids.add(lesson.id),
          isTrue,
          reason: 'duplicate lesson id: ${lesson.id}',
        );

        for (final sentence in lesson.sentences) {
          expect(sentence.spanish.trim(), isNotEmpty);
          expect(sentence.english.trim(), isNotEmpty);
        }
      }
    }

    expect(totalLearningLessons, 32);
    expect(totalLearningSentences, 160);
  });

  test('progress keeps the best score and only passes with 60% or more',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = LearningService();
    await service.load();

    await service.completeLesson('l1-greetings', 40);
    expect(service.isLessonCompleted('l1-greetings'), isFalse);

    await service.completeLesson('l1-greetings', 80);
    expect(service.isLessonCompleted('l1-greetings'), isTrue);
    expect(service.bestScore('l1-greetings'), 80);
    expect(service.xp, 80);

    // A lower score never replaces the best one.
    await service.completeLesson('l1-greetings', 70);
    expect(service.bestScore('l1-greetings'), 80);

    expect(service.completedLessons, 1);
    expect(service.overallProgress, closeTo(1 / 32, 0.0001));
    expect(service.recommendedLesson?.id, 'l1-introduce');
  });
}
