class GkFactModel {
  final int? id;
  final String category;
  final String fact;

  const GkFactModel({
    this.id,
    required this.category,
    required this.fact,
  });

  factory GkFactModel.fromJson(Map<String, dynamic> json) {
    return GkFactModel(
      id: json['id'] as int?,
      category: json['category'] as String,
      fact: json['fact'] as String,
    );
  }
}