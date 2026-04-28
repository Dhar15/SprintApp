import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/word_sprint_service.dart';

enum WordSprintState { idle, loading, fetchingApi, words, quiz, summary, error }

class WordSprintProvider extends ChangeNotifier {
  final _service = WordSprintService();

  WordSprintState _state = WordSprintState.idle;
  WordSprintState get state => _state;

  List<WordModel> _sessionWords = [];
  List<WordModel> get sessionWords => _sessionWords;

  List<QuizQuestion> _quizQuestions = [];
  List<QuizQuestion> get quizQuestions => _quizQuestions;

  int _currentWordIndex = 0;
  int get currentWordIndex => _currentWordIndex;

  int _currentQuizIndex = 0;
  int get currentQuizIndex => _currentQuizIndex;

  int _correctAnswers = 0;
  int get correctAnswers => _correctAnswers;

  int? _selectedOption;
  int? get selectedOption => _selectedOption;

  bool _answerRevealed = false;
  bool get answerRevealed => _answerRevealed;

  WordModel get currentWord => _sessionWords[_currentWordIndex];
  QuizQuestion get currentQuestion => _quizQuestions[_currentQuizIndex];

  String? _errorMessage;
  String _loadingMessage = 'Preparing your session...'; 
  String get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  Future<void> startSession() async {
    _loadingMessage = 'Preparing your session...';
    _state = WordSprintState.loading;
    _currentWordIndex = 0;
    _currentQuizIndex = 0;
    _correctAnswers = 0;
    _selectedOption = null;
    _answerRevealed = false;
    notifyListeners();

    try {
      // Brief delay so the UI shows before parallel fetches begin
      await Future.delayed(const Duration(milliseconds: 100));
      _loadingMessage = 'Fetching definitions...';
      _state = WordSprintState.fetchingApi;
      notifyListeners();

      _sessionWords = await _service.getSessionWords();
      if (_sessionWords.isEmpty) {
        _errorMessage = 'Could not load any words. Check your connection.';
        _state = WordSprintState.error;
      } else {
        _state = WordSprintState.words;
      }
    } catch (e) {
      _errorMessage = 'Failed to load words: $e';
      _state = WordSprintState.error;
    }
    notifyListeners();
  }

  void nextWord() {
    if (_currentWordIndex < _sessionWords.length - 1) {
      _currentWordIndex++;
      notifyListeners();
    } else {
      // All words shown — start quiz
      _quizQuestions = _service.generateQuiz(_sessionWords);
      _currentQuizIndex = 0;
      _selectedOption = null;
      _answerRevealed = false;
      _state = WordSprintState.quiz;
      notifyListeners();
    }
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
    await _service.saveSessionResult(
      _sessionWords,
      _correctAnswers,
      _quizQuestions.length,
    );
    await StorageService.instance.recordOpenedToday();
    _state = WordSprintState.summary;
    notifyListeners();
  }

  void reset() {
    _state = WordSprintState.idle;
    _sessionWords = [];
    _quizQuestions = [];
    _currentWordIndex = 0;
    _currentQuizIndex = 0;
    _correctAnswers = 0;
    _selectedOption = null;
    _answerRevealed = false;
    notifyListeners();
  }

  int get totalQuestions => _quizQuestions.length;
  double get accuracy => totalQuestions == 0 ? 0 : _correctAnswers / totalQuestions;
}
