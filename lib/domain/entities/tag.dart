class Tag {
  final String id;
  final String? userId;
  final String name;
  final String? colorHex;

  const Tag({
    required this.id,
    this.userId,
    required this.name,
    this.colorHex,
  });

  Tag copyWith({
    String? id,
    String? userId,
    String? name,
    String? colorHex,
  }) {
    return Tag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
