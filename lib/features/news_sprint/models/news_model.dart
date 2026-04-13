class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String? imageUrl;
  final String category;
  final DateTime publishedAt;
  final String? originalUrl;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.source,
    this.imageUrl,
    required this.category,
    required this.publishedAt,
    this.originalUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] ?? json['url'] ?? DateTime.now().toString(),
      title: json['title'] ?? '',
      summary: json['summary'] ?? json['description'] ?? '',
      source: json['source'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? json['urlToImage'],
      category: json['category'] ?? 'general',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
      originalUrl: json['url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'source': source,
    'imageUrl': imageUrl,
    'category': category,
    'publishedAt': publishedAt.toIso8601String(),
    'url': originalUrl,
  };
}

class NewsQuizQuestion {
  final NewsArticle article;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const NewsQuizQuestion({
    required this.article,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });
}
