import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/note.dart';
import 'notes_provider.dart';

class SearchState {
  final String query;
  final String? folderId;
  final String? tagId;
  final NoteType? noteType;
  final bool includeArchived;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.folderId,
    this.tagId,
    this.noteType,
    this.includeArchived = false,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    String? query,
    String? folderId,
    String? tagId,
    NoteType? noteType,
    bool? includeArchived,
    List<String>? recentSearches,
    bool clearFolder = false,
    bool clearTag = false,
    bool clearNoteType = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      noteType: clearNoteType ? null : (noteType ?? this.noteType),
      includeArchived: includeArchived ?? this.includeArchived,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void commitRecentSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = [
      clean,
      ...state.recentSearches.where((s) => s.toLowerCase() != clean.toLowerCase()),
    ].take(10).toList();

    state = state.copyWith(recentSearches: updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  void setFolderFilter(String? folderId) {
    if (folderId == null) {
      state = state.copyWith(clearFolder: true);
    } else {
      state = state.copyWith(folderId: folderId);
    }
  }

  void setTagFilter(String? tagId) {
    if (tagId == null) {
      state = state.copyWith(clearTag: true);
    } else {
      state = state.copyWith(tagId: tagId);
    }
  }

  void setNoteTypeFilter(NoteType? type) {
    if (type == null) {
      state = state.copyWith(clearNoteType: true);
    } else {
      state = state.copyWith(noteType: type);
    }
  }

  void toggleIncludeArchived(bool val) {
    state = state.copyWith(includeArchived: val);
  }
}

final searchStateProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

final searchResultsProvider = FutureProvider<List<Note>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  final repo = ref.read(noteRepositoryProvider);

  if (searchState.query.trim().isEmpty) {
    return [];
  }

  return await repo.searchNotesFTS(
    searchState.query,
    folderId: searchState.folderId,
    tagId: searchState.tagId,
    noteType: searchState.noteType,
    includeArchived: searchState.includeArchived,
  );
});
