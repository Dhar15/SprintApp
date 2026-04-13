import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/word_model.dart';
import '../../../core/utils/storage_service.dart';

class WordSprintService {
  static const int sessionSize = 12;
  static const int quizSize = 8;

  // Free Dictionary API — no key required
  static const String _dictApiBase =
      'https://api.dictionaryapi.dev/api/v2/entries/en/';

  List<String> _wordList = [];      // just the words (from word_list.json)
  List<WordModel> _cachedWords = []; // fetched + cached definitions
  bool _listLoaded = false;

  // ── Load word list (just strings) ─────────────────────────────────────────

  Future<void> _loadWordList() async {
    if (_listLoaded) return;
    final raw = await rootBundle.loadString('assets/data/word_list.json');
    _wordList = List<String>.from(jsonDecode(raw));
    _listLoaded = true;
  }

  // ── Fetch definition for a single word from Free Dictionary API ───────────

  Future<WordModel?> _fetchDefinition(String word) async {
    // 1. Check local persistent cache first
    final storage = StorageService.instance;
    final cached = storage.getCachedWordDefinition(word);
    if (cached != null) return cached;

    try {
      final uri = Uri.parse('$_dictApiBase${Uri.encodeComponent(word.toLowerCase())}');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) return null;

      final model = WordModel.fromDictionaryApi(word, data.first as Map<String, dynamic>);

      // Persist to cache so we never re-fetch
      await storage.cacheWordDefinition(model);
      return model;

    } catch (_) {
      return null;
    }
  }

  // ── Build a session: pick words, fetch definitions in parallel ────────────

  Future<List<WordModel>> getSessionWords() async {
    await _loadWordList();
    final storage = StorageService.instance;
    final seen = storage.getSeenWords();

    final newWords = _wordList.where((w) => !seen.contains(w)).toList();
    final oldWords = _wordList.where((w) => seen.contains(w)).toList();

    final rng = Random();
    newWords.shuffle(rng);
    oldWords.shuffle(rng);

    // 70% new, 30% revisit
    final newCount = min((sessionSize * 0.7).ceil(), newWords.length);
    final oldCount = min(sessionSize - newCount, oldWords.length);

    final selected = [
      ...newWords.take(newCount),
      ...oldWords.take(oldCount),
    ]..shuffle(rng);

    // Fetch all definitions in parallel (cached ones return instantly)
    final futures = selected.map((w) => _fetchDefinition(w));
    final results = await Future.wait(futures);

    // Filter out any words that completely failed to resolve
    final resolved = <WordModel>[];
    for (int i = 0; i < results.length; i++) {
      if (results[i] != null) {
        resolved.add(results[i]!);
        _cachedWords.add(results[i]!);
      }
    }

    // If we got fewer than 4 words (very bad network), surface cached pool
    if (resolved.length < 4) {
      final fallback = storage.getAllCachedWords();
      fallback.shuffle(rng);
      for (final w in fallback) {
        if (!resolved.any((r) => r.word == w.word)) {
          resolved.add(w);
        }
        if (resolved.length >= sessionSize) break;
      }
    }

    return resolved.take(sessionSize).toList();
  }

  // ── Quiz generation ────────────────────────────────────────────────────────
  List<QuizQuestion> generateQuiz(List<WordModel> sessionWords) {
  final rng = Random();
  final pool = [...sessionWords]..shuffle(rng);
  final quizWords = pool.take(min(quizSize, pool.length)).toList();

  return quizWords.map((word) {
    // Build distractor pool from other session words first (guaranteed available)
    final sessionDistractors = sessionWords
        .where((w) => w.word != word.word)
        .toList()
      ..shuffle(rng);

    // Supplement with cached words if needed
    final cachedDistractors = StorageService.instance
        .getAllCachedWords()
        .where((w) => w.word != word.word &&
            !sessionDistractors.any((s) => s.word == w.word))
        .toList()
      ..shuffle(rng);

    final allDistractors = [...sessionDistractors, ...cachedDistractors];

    // Pick 3 unique meanings
    final distractorMeanings = <String>[];
    for (final d in allDistractors) {
      if (distractorMeanings.length >= 3) break;
      if (d.meaning != word.meaning &&
          !distractorMeanings.contains(d.meaning)) {
        distractorMeanings.add(d.meaning);
      }
    }

    // Hard fallback if still short (shouldn't happen with 12 session words)
    const fallbacks = [
      'To express strong disapproval or criticism',
      'Showing excessive eagerness to please others',
      'Lasting only for a brief moment in time',
      'Characterized by careful and thorough analysis',
    ];
    int fi = 0;
    while (distractorMeanings.length < 3) {
      final fb = fallbacks[fi++ % fallbacks.length];
      if (!distractorMeanings.contains(fb) && fb != word.meaning) {
        distractorMeanings.add(fb);
      }
    }

    final correctIdx = rng.nextInt(4);
    final options = List<String>.from(distractorMeanings);
    options.insert(correctIdx, word.meaning);

    return QuizQuestion(word: word, options: options, correctIndex: correctIdx);
  }).toList();
}

  String _genericDistractor(int i) {
    const fallbacks = [
      'Showing excessive enthusiasm or energy',
      'Relating to ancient or historical traditions',
      'Characterized by careful deliberation and restraint',
    ];
    return fallbacks[i % fallbacks.length];
  }

  // ── Save session ───────────────────────────────────────────────────────────

  Future<void> saveSessionResult(
      List<WordModel> words, int correct, int total) async {
    final storage = StorageService.instance;
    await storage.addSeenWords(words.map((w) => w.word).toList());
    await storage.updateWordStats(correct: correct, total: total);
    await storage.setLastWordSessionDate(DateTime.now().toIso8601String());
  }
}
