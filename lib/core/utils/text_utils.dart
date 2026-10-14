class TextUtils {
  /// Calculate word count of a string
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    final words = text.trim().split(RegExp(r'\s+'));
    return words.length;
  }

  /// Calculate character count excluding whitespace
  static int countCharacters(String text, {bool includeWhitespace = true}) {
    if (includeWhitespace) {
      return text.length;
    }
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  /// Strip markdown and formatting symbols for clean plain text preview and FTS5 indexing
  static String stripMarkdown(String markdown) {
    var plain = markdown;
    // Remove headers
    plain = plain.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Remove bold/italic (handling ***, **, *, ___, __, _)
    plain = plain.replaceAllMapped(RegExp(r'\*\*\*([^*]+?)\*\*\*'), (m) => m[1]!);
    plain = plain.replaceAllMapped(RegExp(r'___([^_]+?)___'), (m) => m[1]!);
    plain = plain.replaceAllMapped(RegExp(r'\*\*([^*]+?)\*\*'), (m) => m[1]!);
    plain = plain.replaceAllMapped(RegExp(r'__([^_]+?)__'), (m) => m[1]!);
    plain = plain.replaceAllMapped(RegExp(r'\*([^*]+?)\*'), (m) => m[1]!);
    plain = plain.replaceAllMapped(RegExp(r'_([^_]+?)_'), (m) => m[1]!);
    // Remove inline code
    plain = plain.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
    // Remove code blocks
    plain = plain.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    // Remove blockquotes
    plain = plain.replaceAll(RegExp(r'^>\s+', multiLine: true), '');
    // Remove checklists
    plain = plain.replaceAll(RegExp(r'^-\s+\[[\sxX]\]\s+', multiLine: true), '');
    // Remove list markers
    plain = plain.replaceAll(RegExp(r'^[\*\-\+]\s+', multiLine: true), '');
    plain = plain.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    // Remove links [text](url) -> text
    plain = plain.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m[1]!);
    return plain.trim();
  }

  /// Extract auto-title from the first non-empty line of content
  static String extractTitleFromContent(String content, [String defaultTitle = 'Untitled Note']) {
    final lines = content.trim().split('\n');
    for (var line in lines) {
      final stripped = stripMarkdown(line).trim();
      if (stripped.isNotEmpty) {
        if (stripped.length > 60) {
          return '${stripped.substring(0, 57)}...';
        }
        return stripped;
      }
    }
    return defaultTitle;
  }

  /// Generate highlighted preview snippet around matching search terms
  static String createSnippet(String content, String query, {int snippetLength = 120}) {
    if (query.trim().isEmpty || content.isEmpty) {
      final preview = stripMarkdown(content);
      return preview.length > snippetLength
          ? '${preview.substring(0, snippetLength)}...'
          : preview;
    }

    final lowerContent = content.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerContent.indexOf(lowerQuery);

    if (index == -1) {
      final preview = stripMarkdown(content);
      return preview.length > snippetLength
          ? '${preview.substring(0, snippetLength)}...'
          : preview;
    }

    final start = (index - 40).clamp(0, content.length);
    final end = (index + query.length + 80).clamp(0, content.length);

    var snippet = content.substring(start, end).replaceAll('\n', ' ');
    if (start > 0) snippet = '...$snippet';
    if (end < content.length) snippet = '$snippet...';

    return snippet;
  }
}
