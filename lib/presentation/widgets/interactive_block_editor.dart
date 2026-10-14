import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

enum BlockType {
  heading1,
  heading2,
  heading3,
  paragraph,
  todo,
  code,
  quote,
  bullet,
  numbered,
  divider,
}

class NoteBlock {
  final String id;
  BlockType type;
  String content;
  bool isChecked;
  String language;
  int? number;

  NoteBlock({
    required this.id,
    required this.type,
    required this.content,
    this.isChecked = false,
    this.language = 'dart',
    this.number,
  });

  NoteBlock copyWith({
    BlockType? type,
    String? content,
    bool? isChecked,
    String? language,
    int? number,
  }) {
    return NoteBlock(
      id: id,
      type: type ?? this.type,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      language: language ?? this.language,
      number: number ?? this.number,
    );
  }
}

class InteractiveBlockEditor extends StatefulWidget {
  final String initialMarkdown;
  final ValueChanged<String> onContentChanged;

  const InteractiveBlockEditor({
    super.key,
    required this.initialMarkdown,
    required this.onContentChanged,
  });

  @override
  State<InteractiveBlockEditor> createState() => InteractiveBlockEditorState();
}

class InteractiveBlockEditorState extends State<InteractiveBlockEditor> {
  final _uuid = const Uuid();
  List<NoteBlock> _blocks = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _isInternalChange = false;

  static const List<String> supportedLanguages = [
    'dart',
    'javascript',
    'typescript',
    'python',
    'html',
    'css',
    'json',
    'sql',
    'bash',
    'rust',
    'go',
    'cpp',
    'markdown',
    'plaintext',
  ];

  @override
  void initState() {
    super.initState();
    _parseMarkdownToBlocks(widget.initialMarkdown);
  }

  @override
  void didUpdateWidget(covariant InteractiveBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isInternalChange && oldWidget.initialMarkdown != widget.initialMarkdown) {
      _parseMarkdownToBlocks(widget.initialMarkdown);
    }
    _isInternalChange = false;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(NoteBlock block) {
    if (!_controllers.containsKey(block.id)) {
      final controller = TextEditingController(text: block.content);
      controller.addListener(() {
        if (block.content != controller.text) {
          block.content = controller.text;
          _notifyMarkdownChanged();
        }
      });
      _controllers[block.id] = controller;
    }
    return _controllers[block.id]!;
  }

  void _parseMarkdownToBlocks(String markdown) {
    final lines = markdown.split('\n');
    final parsed = <NoteBlock>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Code Block Detection: ```[lang] ... ```
      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        // consume closing ```
        if (i < lines.length && lines[i].trim().startsWith('```')) {
          i++;
        }
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.code,
          content: codeLines.join('\n'),
          language: lang.isEmpty ? 'dart' : lang.toLowerCase(),
        ));
        continue;
      }

      // Checklist / Todo Detection: - [ ] or - [x] or [ ] or [x]
      final todoMatch = RegExp(r'^(?:-\s+)?\[([ xX])\]\s*(.*)$').firstMatch(trimmed);
      if (todoMatch != null) {
        final isChecked = todoMatch.group(1)!.trim().toLowerCase() == 'x';
        final content = todoMatch.group(2) ?? '';
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.todo,
          content: content,
          isChecked: isChecked,
        ));
        i++;
        continue;
      }

      // Headings
      if (trimmed.startsWith('### ')) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.heading3,
          content: trimmed.substring(4),
        ));
        i++;
        continue;
      } else if (trimmed.startsWith('## ')) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.heading2,
          content: trimmed.substring(3),
        ));
        i++;
        continue;
      } else if (trimmed.startsWith('# ')) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.heading1,
          content: trimmed.substring(2),
        ));
        i++;
        continue;
      }

      // Blockquotes
      if (trimmed.startsWith('> ')) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.quote,
          content: trimmed.substring(2),
        ));
        i++;
        continue;
      }

      // Divider
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.divider,
          content: '',
        ));
        i++;
        continue;
      }

      // Numbered list
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final num = int.tryParse(numMatch.group(1)!) ?? 1;
        final content = numMatch.group(2) ?? '';
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.numbered,
          content: content,
          number: num,
        ));
        i++;
        continue;
      }

      // Bullet list
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.bullet,
          content: trimmed.substring(2),
        ));
        i++;
        continue;
      }

      // Default paragraph (ignore purely blank lines unless whole note is empty)
      if (trimmed.isNotEmpty || parsed.isEmpty) {
        parsed.add(NoteBlock(
          id: _uuid.v4(),
          type: BlockType.paragraph,
          content: line,
        ));
      }
      i++;
    }

    if (parsed.isEmpty) {
      parsed.add(NoteBlock(
        id: _uuid.v4(),
        type: BlockType.paragraph,
        content: '',
      ));
    }

    setState(() {
      _blocks = parsed;
    });
  }

  String _blocksToMarkdown() {
    final buffer = StringBuffer();
    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      switch (block.type) {
        case BlockType.heading1:
          buffer.writeln('# ${block.content}');
          buffer.writeln();
          break;
        case BlockType.heading2:
          buffer.writeln('## ${block.content}');
          buffer.writeln();
          break;
        case BlockType.heading3:
          buffer.writeln('### ${block.content}');
          buffer.writeln();
          break;
        case BlockType.todo:
          buffer.writeln('- [${block.isChecked ? 'x' : ' '}] ${block.content}');
          break;
        case BlockType.code:
          buffer.writeln('```${block.language}');
          buffer.writeln(block.content);
          buffer.writeln('```');
          buffer.writeln();
          break;
        case BlockType.quote:
          buffer.writeln('> ${block.content}');
          buffer.writeln();
          break;
        case BlockType.bullet:
          buffer.writeln('- ${block.content}');
          break;
        case BlockType.numbered:
          buffer.writeln('${block.number ?? (i + 1)}. ${block.content}');
          break;
        case BlockType.divider:
          buffer.writeln('---');
          buffer.writeln();
          break;
        case BlockType.paragraph:
          buffer.writeln(block.content);
          buffer.writeln();
          break;
      }
    }
    return buffer.toString().trimRight();
  }

  void _notifyMarkdownChanged() {
    _isInternalChange = true;
    final markdown = _blocksToMarkdown();
    widget.onContentChanged(markdown);
  }

  // Public methods called by toolbar
  void insertCodeBlock([String language = 'dart']) {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.code,
        content: '',
        language: language,
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertTodoItem() {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.todo,
        content: '',
        isChecked: false,
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertHeading(int level) {
    setState(() {
      final type = level == 1
          ? BlockType.heading1
          : level == 2
              ? BlockType.heading2
              : BlockType.heading3;
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: type,
        content: '',
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertQuote() {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.quote,
        content: '',
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertBulletItem() {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.bullet,
        content: '',
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertNumberedItem() {
    setState(() {
      final count = _blocks.where((b) => b.type == BlockType.numbered).length + 1;
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.numbered,
        content: '',
        number: count,
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertDivider() {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.divider,
        content: '',
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void insertParagraph() {
    setState(() {
      final newBlock = NoteBlock(
        id: _uuid.v4(),
        type: BlockType.paragraph,
        content: '',
      );
      _blocks.add(newBlock);
    });
    _notifyMarkdownChanged();
  }

  void _removeBlock(int index) {
    if (index >= 0 && index < _blocks.length) {
      setState(() {
        final removed = _blocks.removeAt(index);
        _controllers.remove(removed.id)?.dispose();
        if (_blocks.isEmpty) {
          _blocks.add(NoteBlock(
            id: _uuid.v4(),
            type: BlockType.paragraph,
            content: '',
          ));
        }
      });
      _notifyMarkdownChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: _blocks.length + 1,
      itemBuilder: (context, index) {
        if (index == _blocks.length) {
          return _buildQuickAddBar(theme);
        }
        final block = _blocks[index];
        return Padding(
          key: ValueKey(block.id),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _buildBlockWidget(theme, block, index),
        );
      },
    );
  }

  Widget _buildBlockWidget(ThemeData theme, NoteBlock block, int index) {
    switch (block.type) {
      case BlockType.todo:
        return _buildTodoWidget(theme, block, index);
      case BlockType.code:
        return _buildCodeBlockWidget(theme, block, index);
      case BlockType.heading1:
        return _buildHeadingWidget(theme, block, index, 24, FontWeight.bold, theme.primaryColor);
      case BlockType.heading2:
        return _buildHeadingWidget(theme, block, index, 20, FontWeight.bold, null);
      case BlockType.heading3:
        return _buildHeadingWidget(theme, block, index, 17, FontWeight.w600, null);
      case BlockType.quote:
        return _buildQuoteWidget(theme, block, index);
      case BlockType.bullet:
        return _buildBulletWidget(theme, block, index);
      case BlockType.numbered:
        return _buildNumberedWidget(theme, block, index);
      case BlockType.divider:
        return _buildDividerWidget(theme, block, index);
      case BlockType.paragraph:
        return _buildParagraphWidget(theme, block, index);
    }
  }

  // 1. To-Do Checklist Widget with Interactive Radio Button
  Widget _buildTodoWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: block.isChecked
            ? theme.dividerColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Interactive Radio Button for Checklist
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                block.isChecked = !block.isChecked;
              });
              _notifyMarkdownChanged();
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: block.isChecked
                      ? theme.primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: block.isChecked
                        ? theme.primaryColor
                        : theme.hintColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: block.isChecked
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Editable task text
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontSize: 15,
                decoration: block.isChecked ? TextDecoration.lineThrough : null,
                decorationColor: theme.hintColor,
                color: block.isChecked ? theme.hintColor : null,
              ),
              decoration: InputDecoration(
                hintText: 'To-do item...',
                hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => insertTodoItem(),
            ),
          ),

          // Delete todo button
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.5)),
            tooltip: 'Delete Item',
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(index),
          ),
        ],
      ),
    );
  }

  // 2. Dedicated Code Block Container Widget
  Widget _buildCodeBlockWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);
    const codeBg = Color(0xFF1E1E2E);
    const codeHeaderBg = Color(0xFF181825);
    const codeTextColor = Color(0xFFCDD6F4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF313244)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code Block Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: codeHeaderBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: Color(0xFF313244))),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFFCBA6F7)),
                const SizedBox(width: 8),
                // Language Dropdown
                PopupMenuButton<String>(
                  tooltip: 'Change Language',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF313244),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          block.language.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF89B4FA),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded, size: 14, color: Color(0xFF89B4FA)),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => supportedLanguages.map((lang) {
                    return PopupMenuItem(
                      value: lang,
                      child: Text(lang.toUpperCase(), style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onSelected: (selectedLang) {
                    setState(() {
                      block.language = selectedLang;
                    });
                    _notifyMarkdownChanged();
                  },
                ),
                const Spacer(),
                // Copy Code Button
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFA6ADC8)),
                  tooltip: 'Copy Code',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Code copied to clipboard!'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                // Remove Code Block Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFF38BA8)),
                  tooltip: 'Delete Code Block',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeBlock(index),
                ),
              ],
            ),
          ),

          // Code Text Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                color: codeTextColor,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: '// Write your code snippet here...',
                hintStyle: TextStyle(color: Color(0xFF6C7086), fontFamily: 'monospace'),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Heading Widget (H1, H2, H3)
  Widget _buildHeadingWidget(
    ThemeData theme,
    NoteBlock block,
    int index,
    double fontSize,
    FontWeight fontWeight,
    Color? color,
  ) {
    final controller = _getController(block);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color ?? theme.textTheme.titleLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Heading...',
              hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeBlock(index),
        ),
      ],
    );
  }

  // 4. Blockquote Widget
  Widget _buildQuoteWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
        border: Border(
          left: BorderSide(color: theme.primaryColor, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, size: 20, color: theme.primaryColor.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 15,
                color: theme.textTheme.bodyMedium?.color,
              ),
              decoration: const InputDecoration(
                hintText: 'Quote text...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(index),
          ),
        ],
      ),
    );
  }

  // 5. Bullet List Widget
  Widget _buildBulletWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'List item...',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
            onSubmitted: (_) => insertBulletItem(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeBlock(index),
        ),
      ],
    );
  }

  // 6. Numbered List Widget
  Widget _buildNumberedWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);
    final numStr = '${block.number ?? (index + 1)}.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            numStr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'Numbered item...',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
            onSubmitted: (_) => insertNumberedItem(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeBlock(index),
        ),
      ],
    );
  }

  // 7. Divider Widget
  Widget _buildDividerWidget(ThemeData theme, NoteBlock block, int index) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.dividerColor,
            thickness: 1.5,
          ),
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.4)),
          visualDensity: VisualDensity.compact,
          onPressed: () => _removeBlock(index),
        ),
      ],
    );
  }

  // 8. Paragraph Widget
  Widget _buildParagraphWidget(ThemeData theme, NoteBlock block, int index) {
    final controller = _getController(block);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: index == 0 ? 'Start writing...' : 'Type text...',
              hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.5)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ),
        if (_blocks.length > 1)
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: theme.hintColor.withValues(alpha: 0.3)),
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeBlock(index),
          ),
      ],
    );
  }

  // Quick Block Add Bar at the bottom
  Widget _buildQuickAddBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Add Block:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
            ),
          ),
          _QuickAddChip(
            icon: Icons.check_circle_outline_rounded,
            label: 'To-Do Radio',
            onTap: insertTodoItem,
          ),
          _QuickAddChip(
            icon: Icons.code_rounded,
            label: 'Code Block',
            onTap: () => insertCodeBlock('dart'),
          ),
          _QuickAddChip(
            icon: Icons.title_rounded,
            label: 'Heading',
            onTap: () => insertHeading(2),
          ),
          _QuickAddChip(
            icon: Icons.format_quote_rounded,
            label: 'Quote',
            onTap: insertQuote,
          ),
          _QuickAddChip(
            icon: Icons.format_list_bulleted_rounded,
            label: 'Bullet',
            onTap: insertBulletItem,
          ),
          _QuickAddChip(
            icon: Icons.text_fields_rounded,
            label: 'Text',
            onTap: insertParagraph,
          ),
        ],
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 14, color: theme.primaryColor),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      onPressed: onTap,
    );
  }
}
