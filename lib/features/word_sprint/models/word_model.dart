class WordModel {
  final String word;
  final String meaning;
  final String example;
  final String difficulty;
  final String? partOfSpeech;
  final String? phonetic;

  const WordModel({
    required this.word,
    required this.meaning,
    required this.example,
    required this.difficulty,
    this.partOfSpeech,
    this.phonetic,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      partOfSpeech: json['partOfSpeech'] as String?,
      phonetic: json['phonetic'] as String?,
    );
  }

  /// Build a WordModel from the Free Dictionary API response
  /// https://api.dictionaryapi.dev/api/v2/entries/en/{word}
  factory WordModel.fromDictionaryApi(String word, Map<String, dynamic> entry) {
    final meanings = entry['meanings'] as List? ?? [];
    String meaning = '';
    String example = '';
    String partOfSpeech = '';

    // Prefer first phonetic text found
    final phonetic = entry['phonetic'] as String? ??
        ((entry['phonetics'] as List?)
            ?.firstWhere(
              (p) => (p['text'] as String?)?.isNotEmpty == true,
              orElse: () => <String, dynamic>{},
            )?['text'] as String?) ??
        '';

    for (final m in meanings) {
      final defs = (m['definitions'] as List?) ?? [];
      if (defs.isEmpty) continue;
      final firstDef = defs.first as Map<String, dynamic>;
      final def = firstDef['definition'] as String? ?? '';
      final ex = firstDef['example'] as String? ?? '';
      if (def.isNotEmpty) {
        meaning = def;
        partOfSpeech = m['partOfSpeech'] as String? ?? '';
        if (ex.isNotEmpty) example = ex;
        break;
      }
    }

    // Search all defs for any example if we still don't have one
    if (example.isEmpty) {
      outer:
      for (final m in meanings) {
        for (final d in (m['definitions'] as List?) ?? []) {
          final ex = (d as Map<String, dynamic>)['example'] as String?;
          if (ex != null && ex.isNotEmpty) {
            example = ex;
            break outer;
          }
        }
      }
    }

    if (example.isEmpty) {
      example = 'The word $word was used to great effect in the conversation.';
    }

    return WordModel(
      word: word,
      meaning: meaning.isNotEmpty ? meaning : 'No definition available.',
      example: example,
      difficulty: _inferDifficulty(word),
      partOfSpeech: partOfSpeech.isNotEmpty ? partOfSpeech : null,
      phonetic: phonetic.isNotEmpty ? phonetic : null,
    );
  }

  static String _inferDifficulty(String word) {
    if (word.length <= 6) return 'easy';
    if (word.length <= 9) return 'medium';
    return 'hard';
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'meaning': meaning,
    'example': example,
    'difficulty': difficulty,
    if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
    if (phonetic != null) 'phonetic': phonetic,
  };
}

class QuizQuestion {
  final WordModel word;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}

class WordSessionResult {
  final int wordsLearned;
  final int quizCorrect;
  final int quizTotal;

  const WordSessionResult({
    required this.wordsLearned,
    required this.quizCorrect,
    required this.quizTotal,
  });

  double get accuracy => quizTotal == 0 ? 0 : quizCorrect / quizTotal;
}
