import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/text_utils.dart';
import '../../providers/search_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/tags_provider.dart';
import '../../widgets/sidebar_navigation.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(searchStateProvider).query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.read(searchStateProvider.notifier);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final foldersAsync = ref.watch(foldersNotifierProvider);
    final tagsAsync = ref.watch(tagsNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Full-Text Search (FTS5)'),
      ),
      body: Column(
        children: [
          // Search Box & Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search notes by keyword, prefix, or phrase...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              searchNotifier.setQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => searchNotifier.setQuery(val),
                  onSubmitted: (val) => searchNotifier.commitRecentSearch(val),
                ),
                const SizedBox(height: 12),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Book filter chip
                      foldersAsync.when(
                        data: (folders) {
                          final currentBook = searchState.folderId == null
                              ? null
                              : folders.where((f) => f.id == searchState.folderId).firstOrNull;
                          return PopupMenuButton<String?>(
                            child: Chip(
                              avatar: Icon(Icons.menu_book_rounded, size: 16, color: theme.primaryColor),
                              label: Text(
                                currentBook == null ? 'All Books' : currentBook.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            itemBuilder: (ctx) {
                              final groups = folders.where((f) => f.isGroup || (f.parentFolderId == null && folders.any((c) => c.parentFolderId == f.id))).toList();
                              final groupIds = groups.map((g) => g.id).toSet();
                              final standaloneBooks = folders.where((f) => !groupIds.contains(f.id) && f.parentFolderId == null).toList();

                              return [
                                const PopupMenuItem(value: null, child: Text('All Books')),
                                if (groups.isNotEmpty) ...[
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    enabled: false,
                                    child: Text('— GROUP OF BOOKS —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ),
                                  for (final group in groups) ...[
                                    ...folders.where((f) => f.parentFolderId == group.id).map((b) => PopupMenuItem(
                                      value: b.id,
                                      child: Text('${group.name} > ${b.name}'),
                                    )),
                                  ],
                                ],
                                if (standaloneBooks.isNotEmpty) ...[
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    enabled: false,
                                    child: Text('— ONLY BOOKS —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ),
                                  ...standaloneBooks.map((b) => PopupMenuItem(value: b.id, child: Text(b.name))),
                                ],
                              ];
                            },
                            onSelected: (fid) => searchNotifier.setFolderFilter(fid),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),

                      // Tag filter chip
                      tagsAsync.when(
                        data: (tags) => PopupMenuButton<String?>(
                          child: Chip(
                            avatar: Icon(Icons.tag_rounded, size: 16, color: theme.primaryColor),
                            label: Text(
                              searchState.tagId == null
                                  ? 'All Tags'
                                  : tags.where((t) => t.id == searchState.tagId).firstOrNull?.name ?? 'Unknown Tag',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: null, child: Text('All Tags')),
                            const PopupMenuDivider(),
                            ...tags.map((t) => PopupMenuItem(value: t.id, child: Text('#${t.name}'))),
                          ],
                          onSelected: (tid) => searchNotifier.setTagFilter(tid),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (e, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 8),

                      // Note Type filter chip
                      PopupMenuButton<NoteType?>(
                        child: Chip(
                          avatar: Icon(Icons.category_outlined, size: 16, color: theme.primaryColor),
                          label: Text(
                            searchState.noteType == null ? 'All Types' : searchState.noteType!.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: null, child: Text('All Types')),
                          const PopupMenuDivider(),
                          ...NoteType.values.map(
                            (t) => PopupMenuItem(value: t, child: Text(t.name)),
                          ),
                        ],
                        onSelected: (type) => searchNotifier.setNoteTypeFilter(type),
                      ),
                      const SizedBox(width: 8),

                      // Include Archived toggle
                      FilterChip(
                        selected: searchState.includeArchived,
                        label: const Text('Include Archived', style: TextStyle(fontSize: 12)),
                        onSelected: (val) => searchNotifier.toggleIncludeArchived(val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results area or Recent Searches
          Expanded(
            child: searchState.query.trim().isEmpty
                ? _buildRecentSearches(theme, searchState, searchNotifier)
                : searchResultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: theme.hintColor),
                              const SizedBox(height: 12),
                              Text(
                                'No matching notes found for "${searchState.query}"',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Check your search query or clear filters.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final note = results[i];
                          final snippet = TextUtils.createSnippet(note.bodyDelta, searchState.query);

                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(note.noteType.icon, color: theme.primaryColor, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title.isNotEmpty ? note.title : 'Untitled Note',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatRelative(note.updatedAt),
                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  snippet,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                                ),
                              ),
                              onTap: () {
                                searchNotifier.commitRecentSearch(searchState.query);
                                ref.read(activeNoteIdProvider.notifier).select(note.id);
                                ref.read(activeTabProvider.notifier).setTab(MainViewTab.notes);
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Search error: $err')),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme, SearchState state, SearchNotifier notifier) {
    if (state.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 54, color: theme.hintColor),
            const SizedBox(height: 12),
            Text(
              'Search your entire knowledge base',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Lightning-fast SQLite FTS5 indexes titles, content, and tags.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT SEARCHES',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.hintColor,
              ),
            ),
            TextButton(
              onPressed: () => notifier.clearRecentSearches(),
              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...state.recentSearches.map(
          (s) => ListTile(
            leading: const Icon(Icons.history_rounded, size: 18),
            title: Text(s),
            trailing: const Icon(Icons.north_west_rounded, size: 16),
            onTap: () {
              _searchController.text = s;
              notifier.setQuery(s);
            },
          ),
        ),
      ],
    );
  }
}
