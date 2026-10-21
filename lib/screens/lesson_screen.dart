import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_content.dart';
import '../services/learning_service.dart';
import '../services/speech_service.dart';

enum _Phase { puzzle, result }

enum _PuzzleKind { order, gap, choice }

class _Token {
  final int id;
  final String text;

  const _Token(this.id, this.text);
}

class _Puzzle {
  final LearningSentence sentence;
  final _PuzzleKind kind;

  /// Shuffled tokens for the "order the words" puzzle.
  final List<_Token> tokens;

  /// Sentence with the missing word replaced by a blank, for the gap puzzle.
  final String gapPrompt;

  /// Correct word plus distractors for gap and choice puzzles.
  final List<String> options;

  const _Puzzle({
    required this.sentence,
    required this.kind,
    this.tokens = const [],
    this.gapPrompt = '',
    this.options = const [],
  });
}

/// Puzzle-based lesson: every sentence becomes a small brain teaser.
///
/// 1. Order the words: rebuild the English sentence from shuffled chips.
/// 2. Fill the gap: pick the missing word.
/// 3. Choose: pick the correct translation among four options.
///
/// A lesson is passed with 60% of the puzzles solved without revealing the
/// answer, keeping the progress rules of [LearningService] untouched.
class LessonScreen extends StatefulWidget {
  final LearningLevel level;
  final LearningLesson lesson;

  const LessonScreen({
    super.key,
    required this.level,
    required this.lesson,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  _Phase _phase = _Phase.puzzle;

  late List<_Puzzle> _puzzles;
  int _index = 0;
  bool _solved = false;
  bool _helpUsed = false;
  int _solvedWithoutHelp = 0;

  int _score = 0;
  int _xpGained = 0;

  @override
  void initState() {
    super.initState();
    _puzzles = _buildPuzzles();
  }

  int _seedFrom(String value) =>
      value.codeUnits.fold<int>(7, (acc, unit) => (acc * 31 + unit) & 0x7fffffff);

  List<String> _words(String sentence) => sentence
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  List<_Puzzle> _buildPuzzles() {
    final random = Random(_seedFrom(widget.lesson.id));

    final pool = <String>{};
    for (final level in learningLevels) {
      for (final lesson in level.lessons) {
        for (final sentence in lesson.sentences) {
          pool.addAll(_words(sentence.english));
        }
      }
    }

    final sentences = widget.lesson.sentences;
    return [
      for (var i = 0; i < sentences.length; i++)
        _makePuzzle(sentences[i], i, pool.toList(), random),
    ];
  }

  _Puzzle _makePuzzle(
    LearningSentence sentence,
    int index,
    List<String> pool,
    Random random,
  ) {
    final words = _words(sentence.english);

    final _PuzzleKind kind;
    if (index % 3 == 1 && words.length >= 3) {
      kind = _PuzzleKind.order;
    } else if (index % 3 == 2 && words.length >= 3) {
      kind = _PuzzleKind.gap;
    } else {
      kind = _PuzzleKind.choice;
    }

    switch (kind) {
      case _PuzzleKind.order:
        final tokens = [
          for (var i = 0; i < words.length; i++) _Token(i, words[i]),
        ];
        final correct = tokens.map((token) => token.text).join(' ');
        final shuffled = [...tokens]..shuffle(random);
        var guard = 0;
        while (shuffled.map((token) => token.text).join(' ') == correct &&
            guard++ < 10) {
          shuffled.shuffle(random);
        }
        return _Puzzle(
          sentence: sentence,
          kind: kind,
          tokens: shuffled,
        );

      case _PuzzleKind.gap:
        final gapWord = words.last;
        final similar = pool
            .where((word) =>
                word.toLowerCase() != gapWord.toLowerCase() &&
                !words.contains(word) &&
                (word.length - gapWord.length).abs() <= 3)
            .toSet()
            .toList()
          ..shuffle(random);
        final fallback = pool
            .where((word) =>
                word.toLowerCase() != gapWord.toLowerCase() &&
                !words.contains(word))
            .toSet()
            .toList()
          ..shuffle(random);
        final options = <String>{
          gapWord,
          ...similar.take(3),
          ...fallback,
        }.take(4).toList()
          ..shuffle(random);
        final prompt = '${words.sublist(0, words.length - 1).join(' ')} ____';
        return _Puzzle(
          sentence: sentence,
          kind: kind,
          gapPrompt: prompt,
          options: options,
        );

      case _PuzzleKind.choice:
        final sameLevel = <String>[];
        final others = <String>{};
        for (final level in learningLevels) {
          for (final lesson in level.lessons) {
            for (final candidate in lesson.sentences) {
              if (candidate.english == sentence.english) continue;
              others.add(candidate.english);
              if (level.number == widget.level.number) {
                sameLevel.add(candidate.english);
              }
            }
          }
        }
        final similar = sameLevel
            .where((candidate) =>
                (_words(candidate).length - words.length).abs() <= 2)
            .toList()
          ..shuffle(random);
        final distractors = others.toList()..shuffle(random);
        final options = <String>{
          sentence.english,
          ...similar.take(3),
          ...distractors,
        }.take(4).toList()
          ..shuffle(random);
        return _Puzzle(
          sentence: sentence,
          kind: kind,
          options: options,
        );
    }
  }

  void _speak(String text, {required String language}) {
    context.read<SpeechService>().speak(text, language: language);
  }

  void _onSolved() {
    if (_solved) return;
    setState(() {
      _solved = true;
      if (!_helpUsed) _solvedWithoutHelp++;
    });
  }

  void _revealAnswer() {
    if (_solved) return;
    setState(() {
      _helpUsed = true;
      _solved = true;
    });
  }

  void _nextPuzzle() {
    if (_index + 1 < _puzzles.length) {
      setState(() {
        _index++;
        _solved = false;
        _helpUsed = false;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final total = _puzzles.length;
    final score = total == 0 ? 0 : ((_solvedWithoutHelp / total) * 100).round();

    final service = context.read<LearningService>();
    final previous = service.bestScore(widget.lesson.id);

    setState(() {
      _score = score;
      _xpGained = score > previous ? score - previous : 0;
      _phase = _Phase.result;
    });

    if (score >= LearningService.passScore) {
      service.completeLesson(widget.lesson.id, score);
    }
  }

  void _restartLesson() {
    setState(() {
      _phase = _Phase.puzzle;
      _index = 0;
      _solved = false;
      _helpUsed = false;
      _solvedWithoutHelp = 0;
      _score = 0;
      _xpGained = 0;
    });
    _puzzles = _buildPuzzles();
  }

  LearningLesson? get _nextLesson {
    final lessons = widget.level.lessons;
    final index = lessons.indexWhere((lesson) => lesson.id == widget.lesson.id);
    if (index >= 0 && index + 1 < lessons.length) {
      return lessons[index + 1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: const Color(0xFF0A0A0A),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_phase) {
            _Phase.puzzle => _buildPuzzle(),
            _Phase.result => _buildResult(),
          },
        ),
      ),
    );
  }

  Widget _buildPuzzle() {
    final puzzle = _puzzles[_index];
    final total = _puzzles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Rompecabezas ${_index + 1} de $total',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            if (_helpUsed)
              const Text(
                'con ayuda',
                style: TextStyle(color: Colors.amberAccent, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_index + 1) / total,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.lightBlueAccent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SpanishPrompt(
          text: puzzle.sentence.spanish,
          onSpeak: () =>
              _speak(puzzle.sentence.spanish, language: 'es-ES'),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _solved
              ? _SolvedCard(
                  sentence: puzzle.sentence.english,
                  usedHelp: _helpUsed,
                  onSpeak: () =>
                      _speak(puzzle.sentence.english, language: 'en-US'),
                )
              : switch (puzzle.kind) {
                  _PuzzleKind.order => _OrderPuzzle(
                      key: ValueKey('order-$_index'),
                      tokens: puzzle.tokens,
                      expected: puzzle.sentence.english,
                      onSolved: _onSolved,
                    ),
                  _PuzzleKind.gap => _GapPuzzle(
                      key: ValueKey('gap-$_index'),
                      prompt: puzzle.gapPrompt,
                      correct: puzzle.sentence.english.split(RegExp(r'\s+')).last,
                      options: puzzle.options,
                      onSolved: _onSolved,
                    ),
                  _PuzzleKind.choice => _ChoicePuzzle(
                      key: ValueKey('choice-$_index'),
                      options: puzzle.options,
                      correct: puzzle.sentence.english,
                      onSolved: _onSolved,
                    ),
                },
        ),
        const SizedBox(height: 10),
        if (_solved)
          FilledButton.icon(
            onPressed: _nextPuzzle,
            icon: Icon(
              _index + 1 < total ? Icons.arrow_forward : Icons.flag,
            ),
            label: Text(
              _index + 1 < total ? 'Siguiente rompecabezas' : 'Ver resultado',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          )
        else
          TextButton(
            onPressed: _revealAnswer,
            child: const Text('No me sale: ver la respuesta'),
          ),
      ],
    );
  }

  Widget _buildResult() {
    final passed = _score >= LearningService.passScore;
    final next = _nextLesson;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Icon(
            passed ? Icons.emoji_events : Icons.refresh,
            size: 72,
            color: passed ? Colors.amberAccent : Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            '$_score%',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? '¡Rompecabezas resueltos! $_solvedWithoutHelp de ${_puzzles.length} sin ayuda.'
                : 'Necesitás ${LearningService.passScore}% para completar la lección.\n'
                    'Resolviste $_solvedWithoutHelp de ${_puzzles.length} sin ayuda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: passed ? Colors.greenAccent : Colors.white70,
              height: 1.5,
            ),
          ),
          if (passed && _xpGained > 0) ...[
            const SizedBox(height: 10),
            Text(
              '+$_xpGained XP',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 28),
          if (passed && next != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        LessonScreen(level: widget.level, lesson: next),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text('Siguiente: ${next.title}'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          if (passed && next != null) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _restartLesson,
            icon: const Icon(Icons.replay),
            label: const Text('Repetir lección'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver a los niveles'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SpanishPrompt extends StatelessWidget {
  final String text;
  final VoidCallback onSpeak;

  const _SpanishPrompt({required this.text, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Decilo en inglés',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.35,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSpeak,
            icon: const Icon(
              Icons.volume_up,
              size: 20,
              color: Colors.white54,
            ),
            tooltip: 'Escuchar',
          ),
        ],
      ),
    );
  }
}

class _SolvedCard extends StatelessWidget {
  final String sentence;
  final bool usedHelp;
  final VoidCallback onSpeak;

  const _SolvedCard({
    required this.sentence,
    required this.usedHelp,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final color = usedHelp ? Colors.amberAccent : Colors.greenAccent;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  usedHelp ? Icons.lightbulb_outline : Icons.check_circle,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  usedHelp ? 'Así se dice' : '¡Correcto!',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up, size: 20),
                  color: color,
                  tooltip: 'Escuchar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sentence,
              style: const TextStyle(
                fontSize: 20,
                height: 1.4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _Chip({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(color: onTap == null ? Colors.white38 : color),
      ),
      onPressed: onTap,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: const BorderSide(color: Colors.white24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _OrderPuzzle extends StatefulWidget {
  final List<_Token> tokens;
  final String expected;
  final VoidCallback onSolved;

  const _OrderPuzzle({
    super.key,
    required this.tokens,
    required this.expected,
    required this.onSolved,
  });

  @override
  State<_OrderPuzzle> createState() => _OrderPuzzleState();
}

class _OrderPuzzleState extends State<_OrderPuzzle> {
  late List<_Token> _bank;
  final List<_Token> _placed = [];
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _bank = [...widget.tokens];
  }

  void _place(_Token token) {
    setState(() {
      _bank.remove(token);
      _placed.add(token);
      _wrong = false;
    });

    if (_bank.isEmpty) {
      final answer = _placed.map((token) => token.text).join(' ');
      if (answer == widget.expected) {
        widget.onSolved();
      } else {
        setState(() => _wrong = true);
      }
    }
  }

  void _remove(_Token token) {
    setState(() {
      _placed.remove(token);
      _bank.add(token);
      _wrong = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tocá las palabras en el orden correcto',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 76),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _wrong ? Colors.redAccent : Colors.white12,
              ),
            ),
            child: _placed.isEmpty
                ? const Text(
                    'La oración armada aparece acá.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final token in _placed)
                        _Chip(
                          key: ValueKey('placed-${token.id}'),
                          label: token.text,
                          onTap: () => _remove(token),
                        ),
                    ],
                  ),
          ),
          if (_wrong) ...[
            const SizedBox(height: 8),
            const Text(
              'Ese orden no es. Tocá una palabra de arriba para devolverla.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          if (_bank.isNotEmpty) ...[
            const Text(
              'Palabras',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final token in _bank)
                  _Chip(
                    key: ValueKey('bank-${token.id}'),
                    label: token.text,
                    onTap: () => _place(token),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GapPuzzle extends StatefulWidget {
  final String prompt;
  final String correct;
  final List<String> options;
  final VoidCallback onSolved;

  const _GapPuzzle({
    super.key,
    required this.prompt,
    required this.correct,
    required this.options,
    required this.onSolved,
  });

  @override
  State<_GapPuzzle> createState() => _GapPuzzleState();
}

class _GapPuzzleState extends State<_GapPuzzle> {
  final Set<String> _wrong = {};

  void _select(String option) {
    if (option == widget.correct) {
      widget.onSolved();
      return;
    }
    setState(() => _wrong.add(option));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Elegí la palabra que falta',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
          ),
          child: Text(
            widget.prompt,
            style: const TextStyle(
              fontSize: 20,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in widget.options)
                  _Chip(
                    key: ValueKey('gap-$option'),
                    label: option,
                    onTap: _wrong.contains(option) ? null : () => _select(option),
                    color: _wrong.contains(option)
                        ? Colors.redAccent
                        : Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoicePuzzle extends StatefulWidget {
  final List<String> options;
  final String correct;
  final VoidCallback onSolved;

  const _ChoicePuzzle({
    super.key,
    required this.options,
    required this.correct,
    required this.onSolved,
  });

  @override
  State<_ChoicePuzzle> createState() => _ChoicePuzzleState();
}

class _ChoicePuzzleState extends State<_ChoicePuzzle> {
  final Set<String> _wrong = {};

  void _select(String option) {
    if (option == widget.correct) {
      widget.onSolved();
      return;
    }
    setState(() => _wrong.add(option));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Elegí la traducción correcta',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: widget.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = widget.options[index];
              final isWrong = _wrong.contains(option);

              return InkWell(
                onTap: isWrong ? null : () => _select(option),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isWrong
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isWrong ? Colors.redAccent : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: isWrong ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),
                      if (isWrong)
                        const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 20,
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
