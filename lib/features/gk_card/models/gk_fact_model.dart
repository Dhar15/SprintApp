class GkFactModel {
  final String category;
  final String fact;

  const GkFactModel({required this.category, required this.fact});

  factory GkFactModel.fromJson(Map<String, dynamic> json) {
    return GkFactModel(
      category: json['category'] as String,
      fact: json['fact'] as String,
    );
  }
}