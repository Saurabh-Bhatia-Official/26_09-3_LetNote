import '../entities/note.dart';
import '../entities/note_version.dart';
import '../../core/constants/app_constants.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes({
    String? folderId,
    String? tagId,
    bool includeArchived = false,
    bool includeTrash = false,
    bool pinnedOnly = false,
    bool favoritesOnly = false,
    NoteType? noteType,
  });

  Future<Note?> getNoteById(String id);

  Future<void> saveNote(Note note);

  Future<void> updateNote(Note note);

  Future<void> softDeleteNote(String id);

  Future<void> restoreNote(String id);

  Future<void> permanentlyDeleteNote(String id);

  Future<void> emptyTrash();

  Future<List<Note>> searchNotesFTS(
    String query, {
    String? folderId,
    String? tagId,
    NoteType? noteType,
    bool includeArchived = false,
  });

  Future<void> togglePin(String id, bool isPinned);

  Future<void> toggleFavorite(String id, bool isFavorite);

  Future<void> toggleArchive(String id, bool isArchived);

  // Version History
  Future<void> createVersionSnapshot(String noteId, String title, String bodyDelta);

  Future<List<NoteVersion>> getVersionHistory(String noteId);

  Future<void> restoreVersion(String noteId, NoteVersion version);

  // Statistics
  Future<int> getTotalNotesCount();
  Future<int> getTrashNotesCount();
  Future<int> getArchivedNotesCount();
}
