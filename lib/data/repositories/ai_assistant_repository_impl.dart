import '../../core/utils/text_utils.dart';
import '../../domain/repositories/ai_assistant_repository.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  bool _enabled = true;

  @override
  bool get isAvailable => _enabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  @override
  Future<String> summarizeNote(String content) async {
    final plain = TextUtils.stripMarkdown(content);
    if (plain.isEmpty) return 'No content to summarize.';

    final sentences = plain.split(RegExp(r'(?<=[.?!])\s+')).where((s) => s.trim().isNotEmpty).toList();
    if (sentences.length <= 2) {
      return 'Summary: $plain';
    }
    // Extract key introductory & conclusive sentences
    final summarySentences = [
      sentences.first,
      if (sentences.length > 3) sentences[sentences.length ~/ 2],
      sentences.last,
    ];
    return 'Summary:\n• ${summarySentences.join('\n• ')}';
  }

  @override
  Future<List<String>> extractActionItems(String content) async {
    final plain = TextUtils.stripMarkdown(content);
    final lines = plain.split('\n');
    final actions = <String>[];

    final actionKeywords = RegExp(r'\b(todo|action|must|should|need to|follow up|prepare|send|review|call|schedule)\b', caseSensitive: false);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (actionKeywords.hasMatch(trimmed)) {
        actions.add(trimmed.replaceAll(RegExp(r'^[-*•\d.]+\s*'), ''));
      }
    }

    if (actions.isEmpty) {
      // Return top 2 tasks if no direct keywords found
      final sample = lines.where((l) => l.trim().length > 5).take(3).toList();
      return sample.map((s) => 'Review: ${s.trim()}').toList();
    }

    return actions;
  }

  @override
  Future<List<String>> suggestTags(String content) async {
    final plain = TextUtils.stripMarkdown(content).toLowerCase();
    final words = plain.split(RegExp(r'[^a-zA-Z0-9]+')).where((w) => w.length > 4).toList();

    final frequencies = <String, int>{};
    final stopWords = {'about', 'there', 'their', 'which', 'would', 'could', 'should', 'these', 'those', 'where'};

    for (final word in words) {
      if (!stopWords.contains(word)) {
        frequencies[word] = (frequencies[word] ?? 0) + 1;
      }
    }

    final sorted = frequencies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) => e.key).toList();
  }

  @override
  Future<List<String>> suggestTitles(String content) async {
    final plain = TextUtils.stripMarkdown(content);
    if (plain.isEmpty) return ['Untitled Thought', 'Quick Note', 'Draft Note'];

    final firstLine = plain.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'New Note');
    final words = firstLine.trim().split(' ').take(5).join(' ');

    return [
      words.length > 3 ? words : 'General Note',
      'Notes: $words',
      'Key Highlights: $words',
    ];
  }

  @override
  Future<String> improveWriting(String content, {String tone = 'professional'}) async {
    // Clean whitespace and ensure capitalization
    final lines = content.split('\n');
    final cleaned = lines.map((line) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) return '';
      return trimmed[0].toUpperCase() + trimmed.substring(1);
    }).join('\n');

    return cleaned;
  }

  @override
  Future<String> askQuestion(String prompt, String noteContext) async {
    final plain = TextUtils.stripMarkdown(noteContext);
    if (plain.isEmpty) {
      return 'The current note has no content to analyze.';
    }
    final snippet = plain.length > 150 ? '${plain.substring(0, 150)}...' : plain;
    return 'Based on this note: The note discusses "${plain.split('\n').first}". Relevant context regarding "$prompt": $snippet';
  }
}
