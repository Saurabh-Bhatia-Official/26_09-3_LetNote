import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../data/repositories/ai_assistant_repository_impl.dart';

final aiAssistantRepositoryProvider = Provider<AIAssistantRepository>((ref) {
  return AIAssistantRepositoryImpl();
});

class AIAssistantState {
  final bool isConsentGiven;
  final bool isLoading;
  final String? lastResult;
  final String? errorMessage;

  const AIAssistantState({
    this.isConsentGiven = false,
    this.isLoading = false,
    this.lastResult,
    this.errorMessage,
  });

  AIAssistantState copyWith({
    bool? isConsentGiven,
    bool? isLoading,
    String? lastResult,
    String? errorMessage,
    bool clearResult = false,
  }) {
    return AIAssistantState(
      isConsentGiven: isConsentGiven ?? this.isConsentGiven,
      isLoading: isLoading ?? this.isLoading,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      errorMessage: errorMessage,
    );
  }
}

class AIAssistantNotifier extends Notifier<AIAssistantState> {
  @override
  AIAssistantState build() => const AIAssistantState();

  void setConsent(bool consent) {
    state = state.copyWith(isConsentGiven: consent);
  }

  Future<String?> summarize(String content) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(aiAssistantRepositoryProvider);
      final res = await repo.summarizeNote(content);
      state = state.copyWith(isLoading: false, lastResult: res);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<List<String>> extractTasks(String content) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(aiAssistantRepositoryProvider);
      final res = await repo.extractActionItems(content);
      state = state.copyWith(isLoading: false);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return [];
    }
  }

  Future<List<String>> suggestTags(String content) async {
    final repo = ref.read(aiAssistantRepositoryProvider);
    return await repo.suggestTags(content);
  }

  Future<List<String>> suggestTitles(String content) async {
    final repo = ref.read(aiAssistantRepositoryProvider);
    return await repo.suggestTitles(content);
  }

  void clearResult() {
    state = state.copyWith(clearResult: true, errorMessage: null);
  }
}

final aiAssistantProvider = NotifierProvider<AIAssistantNotifier, AIAssistantState>(AIAssistantNotifier.new);
