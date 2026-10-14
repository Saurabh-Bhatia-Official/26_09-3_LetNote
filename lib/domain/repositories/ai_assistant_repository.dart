abstract class AIAssistantRepository {
  bool get isAvailable;

  Future<String> summarizeNote(String content);

  Future<List<String>> extractActionItems(String content);

  Future<List<String>> suggestTags(String content);

  Future<List<String>> suggestTitles(String content);

  Future<String> improveWriting(String content, {String tone = 'professional'});

  Future<String> askQuestion(String prompt, String noteContext);
}
