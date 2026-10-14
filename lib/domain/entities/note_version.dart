class NoteVersion {
  final String id;
  final String noteId;
  final String titleSnapshot;
  final String bodyDeltaSnapshot;
  final DateTime createdAt;

  const NoteVersion({
    required this.id,
    required this.noteId,
    required this.titleSnapshot,
    required this.bodyDeltaSnapshot,
    required this.createdAt,
  });
}
