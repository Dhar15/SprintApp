import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gk_fact_model.dart';
import 'package:home_widget/home_widget.dart';

class GkService {
  static const _cacheKey = 'gk_of_day_index';
  static const _cacheDateKey = 'gk_of_day_date';
  static List<GkFactModel>? _allFacts;

  Future<List<GkFactModel>> _loadFacts() async {
    if (_allFacts != null) return _allFacts!;
    final raw = await rootBundle.loadString('assets/data/gk_facts.json');
    final list = jsonDecode(raw) as List;
    _allFacts = list.map((e) => GkFactModel.fromJson(e)).toList();
    return _allFacts!;
  }

  Future<GkFactModel?> getFactOfDay() async {
    final facts = await _loadFacts();
    if (facts.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_cacheDateKey);
    final cachedIndex = prefs.getInt(_cacheKey);

    // Return cached fact if already picked today
    if (cachedDate == today && cachedIndex != null) {
        final fact = facts[cachedIndex % facts.length];
        await _pushToWidget(fact);
        return fact;
    }

    // Pick a new fact — use day-of-year for consistency
    final dayOfYear = int.parse(
      DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays.toString(),
    );
    final index = dayOfYear % facts.length;
    await prefs.setString(_cacheDateKey, today);
    await prefs.setInt(_cacheKey, index);
    await _pushToWidget(facts[index]);
    return facts[index];
  }

  Future<List<GkFactModel>> getFactsForCategory(String category) async {
    final facts = await _loadFacts();
    return facts.where((f) => f.category == category).toList();
  }

  Future<int> getTotalCount() async {
    final facts = await _loadFacts();
    return facts.length;
  }

  Future<void> _pushToWidget(GkFactModel fact) async {
    try {
      const categoryEmojis = {
      'positions': '🏛️', 'history': '📜', 'science': '🔬',
      'sports': '⚽', 'organisations': '🌐', 'schemes': '📋',
      'dates': '📅', 'currency': '💰', 'indexes': '📊',
      'discoverers': '💡', 'geography': '🗺️', 'politics': '🗳️',
      'authors': '✍️', 'miscellaneous': '🎲',
      };
      final emoji = categoryEmojis[fact.category] ?? '🎲';
      await HomeWidget.saveWidgetData('gk_of_day_fact', fact.fact);
      await HomeWidget.saveWidgetData(
          'gk_of_day_category', '$emoji ${fact.category.toUpperCase()}');
      await HomeWidget.updateWidget(androidName: 'GkOfDayWidget');
    } catch (e) {
      print('GK widget push error: $e'); 
    }
  }
}