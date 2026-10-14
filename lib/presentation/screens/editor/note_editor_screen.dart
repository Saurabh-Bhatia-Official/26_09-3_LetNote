import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/entities/note.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/ai_assistant_provider.dart';
import '../../widgets/editor_toolbar.dart';
import '../../widgets/interactive_block_editor.dart';
import '../../widgets/pin_dialog.dart';
import '../../widgets/version_history_dialog.dart';
import '../../widgets/backup_dialogs.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final GlobalKey<InteractiveBlockEditorState> _blockEditorKey = GlobalKey<InteractiveBlockEditorState>();
  Timer? _autoSaveDebounceTimer;
  Timer? _snapshotTimer;
  bool _isSaving = false;
  bool _isPreviewMode = false;
  bool _isBlockMode = true;
  String _lastSavedBody = '';
  String _lastSavedTitle = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.bodyDelta);
    _lastSavedTitle = widget.note.title;
    _lastSavedBody = widget.note.bodyDelta;

    _titleController.addListener(_onContentChanged);
    _bodyController.addListener(_onContentChanged);

    _snapshotTimer = Timer.periodic(
      const Duration(minutes: AppConstants.versionHistoryAutoSnapshotMinutes),
      (_) => _takeVersionSnapshot(),
    );
  }

  @override
  void didUpdateWidget(covariant NoteEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _saveCurrentNoteSync();
      _titleController.text = widget.note.title;
      _bodyController.text = widget.note.bodyDelta;
      _lastSavedTitle = widget.note.title;
      _lastSavedBody = widget.note.bodyDelta;
    }
  }

  @override
  void dispose() {
    _autoSaveDebounceTimer?.cancel();
    _snapshotTimer?.cancel();
    _saveCurrentNoteSync();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    if (_titleController.text != _lastSavedTitle || _bodyController.text != _lastSavedBody) {
      _autoSaveDebounceTimer?.cancel();
      setState(() => _isSaving = true);
      _autoSaveDebounceTimer = Timer(
        const Duration(milliseconds: AppConstants.autoSaveDebounceMs),
        _saveCurrentNote,
      );
    }
  }

  Future<void> _saveCurrentNote() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text;

    final effectiveTitle = title.isEmpty ? TextUtils.extractTitleFromContent(body) : title;

    final updated = widget.note.copyWith(
      title: effectiveTitle,
      bodyDelta: body,
      wordCount: TextUtils.countWords(body),
      charCount: TextUtils.countCharacters(body),
      updatedAt: DateTime.now(),
    );

    await ref.read(notesNotifierProvider.notifier).updateNote(updated);

    if (mounted) {
      setState(() {
        _lastSavedTitle = _titleController.text;
        _lastSavedBody = body;
        _isSaving = false;
      });
    }
  }

  void _saveCurrentNoteSync() {
    if (_titleController.text != _lastSavedTitle || _bodyController.text != _lastSavedBody) {
      final title = _titleController.text.trim();
      final body = _bodyController.text;
      final effectiveTitle = title.isEmpty ? TextUtils.extractTitleFromContent(body) : title;

      final updated = widget.note.copyWith(
        title: effectiveTitle,
        bodyDelta: body,
        wordCount: TextUtils.countWords(body),
        charCount: TextUtils.countCharacters(body),
        updatedAt: DateTime.now(),
      );
      ref.read(notesNotifierProvider.notifier).updateNote(updated);
    }
  }

  Future<void> _takeVersionSnapshot() async {
    final title = _titleController.text;
    final body = _bodyController.text;
    if (body.trim().isNotEmpty) {
      final repo = ref.read(noteRepositoryProvider);
      await repo.createVersionSnapshot(widget.note.id, title, body);
    }
  }

  Future<void> _handleLockToggle() async {
    final securityNotifier = ref.read(securityProvider.notifier);
    final securityState = ref.read(securityProvider);

    if (widget.note.isLocked) {
      final pin = await PinDialog.show(
        context,
        mode: PinDialogMode.verify,
        title: 'Unlock & Remove Encryption',
        subtitle: 'Enter your PIN to make this note standard',
      );
      if (pin != null) {
        final verified = await securityNotifier.verifyPin(pin);
        if (!mounted) return;
        if (verified) {
          final updated = widget.note.copyWith(
            isLocked: false,
            encryptedBody: null,
            bodyDelta: _bodyController.text,
          );
          await ref.read(notesNotifierProvider.notifier).updateNote(updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note unlocked and decrypted.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN.')),
          );
        }
      }
    } else {
      String? pin;
      if (!securityState.hasPin) {
        pin = await PinDialog.show(
          context,
          mode: PinDialogMode.create,
          title: 'Create Security PIN',
          subtitle: 'Create a 4-6 digit PIN to encrypt this note with AES-256',
        );
        if (pin != null) {
          await securityNotifier.setPin(pin);
        }
      } else {
        pin = await PinDialog.show(
          context,
          mode: PinDialogMode.verify,
          title: 'Lock Note',
          subtitle: 'Enter your PIN to encrypt this note with AES-256',
        );
      }

      if (pin != null) {
        await _saveCurrentNote();
        await securityNotifier.lockNoteWithPin(widget.note.id, pin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note encrypted and locked with AES-256.')),
          );
        }
      }
    }
  }

  void _showAiAssistantMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, innerRef, _) {
          final aiState = innerRef.watch(aiAssistantProvider);
          final aiNotifier = innerRef.read(aiAssistantProvider.notifier);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Note Assistant',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('On-Device', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (aiState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (aiState.lastResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: SingleChildScrollView(
                      child: Text(aiState.lastResult!, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => aiNotifier.clearResult(),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _bodyController.text += '\n\n${aiState.lastResult!}';
                            aiNotifier.clearResult();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Append to Note'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.summarize_outlined, color: Colors.blueAccent),
                    title: const Text('Summarize Note'),
                    subtitle: const Text('Generate bulleted summary of key points'),
                    onTap: () => aiNotifier.summarize(_bodyController.text),
                  ),
                  ListTile(
                    leading: const Icon(Icons.task_alt_rounded, color: Colors.greenAccent),
                    title: const Text('Extract Action Items'),
                    subtitle: const Text('Convert discussions and tasks into checklist'),
                    onTap: () async {
                      final tasks = await aiNotifier.extractTasks(_bodyController.text);
                      if (tasks.isNotEmpty) {
                        final checklistStr = tasks.map((t) => '- [ ] $t').join('\n');
                        _bodyController.text += '\n\n### Action Items\n$checklistStr';
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.title_rounded, color: Colors.amberAccent),
                    title: const Text('Suggest Titles'),
                    subtitle: const Text('Generate catchy titles from note content'),
                    onTap: () async {
                      final titles = await aiNotifier.suggestTitles(_bodyController.text);
                      if (titles.isNotEmpty) {
                        _titleController.text = titles.first;
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      }
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Export as Markdown (.md)'),
              onTap: () async {
                final repo = ref.read(backupRepositoryProvider);
                final md = await repo.exportNoteAsMarkdown(widget.note);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _showExportResultDialog('Markdown Export', md);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Export as Plain Text (.txt)'),
              onTap: () async {
                final repo = ref.read(backupRepositoryProvider);
                final txt = await repo.exportNoteAsPlainText(widget.note);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _showExportResultDialog('Plain Text Export', txt);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object_rounded),
              title: const Text('Export as JSON (.json)'),
              onTap: () async {
                final repo = ref.read(backupRepositoryProvider);
                final json = await repo.exportNoteAsJson(widget.note);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  _showExportResultDialog('JSON Export', json);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          height: 350,
          child: SingleChildScrollView(
            child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foldersAsync = ref.watch(foldersNotifierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top Action Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                // Note type badge selector
                PopupMenuButton<NoteType>(
                  tooltip: 'Change Note Type',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.note.noteType.icon, color: theme.primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.note.noteType.name,
                          style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => NoteType.values.map((t) {
                    return PopupMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(t.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(t.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onSelected: (type) async {
                    final updated = widget.note.copyWith(noteType: type);
                    await ref.read(notesNotifierProvider.notifier).updateNote(updated);
                  },
                ),

                const SizedBox(width: 12),

                // Book selector dropdown with hierarchy (Group of Books & Only Books)
                foldersAsync.when(
                  data: (folders) {
                    final currentBook = widget.note.folderId != null
                        ? folders.where((f) => f.id == widget.note.folderId).firstOrNull
                        : null;
                    final parentGroup = currentBook?.parentFolderId != null
                        ? folders.where((f) => f.id == currentBook!.parentFolderId).firstOrNull
                        : null;
                    final displayName = currentBook == null
                        ? 'No Book'
                        : (parentGroup != null ? '${parentGroup.name} / ${currentBook.name}' : currentBook.name);

                    final groups = folders.where((f) => f.isGroup || (f.parentFolderId == null && folders.any((c) => c.parentFolderId == f.id))).toList();
                    final groupIds = groups.map((g) => g.id).toSet();
                    final standaloneBooks = folders.where((f) => !groupIds.contains(f.id) && f.parentFolderId == null).toList();

                    return PopupMenuButton<String?>(
                      tooltip: 'Assign to Book',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.menu_book_rounded, size: 15, color: theme.hintColor),
                            const SizedBox(width: 6),
                            Text(
                              displayName,
                              style: TextStyle(fontSize: 12, color: theme.hintColor, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: null, child: Text('No Book (Uncategorized)')),
                        if (groups.isNotEmpty) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            enabled: false,
                            child: Text('— GROUP OF BOOKS —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          for (final group in groups) ...[
                            ...folders.where((f) => f.parentFolderId == group.id).map((book) => PopupMenuItem(
                              value: book.id,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  const Icon(Icons.menu_book_rounded, size: 14),
                                  const SizedBox(width: 8),
                                  Text('${group.name} > ${book.name}'),
                                ],
                              ),
                            )),
                          ],
                        ],
                        if (standaloneBooks.isNotEmpty) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            enabled: false,
                            child: Text('— ONLY BOOKS —', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                          ...standaloneBooks.map((book) => PopupMenuItem(
                            value: book.id,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(Icons.menu_book_rounded, size: 14),
                                const SizedBox(width: 8),
                                Text(book.name),
                              ],
                            ),
                          )),
                        ],
                      ],
                      onSelected: (folderId) async {
                        final updated = widget.note.copyWith(
                          folderId: folderId,
                          setFolderIdNull: folderId == null,
                        );
                        await ref.read(notesNotifierProvider.notifier).updateNote(updated);
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                ),

                const Spacer(),

                // Save Status Indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isSaving ? 1.0 : 0.6,
                  child: Row(
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        _isSaving ? 'Saving...' : 'Saved',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // AI Assistant Button
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 20),
                  tooltip: 'AI Assistant',
                  onPressed: _showAiAssistantMenu,
                ),

                // Pin button
                IconButton(
                  icon: Icon(
                    widget.note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: widget.note.isPinned ? theme.primaryColor : null,
                    size: 20,
                  ),
                  tooltip: widget.note.isPinned ? 'Unpin' : 'Pin Note',
                  onPressed: () {
                    ref.read(notesNotifierProvider.notifier).togglePin(widget.note.id, widget.note.isPinned);
                  },
                ),

                // Favorite button
                IconButton(
                  icon: Icon(
                    widget.note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: widget.note.isFavorite ? Colors.amberAccent : null,
                    size: 20,
                  ),
                  tooltip: widget.note.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
                  onPressed: () {
                    ref.read(notesNotifierProvider.notifier).toggleFavorite(widget.note.id, widget.note.isFavorite);
                  },
                ),

                // Lock button (AES-256)
                IconButton(
                  icon: Icon(
                    widget.note.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: widget.note.isLocked ? Colors.amberAccent : null,
                    size: 20,
                  ),
                  tooltip: widget.note.isLocked ? 'Unlock Note (AES-256)' : 'Lock Note (AES-256)',
                  onPressed: _handleLockToggle,
                ),

                // More Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Version History'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.ios_share_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Export Note'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Archive'),
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
                  onSelected: (val) {
                    if (val == 'history') {
                      VersionHistoryDialog.show(context, widget.note);
                    } else if (val == 'export') {
                      _showExportMenu();
                    } else if (val == 'archive') {
                      ref.read(notesNotifierProvider.notifier).toggleArchive(widget.note.id, widget.note.isArchived);
                    } else if (val == 'delete') {
                      ref.read(notesNotifierProvider.notifier).softDelete(widget.note.id);
                    }
                  },
                ),
              ],
            ),
          ),

          // Rich Text Toolbar with full block support
          EditorToolbar(
            controller: _bodyController,
            onStateChanged: _onContentChanged,
            isPreviewMode: _isPreviewMode,
            onTogglePreview: () => setState(() => _isPreviewMode = !_isPreviewMode),
            isBlockMode: _isBlockMode,
            onToggleBlockMode: () => setState(() => _isBlockMode = !_isBlockMode),
            onInsertCodeBlock: () => _blockEditorKey.currentState?.insertCodeBlock('dart'),
            onInsertTodo: () => _blockEditorKey.currentState?.insertTodoItem(),
            onInsertHeading: (lvl) => _blockEditorKey.currentState?.insertHeading(lvl),
            onInsertQuote: () => _blockEditorKey.currentState?.insertQuote(),
            onInsertBullet: () => _blockEditorKey.currentState?.insertBulletItem(),
            onInsertNumbered: () => _blockEditorKey.currentState?.insertNumberedItem(),
            onInsertDivider: () => _blockEditorKey.currentState?.insertDivider(),
          ),

          // Note Content Area
          Expanded(
            child: Container(
              color: theme.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Title Field
                  TextField(
                    controller: _titleController,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Title...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Body: Interactive Block Editor vs Preview vs Raw Markdown
                  Expanded(
                    child: _isPreviewMode
                        ? (_bodyController.text.trim().isEmpty
                            ? const Center(
                                child: Text(
                                  'Nothing to preview yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : Markdown(
                                data: _bodyController.text,
                                selectable: true,
                                padding: EdgeInsets.zero,
                              ))
                        : (_isBlockMode
                            ? InteractiveBlockEditor(
                                key: _blockEditorKey,
                                initialMarkdown: _bodyController.text,
                                onContentChanged: (newText) {
                                  _bodyController.text = newText;
                                  _onContentChanged();
                                },
                              )
                            : TextField(
                                controller: _bodyController,
                                maxLines: null,
                                expands: true,
                                style: const TextStyle(fontSize: 15, height: 1.6),
                                decoration: const InputDecoration(
                                  hintText: 'Start writing markdown...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )),
                  ),
                ],
              ),
            ),
          ),

          // Footer info bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Text(
                  '${TextUtils.countWords(_bodyController.text)} words',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(width: 14),
                Text(
                  '${TextUtils.countCharacters(_bodyController.text)} chars',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
                const Spacer(),
                Text(
                  'Last edited: ${DateFormatter.formatFull(widget.note.updatedAt)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
