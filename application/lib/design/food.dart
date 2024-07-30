class Food {
  final int id;
  final String name;
  final String type;

  Food({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}
