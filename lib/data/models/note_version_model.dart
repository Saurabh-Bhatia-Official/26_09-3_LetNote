import '../../domain/entities/note_version.dart';

class NoteVersionModel extends NoteVersion {
  const NoteVersionModel({
    required super.id,
    required super.noteId,
    required super.titleSnapshot,
    required super.bodyDeltaSnapshot,
    required super.createdAt,
  });

  factory NoteVersionModel.fromMap(Map<String, dynamic> map) {
    return NoteVersionModel(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      titleSnapshot: map['title_snapshot'] as String? ?? '',
      bodyDeltaSnapshot: map['body_delta_snapshot'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'title_snapshot': titleSnapshot,
      'body_delta_snapshot': bodyDeltaSnapshot,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteVersionModel.fromEntity(NoteVersion version) {
    return NoteVersionModel(
      id: version.id,
      noteId: version.noteId,
      titleSnapshot: version.titleSnapshot,
      bodyDeltaSnapshot: version.bodyDeltaSnapshot,
      createdAt: version.createdAt,
    );
  }
}
