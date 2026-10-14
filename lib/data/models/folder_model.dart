import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    required super.id,
    super.userId,
    super.parentFolderId,
    required super.name,
    super.isGroup = false,
    super.sortOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      parentFolderId: map['parent_folder_id'] as String?,
      name: map['name'] as String,
      isGroup: (map['is_group'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'parent_folder_id': parentFolderId,
      'name': name,
      'is_group': isGroup ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory FolderModel.fromEntity(Folder folder) {
    return FolderModel(
      id: folder.id,
      userId: folder.userId,
      parentFolderId: folder.parentFolderId,
      name: folder.name,
      isGroup: folder.isGroup,
      sortOrder: folder.sortOrder,
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
    );
  }
}
