import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/entities/note.dart';
import '../../providers/notes_provider.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes currently in Trash will be permanently deleted. This action is irreversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(notesNotifierProvider.notifier).emptyTrash();
              Navigator.of(ctx).pop();
            },
            child: const Text('Empty Trash Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Note?'),
        content: Text(
          'Are you sure you want to permanently delete "${note.title.isNotEmpty ? note.title : 'Untitled'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(notesNotifierProvider.notifier).permanentlyDelete(note.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(noteRepositoryProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trash & Recovery'),
        actions: [
          TextButton.icon(
            onPressed: () => _confirmEmptyTrash(context, ref),
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            label: const Text('Empty Trash', style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: repo.getNotes(includeTrash: true),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final trashNotes = snapshot.data ?? [];

          if (trashNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 54, color: theme.hintColor),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is Empty',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Deleted notes stay here for recovery before permanent cleanup.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: theme.cardColor,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Colors.amberAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Items in Trash will be kept according to your retention policy (default 30 days) before auto-cleanup.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: trashNotes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final note = trashNotes[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        title: Text(
                          note.title.isNotEmpty ? note.title : 'Untitled Note',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Deleted: ${DateFormatter.formatRelative(note.deletedAt)} • ${TextUtils.stripMarkdown(note.bodyDelta)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await ref.read(notesNotifierProvider.notifier).restore(note.id);
                                (ctx as Element).markNeedsBuild();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Note restored to active notes.')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                              label: const Text('Restore'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                              tooltip: 'Delete Permanently',
                              onPressed: () => _confirmPermanentDelete(context, ref, note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
