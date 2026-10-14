import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/entities/note.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/pin_dialog.dart';

class NotesListView extends ConsumerWidget {
  const NotesListView({super.key});

  String _getFilterTitle(WidgetRef ref, NoteFilterState filter) {
    if (filter.smartFilter == SmartFilter.pinned) return 'Pinned Notes';
    if (filter.smartFilter == SmartFilter.favorites) return 'Favorite Notes';
    if (filter.smartFilter == SmartFilter.archived) return 'Archived Notes';
    if (filter.smartFilter == SmartFilter.trash) return 'Trash';
    if (filter.noteType != null) return '${filter.noteType!.name} Notes';
    if (filter.folderId != null) {
      final folders = ref.watch(foldersNotifierProvider).value;
      final book = folders?.where((f) => f.id == filter.folderId).firstOrNull;
      if (book != null) return 'Book: ${book.name}';
    }
    if (filter.bookGroupId != null) {
      final folders = ref.watch(foldersNotifierProvider).value;
      final group = folders?.where((f) => f.id == filter.bookGroupId).firstOrNull;
      if (group != null) return 'Group: ${group.name}';
    }
    return 'All Notes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(noteFilterProvider);
    final notesAsync = ref.watch(notesNotifierProvider);
    final activeId = ref.watch(activeNoteIdProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // List Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFilterTitle(ref, filterState),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      notesAsync.when(
                        data: (notes) => Text(
                          '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                // Note type filter dropdown
                PopupMenuButton<NoteType?>(
                  tooltip: 'Filter by Note Type',
                  icon: const Icon(Icons.filter_list_rounded, size: 20),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: null, child: Text('All Types')),
                    const PopupMenuDivider(),
                    ...NoteType.values.map(
                      (t) => PopupMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(t.name),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onSelected: (type) {
                    ref.read(noteFilterProvider.notifier).setFilter(
                          filterState.copyWith(noteType: type, clearNoteType: type == null),
                        );
                  },
                ),
                const SizedBox(width: 6),
                // New Note button
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(notesNotifierProvider.notifier).createNewNote(
                      folderId: filterState.folderId,
                      noteType: filterState.noteType ?? NoteType.standard,
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return _buildEmptyState(context, ref, theme, filterState);
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: notes.length,
                  itemBuilder: (ctx, i) {
                    final note = notes[i];
                    final isSelected = note.id == activeId;
                    return _buildNoteCard(context, ref, theme, note, isSelected);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading notes: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Note note,
    bool isSelected,
  ) {
    final security = ref.watch(securityProvider);
    final isUnlocked = !note.isLocked || security.isNoteUnlocked(note.id);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.primaryColor : theme.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Material(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.12) : theme.cardColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onTap: () async {
              if (note.isLocked && !isUnlocked) {
                // Prompt for PIN
                final pin = await PinDialog.show(
                  context,
                  mode: PinDialogMode.verify,
                  title: 'Unlock Note',
                  subtitle: 'Enter your PIN to decrypt this note',
                );
                if (pin != null) {
                  final ok = await ref.read(securityProvider.notifier).unlockNote(note.id, pin);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect PIN.')),
                    );
                    return;
                  }
                } else {
                  return;
                }
              }
              ref.read(activeNoteIdProvider.notifier).select(note.id);
            },
            title: Row(
              children: [
                if (note.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin_rounded, size: 14, color: theme.primaryColor),
                  ),
                if (note.isLocked)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.lock_rounded, size: 14, color: Colors.amberAccent),
                  ),
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Untitled Note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : null,
                    ),
                  ),
                ),
                Text(
                  DateFormatter.formatRelative(note.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  note.isLocked && !isUnlocked
                      ? '🔒 Encrypted content (PIN protected)'
                      : (note.bodyDelta.isNotEmpty
                          ? TextUtils.stripMarkdown(note.bodyDelta)
                          : 'Empty note'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontStyle: note.isLocked && !isUnlocked ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Note type pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(note.noteType.icon, size: 11, color: theme.hintColor),
                          const SizedBox(width: 4),
                          Text(
                            note.noteType.name,
                            style: TextStyle(fontSize: 10, color: theme.hintColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Context menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(note.isPinned ? 'Unpin' : 'Pin to Top'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(note.isFavorite ? Icons.star_border_rounded : Icons.star_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(note.isFavorite ? 'Remove Favorite' : 'Mark Favorite'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(note.isArchived ? Icons.unarchive_rounded : Icons.archive_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(note.isArchived ? 'Unarchive' : 'Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Move to Trash', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (val) async {
                        final notifier = ref.read(notesNotifierProvider.notifier);
                        if (val == 'pin') {
                          await notifier.togglePin(note.id, note.isPinned);
                        } else if (val == 'favorite') {
                          await notifier.toggleFavorite(note.id, note.isFavorite);
                        } else if (val == 'duplicate') {
                          await notifier.duplicateNote(note);
                        } else if (val == 'archive') {
                          await notifier.toggleArchive(note.id, note.isArchived);
                        } else if (val == 'delete') {
                          await notifier.softDelete(note.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    NoteFilterState filter,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 54, color: theme.hintColor),
          const SizedBox(height: 14),
          Text(
            'No notes found',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Capture your first thought, meeting notes, or checklist.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(notesNotifierProvider.notifier).createNewNote(
                folderId: filter.folderId,
                noteType: filter.noteType ?? NoteType.standard,
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Note'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
