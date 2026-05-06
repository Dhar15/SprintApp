class WordOfDayModel {
  final String word;
  final String meaning;
  final String example;

  const WordOfDayModel({
    required this.word,
    required this.meaning,
    required this.example,
  });

  factory WordOfDayModel.fromJson(Map<String, dynamic> json) {
    return WordOfDayModel(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'meaning': meaning,
    'example': example,
  };
}