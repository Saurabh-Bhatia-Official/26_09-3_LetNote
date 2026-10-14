import '../../domain/entities/tag.dart';

class TagModel extends Tag {
  const TagModel({
    required super.id,
    super.userId,
    required super.name,
    super.colorHex,
  });

  factory TagModel.fromMap(Map<String, dynamic> map) {
    return TagModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color_hex': colorHex,
    };
  }

  factory TagModel.fromEntity(Tag tag) {
    return TagModel(
      id: tag.id,
      userId: tag.userId,
      name: tag.name,
      colorHex: tag.colorHex,
    );
  }
}
