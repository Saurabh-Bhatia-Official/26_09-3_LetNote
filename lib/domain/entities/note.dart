import '../../core/constants/app_constants.dart';

class Note {
  final String id;
  final String? userId;
  final String? folderId;
  final String title;
  final String bodyDelta; // Rich text markdown or JSON delta
  final NoteType noteType;
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final bool isLocked;
  final bool isImportant;
  final bool isTemplate;
  final String? encryptedBody; // Populated when isLocked = true
  final int wordCount;
  final int charCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt; // Nullable; if set, note is in Trash
  final int syncVersion;
  final List<String> tagIds;

  const Note({
    required this.id,
    this.userId,
    this.folderId,
    required this.title,
    required this.bodyDelta,
    this.noteType = NoteType.standard,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isLocked = false,
    this.isImportant = false,
    this.isTemplate = false,
    this.encryptedBody,
    this.wordCount = 0,
    this.charCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncVersion = 0,
    this.tagIds = const [],
  });

  bool get isDeleted => deletedAt != null;

  Note copyWith({
    String? id,
    String? userId,
    String? folderId,
    String? title,
    String? bodyDelta,
    NoteType? noteType,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    bool? isLocked,
    bool? isImportant,
    bool? isTemplate,
    String? encryptedBody,
    int? wordCount,
    int? charCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? syncVersion,
    List<String>? tagIds,
    bool setDeletedAtNull = false,
    bool setFolderIdNull = false,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      folderId: setFolderIdNull ? null : (folderId ?? this.folderId),
      title: title ?? this.title,
      bodyDelta: bodyDelta ?? this.bodyDelta,
      noteType: noteType ?? this.noteType,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isLocked: isLocked ?? this.isLocked,
      isImportant: isImportant ?? this.isImportant,
      isTemplate: isTemplate ?? this.isTemplate,
      encryptedBody: encryptedBody ?? this.encryptedBody,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: setDeletedAtNull ? null : (deletedAt ?? this.deletedAt),
      syncVersion: syncVersion ?? this.syncVersion,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}
