import '../../core/constants/app_constants.dart';
import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    super.userId,
    super.folderId,
    required super.title,
    required super.bodyDelta,
    super.noteType,
    super.isPinned,
    super.isFavorite,
    super.isArchived,
    super.isLocked,
    super.isImportant,
    super.isTemplate,
    super.encryptedBody,
    super.wordCount,
    super.charCount,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
    super.syncVersion,
    super.tagIds,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, [List<String> tags = const []]) {
    return NoteModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      folderId: map['folder_id'] as String?,
      title: map['title'] as String? ?? '',
      bodyDelta: map['body_delta'] as String? ?? '',
      noteType: NoteTypeExtension.fromString(map['note_type'] as String?),
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      isImportant: (map['is_important'] as int? ?? 0) == 1,
      isTemplate: (map['is_template'] as int? ?? 0) == 1,
      encryptedBody: map['encrypted_body'] as String?,
      wordCount: map['word_count'] as int? ?? 0,
      charCount: map['char_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
      syncVersion: map['sync_version'] as int? ?? 0,
      tagIds: tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'folder_id': folderId,
      'title': title,
      'body_delta': bodyDelta,
      'note_type': noteType.name.toLowerCase(),
      'is_pinned': isPinned ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
      'is_important': isImportant ? 1 : 0,
      'is_template': isTemplate ? 1 : 0,
      'encrypted_body': encryptedBody,
      'word_count': wordCount,
      'char_count': charCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'sync_version': syncVersion,
    };
  }

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      userId: note.userId,
      folderId: note.folderId,
      title: note.title,
      bodyDelta: note.bodyDelta,
      noteType: note.noteType,
      isPinned: note.isPinned,
      isFavorite: note.isFavorite,
      isArchived: note.isArchived,
      isLocked: note.isLocked,
      isImportant: note.isImportant,
      isTemplate: note.isTemplate,
      encryptedBody: note.encryptedBody,
      wordCount: note.wordCount,
      charCount: note.charCount,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      deletedAt: note.deletedAt,
      syncVersion: note.syncVersion,
      tagIds: note.tagIds,
    );
  }
}
