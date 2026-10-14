import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/note.dart';
import 'notes_provider.dart';

class DashboardData {
  final int totalNotes;
  final int pinnedCount;
  final int favoritesCount;
  final int trashCount;
  final int archivedCount;
  final List<Note> recentNotes;
  final List<Note> pinnedNotes;
  final List<Note> favoriteNotes;
  final int totalWordCount;
  final int openChecklistsCount;

  const DashboardData({
    this.totalNotes = 0,
    this.pinnedCount = 0,
    this.favoritesCount = 0,
    this.trashCount = 0,
    this.archivedCount = 0,
    this.recentNotes = const [],
    this.pinnedNotes = const [],
    this.favoriteNotes = const [],
    this.totalWordCount = 0,
    this.openChecklistsCount = 0,
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);

  final totalNotes = await repo.getTotalNotesCount();
  final trashCount = await repo.getTrashNotesCount();
  final archivedCount = await repo.getArchivedNotesCount();

  // Fetch recent active notes
  final allActive = await repo.getNotes(includeArchived: false, includeTrash: false);

  final pinned = allActive.where((n) => n.isPinned).toList();
  final favorites = allActive.where((n) => n.isFavorite).toList();
  final recent = allActive.take(10).toList();

  int wordCount = 0;
  int openTasks = 0;

  for (final note in allActive) {
    wordCount += note.wordCount;
    if (note.bodyDelta.contains('[ ]') || note.bodyDelta.contains('- [ ]')) {
      final matches = RegExp(r'\[\s\]').allMatches(note.bodyDelta).length;
      openTasks += matches;
    }
  }

  return DashboardData(
    totalNotes: totalNotes,
    pinnedCount: pinned.length,
    favoritesCount: favorites.length,
    trashCount: trashCount,
    archivedCount: archivedCount,
    recentNotes: recent,
    pinnedNotes: pinned,
    favoriteNotes: favorites,
    totalWordCount: wordCount,
    openChecklistsCount: openTasks,
  );
});
