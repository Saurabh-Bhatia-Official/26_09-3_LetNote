import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_version.dart';
import '../providers/notes_provider.dart';

class VersionHistoryDialog extends ConsumerStatefulWidget {
  final Note note;

  const VersionHistoryDialog({super.key, required this.note});

  static Future<void> show(BuildContext context, Note note) {
    return showDialog(
      context: context,
      builder: (ctx) => VersionHistoryDialog(note: note),
    );
  }

  @override
  ConsumerState<VersionHistoryDialog> createState() => _VersionHistoryDialogState();
}

class _VersionHistoryDialogState extends ConsumerState<VersionHistoryDialog> {
  List<NoteVersion> _versions = [];
  NoteVersion? _selectedVersion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final repo = ref.read(noteRepositoryProvider);
    final history = await repo.getVersionHistory(widget.note.id);
    if (mounted) {
      setState(() {
        _versions = history;
        if (history.isNotEmpty) {
          _selectedVersion = history.first;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreSelected() async {
    if (_selectedVersion == null) return;
    final repo = ref.read(noteRepositoryProvider);
    await repo.restoreVersion(widget.note.id, _selectedVersion!);
    ref.invalidate(notesNotifierProvider);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restored previous version successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: theme.primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Version History',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _versions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 48, color: theme.hintColor),
                              const SizedBox(height: 12),
                              Text(
                                'No previous snapshots recorded yet',
                                style: TextStyle(color: theme.hintColor),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Snapshots are automatically created during edit sessions',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            // Left list of version timestamps
                            SizedBox(
                              width: 240,
                              child: ListView.separated(
                                itemCount: _versions.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 4),
                                itemBuilder: (ctx, i) {
                                  final v = _versions[i];
                                  final isSelected = _selectedVersion?.id == v.id;

                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: theme.primaryColor.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    title: Text(
                                      DateFormatter.formatFull(v.createdAt),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      v.titleSnapshot.isNotEmpty ? v.titleSnapshot : 'Untitled',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    onTap: () => setState(() => _selectedVersion = v),
                                  );
                                },
                              ),
                            ),
                            const VerticalDivider(width: 24),
                            // Right snapshot content preview
                            Expanded(
                              child: _selectedVersion == null
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          _selectedVersion!.titleSnapshot.isNotEmpty
                                              ? _selectedVersion!.titleSnapshot
                                              : 'Untitled',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: theme.dividerColor),
                                            ),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                _selectedVersion!.bodyDeltaSnapshot,
                                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _restoreSelected,
                                              icon: const Icon(Icons.restore_rounded, size: 18),
                                              label: const Text('Restore This Version'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: theme.primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
