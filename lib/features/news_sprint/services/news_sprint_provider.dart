import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_sprint_service.dart';
import '../../../core/utils/storage_service.dart';

enum NewsSprintState { idle, loading, articles, quiz, summary, error }

class NewsSprintProvider extends ChangeNotifier {
  final _service = NewsSprintService();

  NewsSprintState _state = NewsSprintState.idle;
  NewsSprintState get state => _state;

  List<NewsArticle> _articles = [];
  List<NewsArticle> get articles => _articles;

  List<NewsQuizQuestion> _quizQuestions = [];
  List<NewsQuizQuestion> get quizQuestions => _quizQuestions;

  int _currentArticleIndex = 0;
  int get currentArticleIndex => _currentArticleIndex;

  int _currentQuizIndex = 0;
  int get currentQuizIndex => _currentQuizIndex;

  int _correctAnswers = 0;
  int get correctAnswers => _correctAnswers;

  int? _selectedOption;
  int? get selectedOption => _selectedOption;

  bool _answerRevealed = false;
  bool get answerRevealed => _answerRevealed;

  bool _usingFallback = false;
  bool get usingFallback => _usingFallback;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  NewsArticle get currentArticle => _articles[_currentArticleIndex];
  NewsQuizQuestion get currentQuestion => _quizQuestions[_currentQuizIndex];

  Future<void> startSession() async {
    _state = NewsSprintState.loading;
    _currentArticleIndex = 0;
    _currentQuizIndex = 0;
    _correctAnswers = 0;
    _selectedOption = null;
    _answerRevealed = false;
    _usingFallback = false;
    notifyListeners();

    try {
      _articles = await _service.fetchArticles();
      if (_articles.isEmpty) {
        _errorMessage = 'Could not load news articles.';
        _state = NewsSprintState.error;
      } else {
        // Check if we're on fallback (no network)
        _usingFallback = StorageService.instance.getCachedNews() == null &&
            _articles.first.id.startsWith('f');
        _state = NewsSprintState.articles;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch news: $e';
      _state = NewsSprintState.error;
    }
    notifyListeners();
  }

  void nextArticle() {
    if (_currentArticleIndex < _articles.length - 1) {
      _currentArticleIndex++;
      notifyListeners();
    } else {
      _startQuiz(); // now async, fire and forget is fine — state updates via notifyListeners
    }
  }

  Future<void> _startQuiz() async {
    _state = NewsSprintState.quiz;
    _quizQuestions = [];
    _currentQuizIndex = 0;
    _selectedOption = null;
    _answerRevealed = false;
    notifyListeners();

    _quizQuestions = await _service.generateQuiz(_articles);
    notifyListeners();  
  }

  void selectAnswer(int index) {
    if (_answerRevealed) return;
    _selectedOption = index;
    _answerRevealed = true;
    if (index == currentQuestion.correctIndex) {
      _correctAnswers++;
    }
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuizIndex < _quizQuestions.length - 1) {
      _currentQuizIndex++;
      _selectedOption = null;
      _answerRevealed = false;
      notifyListeners();
    } else {
      _finishSession();
    }
  }

  Future<void> _finishSession() async {
    await StorageService.instance.updateNewsStats(
      correct: _correctAnswers,
      articlesRead: _articles.length,
    );
    await StorageService.instance.recordOpenedToday();
    _state = NewsSprintState.summary;
    notifyListeners();
  }

  void reset() {
    _state = NewsSprintState.idle;
    _articles = [];
    _quizQuestions = [];
    _currentArticleIndex = 0;
    _currentQuizIndex = 0;
    _correctAnswers = 0;
    _selectedOption = null;
    _answerRevealed = false;
    notifyListeners();
  }

  int get totalQuestions => _quizQuestions.length;
  double get accuracy => totalQuestions == 0 ? 0 : _correctAnswers / totalQuestions;
}
