class Ong {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final bool highlighted;
  final String category;
  final String fotoRelevante1;
  final String fotoRelevante2;
  final String fotoRelevante3;
  final String sobreOng;

  Ong({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    this.highlighted = false,
    this.category = '',
    this.fotoRelevante1 = '',
    this.fotoRelevante2 = '',
    this.fotoRelevante3 = '',
    this.sobreOng = '',
  });

  factory Ong.fromJson(Map<String, dynamic> json) {
    return Ong(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      highlighted: json['highlighted'] ?? false,
      category: json['category'] ?? '',
      fotoRelevante1: json['foto_relevante1'] ?? '',
      fotoRelevante2: json['foto_relevante2'] ?? '',
      fotoRelevante3: json['foto_relevante3'] ?? '',
      sobreOng: json['sobre_ong'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'highlighted': highlighted,
      'category': category,
      'foto_relevante1': fotoRelevante1,
      'foto_relevante2': fotoRelevante2,
      'foto_relevante3': fotoRelevante3,
      'sobre_ong': sobreOng,
    };
  }
}
