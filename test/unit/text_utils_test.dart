import 'package:flutter_test/flutter_test.dart';
import 'package:let_note/core/utils/text_utils.dart';

void main() {
  group('TextUtils Tests', () {
    test('Word count and character count calculation', () {
      const text = 'Quick brown fox jumps over lazy dog';
      expect(TextUtils.countWords(text), equals(7));
      expect(TextUtils.countCharacters(text, includeWhitespace: true), equals(35));
      expect(TextUtils.countCharacters(text, includeWhitespace: false), equals(29));
      expect(TextUtils.countWords('   '), equals(0));
    });

    test('Strip markdown formatting symbols', () {
      const markdown = '''
# Main Header
**Bold text** and *italic text*
- [ ] Task 1
- [x] Task 2
> A wise quote
`code snippet`
''';
      final plain = TextUtils.stripMarkdown(markdown);
      expect(plain.contains('#'), isFalse);
      expect(plain.contains('**'), isFalse);
      expect(plain.contains('[ ]'), isFalse);
      expect(plain.contains('Main Header'), isTrue);
      expect(plain.contains('Bold text and italic text'), isTrue);
    });

    test('Extract title from content if untitled', () {
      const content = '''
### Meeting with Product Team
Discussed roadmap v1.0 and offline-first SQLite FTS5 features.
''';
      final title = TextUtils.extractTitleFromContent(content);
      expect(title, equals('Meeting with Product Team'));
    });

    test('Snippet creation around matched query', () {
      const content = 'LetNote is a powerful notes app designed for offline first productivity with high performance.';
      final snippet = TextUtils.createSnippet(content, 'offline first');
      expect(snippet.toLowerCase().contains('offline first'), isTrue);
    });
  });
}
