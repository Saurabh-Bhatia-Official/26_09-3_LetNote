import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../data/repositories/note_repository_impl.dart';
import 'folders_provider.dart';

enum SmartFilter {
  all,
  pinned,
  favorites,
  archived,
  trash,
}

class NoteFilterState {
  final SmartFilter smartFilter;
  final String? folderId;
  final String? bookGroupId;
  final String? tagId;
  final NoteType? noteType;

  const NoteFilterState({
    this.smartFilter = SmartFilter.all,
    this.folderId,
    this.bookGroupId,
    this.tagId,
    this.noteType,
  });

  NoteFilterState copyWith({
    SmartFilter? smartFilter,
    String? folderId,
    String? bookGroupId,
    String? tagId,
    NoteType? noteType,
    bool clearFolder = false,
    bool clearBookGroup = false,
    bool clearTag = false,
    bool clearNoteType = false,
  }) {
    return NoteFilterState(
      smartFilter: smartFilter ?? this.smartFilter,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      bookGroupId: clearBookGroup ? null : (bookGroupId ?? this.bookGroupId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      noteType: clearNoteType ? null : (noteType ?? this.noteType),
    );
  }
}

class NoteFilterNotifier extends Notifier<NoteFilterState> {
  @override
  NoteFilterState build() => const NoteFilterState();

  void setFilter(NoteFilterState filter) => state = filter;
}

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl();
});

final noteFilterProvider = NotifierProvider<NoteFilterNotifier, NoteFilterState>(NoteFilterNotifier.new);

class ActiveNoteIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final activeNoteIdProvider = NotifierProvider<ActiveNoteIdNotifier, String?>(ActiveNoteIdNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  final _uuid = const Uuid();

  @override
  Future<List<Note>> build() async {
    final filter = ref.watch(noteFilterProvider);
    final repo = ref.read(noteRepositoryProvider);

    if (filter.bookGroupId != null) {
      final foldersRepo = ref.read(folderRepositoryProvider);
      final allFolders = await foldersRepo.getFolders();
      final childFolderIds = allFolders
          .where((f) => f.parentFolderId == filter.bookGroupId || f.id == filter.bookGroupId)
          .map((f) => f.id)
          .toSet();

      final allNotes = await repo.getNotes(
        tagId: filter.tagId,
        includeArchived: filter.smartFilter == SmartFilter.archived,
        includeTrash: filter.smartFilter == SmartFilter.trash,
        pinnedOnly: filter.smartFilter == SmartFilter.pinned,
        favoritesOnly: filter.smartFilter == SmartFilter.favorites,
        noteType: filter.noteType,
      );
      return allNotes.where((n) => n.folderId != null && childFolderIds.contains(n.folderId)).toList();
    }

    return await repo.getNotes(
      folderId: filter.folderId,
      tagId: filter.tagId,
      includeArchived: filter.smartFilter == SmartFilter.archived,
      includeTrash: filter.smartFilter == SmartFilter.trash,
      pinnedOnly: filter.smartFilter == SmartFilter.pinned,
      favoritesOnly: filter.smartFilter == SmartFilter.favorites,
      noteType: filter.noteType,
    );
  }

  Future<Note> createNewNote({
    String? folderId,
    NoteType noteType = NoteType.standard,
    String? initialTitle,
    String? initialBody,
  }) async {
    final repo = ref.read(noteRepositoryProvider);
    final now = DateTime.now();
    final body = initialBody ?? noteType.defaultTemplate;
    final title = initialTitle ?? (noteType == NoteType.standard ? '' : noteType.name);

    final newNote = Note(
      id: _uuid.v4(),
      folderId: folderId,
      title: title,
      bodyDelta: body,
      noteType: noteType,
      wordCount: TextUtils.countWords(body),
      charCount: TextUtils.countCharacters(body),
      createdAt: now,
      updatedAt: now,
    );

    await repo.saveNote(newNote);
    ref.invalidateSelf();
    ref.read(activeNoteIdProvider.notifier).select(newNote.id);
    return newNote;
  }

  Future<void> updateNote(Note note) async {
    final repo = ref.read(noteRepositoryProvider);
    final updated = note.copyWith(
      updatedAt: DateTime.now(),
      wordCount: TextUtils.countWords(note.bodyDelta),
      charCount: TextUtils.countCharacters(note.bodyDelta),
    );
    await repo.updateNote(updated);

    final currentList = state.value;
    if (currentList != null) {
      state = AsyncData(
        currentList.map((n) => n.id == updated.id ? updated : n).toList(),
      );
    }
  }

  Future<void> softDelete(String id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.softDeleteNote(id);

    if (ref.read(activeNoteIdProvider) == id) {
      ref.read(activeNoteIdProvider.notifier).select(null);
    }
    ref.invalidateSelf();
  }

  Future<void> restore(String id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.restoreNote(id);
    ref.invalidateSelf();
  }

  Future<void> permanentlyDelete(String id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.permanentlyDeleteNote(id);
    if (ref.read(activeNoteIdProvider) == id) {
      ref.read(activeNoteIdProvider.notifier).select(null);
    }
    ref.invalidateSelf();
  }

  Future<void> emptyTrash() async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.emptyTrash();
    ref.invalidateSelf();
  }

  Future<void> togglePin(String id, bool isPinned) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.togglePin(id, !isPinned);
    ref.invalidateSelf();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.toggleFavorite(id, !isFavorite);
    ref.invalidateSelf();
  }

  Future<void> toggleArchive(String id, bool isArchived) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.toggleArchive(id, !isArchived);
    if (ref.read(activeNoteIdProvider) == id) {
      ref.read(activeNoteIdProvider.notifier).select(null);
    }
    ref.invalidateSelf();
  }

  Future<void> duplicateNote(Note original) async {
    final repo = ref.read(noteRepositoryProvider);
    final now = DateTime.now();
    final copy = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      setDeletedAtNull: true,
    );
    await repo.saveNote(copy);
    ref.invalidateSelf();
    ref.read(activeNoteIdProvider.notifier).select(copy.id);
  }
}

final notesNotifierProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

final activeNoteProvider = Provider<Note?>((ref) {
  final activeId = ref.watch(activeNoteIdProvider);
  if (activeId == null) return null;

  final notesAsync = ref.watch(notesNotifierProvider);
  return notesAsync.value?.where((n) => n.id == activeId).firstOrNull;
});
