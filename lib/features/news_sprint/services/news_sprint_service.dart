import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/app_config.dart';

class NewsSprintService {
  static const int maxArticles = 8;
  static const String _newsApiBase = 'https://newsapi.org/v2/everything';

  Future<List<NewsArticle>> fetchArticles() async {
    final storage = StorageService.instance;
    final cached = storage.getCachedNews();
    final cachedTopic = storage.getCachedNewsTopic();
    final currentTopic = storage.getNewsTopic();
    if (cached != null && cached.isNotEmpty && cachedTopic == currentTopic) {
      return cached.map((e) => NewsArticle.fromJson(e)).toList();
    }

    try {
      final articles = await _fetchFromNewsApi();
      if (articles.isNotEmpty) {
        await storage.cacheNews(articles.map((a) => a.toJson()).toList());
        await storage.setCachedNewsTopic(currentTopic);
        return articles;
      }
    } catch (e) {
      print('NewsAPI error: $e');
    }
    return _staticFallbackArticles();
  }

  Future<List<NewsArticle>> _fetchFromNewsApi() async {
    final topic = StorageService.instance.getNewsTopic();
    final q = topic == 'all'
        ? 'world OR technology OR business OR science OR health'
        : topic;

    final uri = Uri.parse(
      '$_newsApiBase?language=en&sortBy=publishedAt&pageSize=$maxArticles&q=$q&apiKey=${AppConfig.newsApiKey}',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    print('NewsAPI status: ${response.statusCode}');
    print('NewsAPI body: ${response.body.substring(0, 300)}');

    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}: ${response.body}');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'ok') throw Exception('NewsAPI error: ${data['message']}');

    final articles = data['articles'] as List? ?? [];

    return articles
        .where((a) {
          final title = a['title'] as String? ?? '';
          final desc = a['description'] as String? ?? '';
          // Filter out removed articles, date-only titles, and empty content
          if (title == '[Removed]' || title.isEmpty) return false;
          if (desc.isEmpty) return false;
          // Filter titles that are just dates or very short (likely metadata)
          if (title.length < 15) return false;
          // Filter titles that start with a date pattern like "12/04/2026"
          if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(title)) return false;
          return true;
        })
        .take(maxArticles)
        .map((a) => NewsArticle(
              id: a['url'] ?? a['title'],
              title: a['title'] as String,
              summary: _summarize((a['description'] ?? a['content'] ?? '') as String),
              source: (a['source']?['name'] ?? 'News') as String,
              imageUrl: a['urlToImage'] as String?,
              category: 'world',
              publishedAt: DateTime.tryParse(a['publishedAt'] ?? '') ?? DateTime.now(),
              originalUrl: a['url'] as String?,
            ))
        .toList();
  }

  String _summarize(String text) {
    if (text.isEmpty) return 'Read more for details.';
    if (text.length <= 280) return text;
    final truncated = text.substring(0, 280);
    final lastPeriod = truncated.lastIndexOf('.');
    if (lastPeriod > 100) return truncated.substring(0, lastPeriod + 1);
    return '$truncated...';
  }

  Future<List<NewsQuizQuestion>> generateQuiz(List<NewsArticle> articles) async {
    final futures = articles.map((a) => _generateQuestionForArticle(a)).toList();
    final results = await Future.wait(futures);
    return results.whereType<NewsQuizQuestion>().toList();
  }

  Future<NewsQuizQuestion?> _generateQuestionForArticle(NewsArticle article) async {
    try {
      final prompt = '''
You are a quiz generator. Given this news summary, generate ONE multiple choice question to test comprehension.

Article title: ${article.title}
Summary: ${article.summary}

Respond ONLY with valid JSON in exactly this format, no markdown, no explanation:
{
  "question": "A specific factual question about this news story",
  "options": ["correct answer", "wrong answer 2", "wrong answer 3", "wrong answer 4"],
  "correct_index": 0,
  "explanation": "One sentence explaining why the answer is correct"
}

Rules:
- Question must be answerable from the summary alone
- All 4 options must be plausible (not obviously wrong)
- correct_index is always 0 in your response (we will shuffle)
- Keep options concise (under 12 words each)
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': AppConfig.groqApiKey,
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'max_tokens': 400,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('Groq error: ${response.statusCode} — ${response.body}');
        return _fallbackQuestion(article);
      }

      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'] as String;
      final parsed = jsonDecode(text.trim()) as Map<String, dynamic>;
      final options = List<String>.from(parsed['options']);
      final rng = Random();

      final correctAnswer = options[0];
      options.shuffle(rng);
      final correctIdx = options.indexOf(correctAnswer);

      return NewsQuizQuestion(
        article: article,
        question: parsed['question'] as String,
        options: options,
        correctIndex: correctIdx,
        explanation: parsed['explanation'] as String? ?? '',
      );
    } catch (e) {
      print('Quiz generation failed for "${article.title}": $e');
      return _fallbackQuestion(article);
    }
  }

  NewsQuizQuestion _fallbackQuestion(NewsArticle article) {
    return NewsQuizQuestion(
      article: article,
      question: 'What is the main topic of this news story?',
      options: [
        article.title.length > 60 ? '${article.title.substring(0, 60)}...' : article.title,
        'A story about global financial markets and trade',
        'A report on scientific research and discoveries',
        'An update on sports events and competitions',
      ],
      correctIndex: 0,
      explanation: 'This story is about: ${article.title}',
    );
  }

  List<NewsArticle> _staticFallbackArticles() {
    return [
      NewsArticle(
        id: 'f1',
        title: 'Global Climate Summit Reaches Historic Agreement',
        summary: 'World leaders gathered in Geneva reached a landmark agreement on carbon emissions, pledging to cut greenhouse gases by 45% before 2035. The deal, signed by 192 nations, includes financial commitments to support developing countries in their transition to clean energy.',
        source: 'World News',
        category: 'environment',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsArticle(
        id: 'f2',
        title: 'AI Breakthrough: New Model Solves Complex Protein Structures',
        summary: 'Researchers at a leading tech firm announced a new artificial intelligence system capable of predicting protein structures with 98% accuracy. The breakthrough could accelerate drug discovery and transform the treatment of diseases like Alzheimer\'s and cancer.',
        source: 'Tech Today',
        category: 'technology',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      NewsArticle(
        id: 'f3',
        title: 'Central Banks Signal Coordinated Rate Cuts Ahead',
        summary: 'The Federal Reserve and European Central Bank signaled a coordinated pivot toward interest rate reductions amid cooling inflation. Markets rallied on the news, with the S&P 500 gaining over 2% as investors anticipate cheaper borrowing costs in the second half of the year.',
        source: 'Finance Wire',
        category: 'business',
        publishedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      NewsArticle(
        id: 'f4',
        title: 'Space Agency Confirms Water Ice Discovery on Moon',
        summary: 'A space agency confirmed the presence of substantial water ice deposits in permanently shadowed craters near the lunar south pole. The finding strengthens the case for establishing a permanent lunar base and could provide resources for future deep-space missions to Mars.',
        source: 'Science Daily',
        category: 'science',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      NewsArticle(
        id: 'f5',
        title: 'Major Trade Deal Reshapes Asia-Pacific Commerce',
        summary: 'Fifteen Asia-Pacific nations signed a sweeping trade agreement eliminating tariffs on thousands of goods and establishing common digital commerce standards. Economists project the deal will add \$500 billion to regional GDP over the next decade while creating millions of jobs.',
        source: 'Global Trade',
        category: 'business',
        publishedAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
      NewsArticle(
        id: 'f6',
        title: 'Breakthrough in Quantum Computing Achieved',
        summary: 'Scientists demonstrated a quantum computer solving in four minutes a problem that would take classical supercomputers ten thousand years. The milestone, called quantum supremacy in a real-world application, opens new possibilities for materials science and cryptography.',
        source: 'Tech Wire',
        category: 'technology',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      NewsArticle(
        id: 'f7',
        title: 'Global Health Organization Issues Pandemic Preparedness Update',
        summary: 'The World Health Organization released updated global pandemic preparedness guidelines, calling on member states to invest in early-warning surveillance systems and vaccine manufacturing capacity. The report cited lessons from recent outbreaks and called for greater international cooperation.',
        source: 'Health News',
        category: 'health',
        publishedAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
      NewsArticle(
        id: 'f8',
        title: 'Renewable Energy Surpasses Fossil Fuels in EU Grid',
        summary: 'For the first time, renewable energy sources generated more than half of the European Union\'s electricity over a full calendar year. Solar and wind power led the surge, while coal usage dropped to a historic low, marking a significant step toward the bloc\'s 2050 net-zero goals.',
        source: 'Energy Report',
        category: 'environment',
        publishedAt: DateTime.now().subtract(const Duration(hours: 16)),
      ),
    ];
  }
}