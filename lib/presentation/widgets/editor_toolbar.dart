import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onStateChanged;
  final bool isPreviewMode;
  final VoidCallback onTogglePreview;
  final bool isBlockMode;
  final VoidCallback? onToggleBlockMode;

  final VoidCallback? onInsertCodeBlock;
  final VoidCallback? onInsertTodo;
  final void Function(int level)? onInsertHeading;
  final VoidCallback? onInsertQuote;
  final VoidCallback? onInsertBullet;
  final VoidCallback? onInsertNumbered;
  final VoidCallback? onInsertDivider;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.onStateChanged,
    required this.isPreviewMode,
    required this.onTogglePreview,
    this.isBlockMode = true,
    this.onToggleBlockMode,
    this.onInsertCodeBlock,
    this.onInsertTodo,
    this.onInsertHeading,
    this.onInsertQuote,
    this.onInsertBullet,
    this.onInsertNumbered,
    this.onInsertDivider,
  });

  void _wrapSelection(String prefix, [String? suffix]) {
    final s = suffix ?? prefix;
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final cursor = selection.isValid ? selection.baseOffset : text.length;
      final newText = text.replaceRange(cursor, cursor, '$prefix$s');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + prefix.length),
      );
    } else {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$s');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start + prefix.length,
          extentOffset: selection.end + prefix.length,
        ),
      );
    }
    onStateChanged();
  }

  void _insertAtLineStart(String marker) {
    final text = controller.text;
    final selection = controller.selection;
    final cursor = selection.isValid ? selection.baseOffset : text.length;

    // Find the start of the current line
    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, marker);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + marker.length),
    );
    onStateChanged();
  }

  void _insertSnippet(String snippet) {
    final text = controller.text;
    final selection = controller.selection;
    final cursor = selection.isValid ? selection.baseOffset : text.length;

    final newText = text.replaceRange(cursor, cursor, snippet);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + snippet.length),
    );
    onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Mode indicator chip
          if (onToggleBlockMode != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ActionChip(
                avatar: Icon(
                  isBlockMode ? Icons.view_agenda_rounded : Icons.code_rounded,
                  size: 14,
                  color: theme.primaryColor,
                ),
                label: Text(
                  isBlockMode ? 'Blocks' : 'Markdown',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: isBlockMode ? 'Switch to Raw Markdown' : 'Switch to Block Editor',
                onPressed: onToggleBlockMode,
              ),
            ),
            _buildDivider(theme),
          ],

          // Headings
          _ToolbarButton(
            tooltip: 'Heading 1',
            icon: Icons.title_rounded,
            onPressed: () {
              if (isBlockMode && onInsertHeading != null) {
                onInsertHeading!(1);
              } else {
                _insertAtLineStart('# ');
              }
            },
          ),
          _ToolbarButton(
            tooltip: 'Heading 2',
            icon: Icons.format_size_rounded,
            onPressed: () {
              if (isBlockMode && onInsertHeading != null) {
                onInsertHeading!(2);
              } else {
                _insertAtLineStart('## ');
              }
            },
          ),
          _ToolbarButton(
            tooltip: 'Heading 3',
            icon: Icons.text_fields_rounded,
            onPressed: () {
              if (isBlockMode && onInsertHeading != null) {
                onInsertHeading!(3);
              } else {
                _insertAtLineStart('### ');
              }
            },
          ),
          _buildDivider(theme),

          // Text styling
          _ToolbarButton(
            tooltip: 'Bold (Ctrl+B)',
            icon: Icons.format_bold_rounded,
            onPressed: () => _wrapSelection('**'),
          ),
          _ToolbarButton(
            tooltip: 'Italic (Ctrl+I)',
            icon: Icons.format_italic_rounded,
            onPressed: () => _wrapSelection('*'),
          ),
          _ToolbarButton(
            tooltip: 'Strikethrough',
            icon: Icons.format_strikethrough_rounded,
            onPressed: () => _wrapSelection('~~'),
          ),
          _buildDivider(theme),

          // To-Do Checklist Item with Radio Button
          _ToolbarButton(
            tooltip: 'To-Do Radio Checklist',
            icon: Icons.check_circle_outline_rounded,
            onPressed: () {
              if (isBlockMode && onInsertTodo != null) {
                onInsertTodo!();
              } else {
                _insertAtLineStart('- [ ] ');
              }
            },
          ),

          // Bullet List
          _ToolbarButton(
            tooltip: 'Bullet List',
            icon: Icons.format_list_bulleted_rounded,
            onPressed: () {
              if (isBlockMode && onInsertBullet != null) {
                onInsertBullet!();
              } else {
                _insertAtLineStart('- ');
              }
            },
          ),

          // Numbered List
          _ToolbarButton(
            tooltip: 'Numbered List',
            icon: Icons.format_list_numbered_rounded,
            onPressed: () {
              if (isBlockMode && onInsertNumbered != null) {
                onInsertNumbered!();
              } else {
                _insertAtLineStart('1. ');
              }
            },
          ),
          _buildDivider(theme),

          // Code Block Container
          _ToolbarButton(
            tooltip: 'Code Block',
            icon: Icons.code_rounded,
            onPressed: () {
              if (isBlockMode && onInsertCodeBlock != null) {
                onInsertCodeBlock!();
              } else {
                _wrapSelection('```dart\n', '\n```');
              }
            },
          ),

          // Blockquote
          _ToolbarButton(
            tooltip: 'Blockquote',
            icon: Icons.format_quote_rounded,
            onPressed: () {
              if (isBlockMode && onInsertQuote != null) {
                onInsertQuote!();
              } else {
                _insertAtLineStart('> ');
              }
            },
          ),

          // Horizontal Divider
          _ToolbarButton(
            tooltip: 'Divider',
            icon: Icons.horizontal_rule_rounded,
            onPressed: () {
              if (isBlockMode && onInsertDivider != null) {
                onInsertDivider!();
              } else {
                _insertSnippet('\n\n---\n\n');
              }
            },
          ),

          // Link
          _ToolbarButton(
            tooltip: 'Insert Link',
            icon: Icons.link_rounded,
            onPressed: () => _wrapSelection('[', '](https://)'),
          ),

          _buildDivider(theme),

          // Preview Toggle Button
          IconButton(
            tooltip: isPreviewMode ? 'Switch to Edit' : 'Preview Note',
            icon: Icon(
              isPreviewMode ? Icons.edit_note_rounded : Icons.visibility_outlined,
              color: isPreviewMode ? theme.primaryColor : null,
              size: 20,
            ),
            onPressed: onTogglePreview,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      color: theme.dividerColor,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 19),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
