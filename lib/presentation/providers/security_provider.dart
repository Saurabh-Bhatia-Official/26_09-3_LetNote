import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/encryption_service.dart';
import '../../domain/repositories/security_repository.dart';
import '../../data/repositories/security_repository_impl.dart';
import 'notes_provider.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepositoryImpl();
});

class SecurityState {
  final bool hasPin;
  final bool isAppUnlocked;
  final Set<String> unlockedNoteIds;
  final int autoLockTimeoutMinutes;
  final bool isBiometricsEnabled;

  const SecurityState({
    this.hasPin = false,
    this.isAppUnlocked = true,
    this.unlockedNoteIds = const {},
    this.autoLockTimeoutMinutes = 5,
    this.isBiometricsEnabled = false,
  });

  bool isNoteUnlocked(String noteId) => unlockedNoteIds.contains(noteId);

  SecurityState copyWith({
    bool? hasPin,
    bool? isAppUnlocked,
    Set<String>? unlockedNoteIds,
    int? autoLockTimeoutMinutes,
    bool? isBiometricsEnabled,
  }) {
    return SecurityState(
      hasPin: hasPin ?? this.hasPin,
      isAppUnlocked: isAppUnlocked ?? this.isAppUnlocked,
      unlockedNoteIds: unlockedNoteIds ?? this.unlockedNoteIds,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
    );
  }
}

class SecurityNotifier extends Notifier<SecurityState> {
  @override
  SecurityState build() {
    _init();
    return const SecurityState();
  }

  Future<void> _init() async {
    final repo = ref.read(securityRepositoryProvider);
    final hasPin = await repo.hasPinSet();
    final timeout = await repo.getAutoLockTimeoutMinutes();
    final bio = await repo.isBiometricsEnabled();

    state = state.copyWith(
      hasPin: hasPin,
      autoLockTimeoutMinutes: timeout,
      isBiometricsEnabled: bio,
      isAppUnlocked: !hasPin,
    );
  }

  Future<bool> verifyPin(String pin) async {
    final repo = ref.read(securityRepositoryProvider);
    final isValid = await repo.verifyPin(pin);
    if (isValid) {
      state = state.copyWith(isAppUnlocked: true);
    }
    return isValid;
  }

  Future<void> setPin(String pin) async {
    final repo = ref.read(securityRepositoryProvider);
    await repo.setPin(pin);
    state = state.copyWith(hasPin: true, isAppUnlocked: true);
  }

  Future<void> removePin() async {
    final repo = ref.read(securityRepositoryProvider);
    await repo.removePin();
    state = state.copyWith(
      hasPin: false,
      isAppUnlocked: true,
      unlockedNoteIds: {},
    );
  }

  Future<void> lockNoteWithPin(String noteId, String pin) async {
    final notesRepo = ref.read(noteRepositoryProvider);
    final note = await notesRepo.getNoteById(noteId);
    if (note != null) {
      final encrypted = EncryptionService.encryptText(note.bodyDelta, pin);
      final updated = note.copyWith(
        isLocked: true,
        encryptedBody: encrypted,
        bodyDelta: '',
      );
      await notesRepo.updateNote(updated);

      final newSet = Set<String>.from(state.unlockedNoteIds)..remove(noteId);
      state = state.copyWith(unlockedNoteIds: newSet);

      ref.invalidate(notesNotifierProvider);
    }
  }

  Future<bool> unlockNote(String noteId, String pin) async {
    final repo = ref.read(securityRepositoryProvider);
    final isValid = await repo.verifyPin(pin);
    if (!isValid) return false;

    final notesRepo = ref.read(noteRepositoryProvider);
    final note = await notesRepo.getNoteById(noteId);
    if (note != null && note.encryptedBody != null) {
      try {
        final decrypted = EncryptionService.decryptText(note.encryptedBody!, pin);
        final newSet = Set<String>.from(state.unlockedNoteIds)..add(noteId);
        state = state.copyWith(unlockedNoteIds: newSet);

        final decryptedNote = note.copyWith(bodyDelta: decrypted);
        await notesRepo.updateNote(decryptedNote);
        ref.invalidate(notesNotifierProvider);
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  bool isNoteUnlocked(String noteId) {
    return state.unlockedNoteIds.contains(noteId);
  }

  Future<void> setAutoLockTimeoutMinutes(int minutes) async {
    final repo = ref.read(securityRepositoryProvider);
    await repo.setAutoLockTimeoutMinutes(minutes);
    state = state.copyWith(autoLockTimeoutMinutes: minutes);
  }

  void relockAllNotes() {
    state = state.copyWith(unlockedNoteIds: {});
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(SecurityNotifier.new);
