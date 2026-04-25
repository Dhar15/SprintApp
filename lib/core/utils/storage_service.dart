import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/word_sprint/models/word_model.dart';

class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw Exception('StorageService not initialized');
    return _prefs!;
  }

  static const _streakKey = 'streak_count';
  static const _lastOpenedKey = 'last_opened_date';

  int getStreak() {
    final lastOpened = _p.getString(_lastOpenedKey);
    final streak = _p.getInt(_streakKey) ?? 0;
    if (lastOpened == null) return 0;
    
    final last = DateTime.parse(lastOpened);
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(last.year, last.month, last.day))
        .inDays;

    if (diff == 0) return streak;       // same day, streak unchanged
    if (diff == 1) return streak;       // yesterday, still valid
    return 0;                           // missed a day, streak broken
  }

  Future<int> recordOpenedToday() async {
    final lastOpened = _p.getString(_lastOpenedKey);
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);
    int streak = _p.getInt(_streakKey) ?? 0;

    if (lastOpened != null) {
      final last = DateTime.parse(lastOpened);
      final diff = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;

      if (diff == 0) return streak;     // already recorded today
      if (diff == 1) streak += 1;       // consecutive day
      else streak = 1;                  // streak broken, reset to 1
    } else {
      streak = 1;                       // first ever open
    }

    await _p.setInt(_streakKey, streak);
    await _p.setString(_lastOpenedKey, todayStr);
    await _recordPlayedDay(todayStr);  
    return streak;
  }

  // ── Word Sprint — seen list & stats ───────────────────────────────────────
  static const _seenWordsKey       = 'seen_words';
  static const _wordStatsKey       = 'word_stats';
  static const _lastWordSessionKey = 'last_word_session';

  Set<String> getSeenWords() =>
      (_p.getStringList(_seenWordsKey) ?? []).toSet();

  Future<void> addSeenWords(List<String> words) async {
    final existing = getSeenWords()..addAll(words);
    await _p.setStringList(_seenWordsKey, existing.toList());
  }

  Map<String, dynamic> getWordStats() {
    final raw = _p.getString(_wordStatsKey);
    if (raw == null) return {'total_seen': 0, 'total_correct': 0, 'sessions': 0};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> updateWordStats({required int correct, required int total}) async {
    final s = getWordStats();
    s['total_seen']    = (s['total_seen']    as int) + total;
    s['total_correct'] = (s['total_correct'] as int) + correct;
    s['sessions']      = (s['sessions']      as int) + 1;
    await _p.setString(_wordStatsKey, jsonEncode(s));
  }

  String? getLastWordSessionDate() => _p.getString(_lastWordSessionKey);

  Future<void> setLastWordSessionDate(String date) async =>
      _p.setString(_lastWordSessionKey, date);

  // ── Word definition cache (Free Dictionary API results) ───────────────────
  // Key pattern: "wdef:<Word>"  →  JSON of WordModel

  static String _defKey(String word) => 'wdef:${word.toLowerCase()}';

  /// Returns a cached WordModel for [word], or null if not cached.
  WordModel? getCachedWordDefinition(String word) {
    final raw = _p.getString(_defKey(word));
    if (raw == null) return null;
    try {
      return WordModel.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  /// Persist a fetched WordModel so we never re-hit the API for it.
  Future<void> cacheWordDefinition(WordModel model) async {
    await _p.setString(_defKey(model.word), jsonEncode(model.toJson()));
  }

  /// Return every WordModel that has been cached locally — used for
  /// building quiz distractors without needing new network calls.
  List<WordModel> getAllCachedWords() {
    final keys = _p.getKeys().where((k) => k.startsWith('wdef:')).toList();
    final result = <WordModel>[];
    for (final k in keys) {
      try {
        final raw = _p.getString(k);
        if (raw != null) {
          result.add(WordModel.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw))));
        }
      } catch (_) {}
    }
    return result;
  }

  // ── News Sprint ───────────────────────────────────────────────────────────
  static const _newsStatsKey    = 'news_stats';
  static const _cachedNewsKey   = 'cached_news';
  static const _newsCacheTimeKey = 'news_cache_time';

  Map<String, dynamic> getNewsStats() {
    final raw = _p.getString(_newsStatsKey);
    if (raw == null) return {'sessions': 0, 'articles_read': 0, 'total_correct': 0};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> updateNewsStats({
    required int correct,
    required int articlesRead,
  }) async {
    final s = getNewsStats();
    s['sessions']      = (s['sessions']      as int) + 1;
    s['articles_read'] = (s['articles_read'] as int) + articlesRead;
    s['total_correct'] = (s['total_correct'] as int) + correct;
    await _p.setString(_newsStatsKey, jsonEncode(s));
  }

  List<Map<String, dynamic>>? getCachedNews() {
    final raw = _p.getString(_cachedNewsKey);
    final cacheDate = _p.getString('news_cache_date');
    final today = DateTime.now().toIso8601String().substring(0, 10); // "2026-04-12"
    if (raw == null || cacheDate != today) return null;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> cacheNews(List<Map<String, dynamic>> articles) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _p.setString(_cachedNewsKey, jsonEncode(articles));
    await _p.setString('news_cache_date', today);
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  static const _wordCountKey    = 'setting_word_count';
  static const _quizCountKey    = 'setting_quiz_count';
  static const _newsTopicKey    = 'setting_news_topic';

  int getWordCount() => _p.getInt(_wordCountKey) ?? 12;
  int getQuizCount() => _p.getInt(_quizCountKey) ?? 8;
  String getNewsTopic() => _p.getString(_newsTopicKey) ?? 'all';

  Future<void> setWordCount(int v) => _p.setInt(_wordCountKey, v);
  Future<void> setQuizCount(int v) => _p.setInt(_quizCountKey, v);
  Future<void> setNewsTopic(String v) => _p.setString(_newsTopicKey, v);

  // ── Streak calendar ────────────────────────────────────────────────────────
  // Stores a set of date strings "yyyy-MM-dd" for every day the user opened app
  static const _playedDaysKey = 'played_days';

  Set<String> getPlayedDays() {
    return (_p.getStringList(_playedDaysKey) ?? []).toSet();
  }

  Future<void> _recordPlayedDay(String dateStr) async {
    final days = getPlayedDays()..add(dateStr);
    await _p.setStringList(_playedDaysKey, days.toList());
  }

  String? getCachedNewsTopic() => _p.getString('cached_news_topic');
  Future<void> setCachedNewsTopic(String t) => _p.setString('cached_news_topic', t);
}
