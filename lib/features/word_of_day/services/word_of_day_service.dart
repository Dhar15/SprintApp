import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_of_day_model.dart';
import '../../../core/utils/app_config.dart';

class WordOfDayService {
  static const _cacheKey = 'word_of_day_cache';
  static const _cacheDateKey = 'word_of_day_date';

  Future<WordOfDayModel?> getWordOfDay() async {
    // Check cache first — same word all day
    final cached = await _getCached();
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(
        '${AppConfig.wordOfDayApiUrl}?action=word_of_day',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return null;

      final word = WordOfDayModel.fromJson(
        data['word'] as Map<String, dynamic>,
      );

      await _cache(word);
      return word;
    } catch (e) {
      print('Word of Day API error: $e');
      return null;
    }
  }

  Future<WordOfDayModel?> _getCached() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(_cacheDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (cachedDate != today) return null;

    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      return WordOfDayModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cache(WordOfDayModel word) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_cacheKey, jsonEncode(word.toJson()));
    await prefs.setString(_cacheDateKey, today);
  }
}