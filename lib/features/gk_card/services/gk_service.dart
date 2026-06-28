import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gk_fact_model.dart';
import '../../../core/utils/app_config.dart';
import 'package:home_widget/home_widget.dart';

class GkService {
  static const _cacheKey        = 'gk_of_day_index';
  static const _cacheDateKey    = 'gk_of_day_date';
  static const _factsKey        = 'gk_facts_cache';
  static const _factsCacheDateKey = 'gk_facts_cache_date';

  static List<GkFactModel>? _allFacts;

  // ── Load facts — Supabase first, local JSON as fallback ──────────────────
  Future<List<GkFactModel>> _loadFacts() async {
    if (_allFacts != null) return _allFacts!;

    // Try Supabase
    try {
      final remote = await _fetchFromSupabase();
      if (remote.isNotEmpty) {
        _allFacts = remote;
        return _allFacts!;
      }
    } catch (e) {
      print('Supabase fetch error: $e');
    }

    // Fallback to local JSON asset
    try {
      final raw = await rootBundle.loadString('assets/data/gk_facts.json');
      final list = jsonDecode(raw) as List;
      _allFacts = list.map((e) => GkFactModel.fromJson(e)).toList();
      print('GK loaded from local asset: ${_allFacts!.length} facts');
      return _allFacts!;
    } catch (e) {
      print('Local GK load error: $e');
      return [];
    }
  }

  Future<List<GkFactModel>> _fetchFromSupabase() async {
    final uri = Uri.parse(
      '${AppConfig.supabaseUrl}/rest/v1/gk_facts?select=id,category,fact&active=eq.true&order=id.asc',
    );

    final response = await http.get(uri, headers: {
      'apikey': AppConfig.supabaseAnonKey,
      'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Supabase HTTP ${response.statusCode}');
    }

    final list = jsonDecode(response.body) as List;
    final facts = list.map((e) => GkFactModel.fromJson(e)).toList();
    print('GK loaded from Supabase: ${facts.length} facts');
    return facts;
  }

  // ── Fact of the Day ───────────────────────────────────────────────────────
  Future<GkFactModel?> getFactOfDay() async {
    final facts = await _loadFacts();
    if (facts.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cachedDate = prefs.getString(_cacheDateKey);
    final cachedIndex = prefs.getInt(_cacheKey);

    if (cachedDate == today && cachedIndex != null) {
      final fact = facts[cachedIndex % facts.length];
      await _pushToWidget(fact);
      return fact;
    }

    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final index = dayOfYear % facts.length;

    await prefs.setString(_cacheDateKey, today);
    await prefs.setInt(_cacheKey, index);
    await _pushToWidget(facts[index]);
    return facts[index];
  }

  Future<bool> updateFact(int id, String updatedFact, String updatedCategory) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.supabaseUrl}/rest/v1/gk_facts?id=eq.$id',
      );

      final response = await http.patch(
        uri,
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
        'fact': updatedFact,
        'category': updatedCategory,
      }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Invalidate in-memory cache so next load fetches fresh from Supabase
        _allFacts = null;
        print('GK fact updated successfully: id=$id');
        return true;
      } else {
        print('Supabase PATCH error: ${response.statusCode} — ${response.body}');
        return false;
      }
    } catch (e) {
      print('updateFact error: $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<List<GkFactModel>> getFactsForCategory(String category) async {
    final facts = await _loadFacts();
    return facts.where((f) => f.category == category).toList();
  }

  Future<int> getTotalCount() async {
    final facts = await _loadFacts();
    return facts.length;
  }

  // ── Widget push ───────────────────────────────────────────────────────────
  Future<void> _pushToWidget(GkFactModel fact) async {
    try {
      const categoryEmojis = {
        'positions':     '🏛️',
        'history':       '📜',
        'science':       '🔬',
        'sports':        '⚽',
        'organisations': '🌐',
        'schemes':       '📋',
        'dates':         '📅',
        'currency':      '💰',
        'indexes':       '📊',
        'discoverers':   '💡',
        'geography':     '🗺️',
        'politics':      '🗳️',
        'authors':       '✍️',
        'miscellaneous': '🎲',
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