import 'dart:io';
import '../entities/backup_manifest.dart';
import '../entities/note.dart';

abstract class BackupRepository {
  Future<File> createEncryptedBackup({
    required String password,
    String? destinationPath,
  });

  Future<BackupManifest> inspectBackup(File backupFile, {required String password});

  Future<void> restoreBackup(File backupFile, {required String password});

  Future<String> exportNoteAsMarkdown(Note note);
  Future<String> exportNoteAsPlainText(Note note);
  Future<String> exportNoteAsJson(Note note);
}
