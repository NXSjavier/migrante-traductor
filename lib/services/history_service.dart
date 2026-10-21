import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String original;
  final String translated;
  final String fromLang;
  final String toLang;
  final DateTime date;
  final String type; // text, voice, camera

  HistoryItem({
    required this.original,
    required this.translated,
    required this.fromLang,
    required this.toLang,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'original': original,
        'translated': translated,
        'fromLang': fromLang,
        'toLang': toLang,
        'date': date.toIso8601String(),
        'type': type,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        original: json['original'],
        translated: json['translated'],
        fromLang: json['fromLang'],
        toLang: json['toLang'],
        date: DateTime.parse(json['date']),
        type: json['type'],
      );
}

class HistoryService extends ChangeNotifier {
  List<HistoryItem> _items = [];
  static const _key = 'translation_history';

  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _items = raw
        .map((e) => HistoryItem.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> add({
    required String original,
    required String translated,
    required String fromLang,
    required String toLang,
    required String type,
  }) async {
    if (original.trim().isEmpty || translated.trim().isEmpty) return;

    _items.insert(
      0,
      HistoryItem(
        original: original,
        translated: translated,
        fromLang: fromLang,
        toLang: toLang,
        date: DateTime.now(),
        type: type,
      ),
    );

    // Máximo 100 elementos
    if (_items.length > 100) {
      _items = _items.take(100).toList();
    }

    await _save();
    notifyListeners();
  }

  Future<void> remove(int index) async {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }
}
