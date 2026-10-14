import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/crypto/encryption_service.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/backup_manifest.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/backup_repository.dart';
import '../datasources/database_helper.dart';

class BackupRepositoryImpl implements BackupRepository {
  final DatabaseHelper databaseHelper;

  BackupRepositoryImpl({DatabaseHelper? dbHelper})
      : databaseHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<File> createEncryptedBackup({
    required String password,
    String? destinationPath,
  }) async {
    final db = await databaseHelper.database;

    // 1. Fetch all data
    final notes = await db.query('notes');
    final folders = await db.query('folders');
    final tags = await db.query('tags');
    final noteTags = await db.query('note_tags');
    final attachments = await db.query('attachments');

    final dataPayload = {
      'notes': notes,
      'folders': folders,
      'tags': tags,
      'note_tags': noteTags,
      'attachments': attachments,
    };

    final jsonString = jsonEncode(dataPayload);
    final utf8Bytes = utf8.encode(jsonString);
    final checksum = EncryptionService.calculateChecksum(utf8Bytes);

    final manifest = BackupManifest(
      appVersion: AppConstants.appVersion,
      exportedAt: DateTime.now(),
      noteCount: notes.length,
      folderCount: folders.length,
      tagCount: tags.length,
      attachmentCount: attachments.length,
      checksum: checksum,
    );

    // 2. Encrypt the data payload with user's backup password
    final encryptedData = EncryptionService.encryptText(jsonString, password);

    // 3. Create ZIP archive
    final archive = Archive();

    // Manifest is unencrypted to allow pre-restore preview
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // Data payload is encrypted
    final payloadBytes = utf8.encode(encryptedData);
    archive.addFile(ArchiveFile('data.enc', payloadBytes.length, payloadBytes));

    final zipData = ZipEncoder().encode(archive);
    if (zipData.isEmpty) {
      throw const BackupFailure('Failed to encode backup zip archive');
    }

    // 4. Save to destination or documents directory
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    String finalPath;
    if (destinationPath != null && destinationPath.isNotEmpty) {
      finalPath = destinationPath;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final backupFolder = Directory(p.join(docDir.path, 'LetNote', 'Backups'));
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      finalPath = p.join(backupFolder.path, 'letnote_backup_$timestamp.letnote');
    }

    final file = File(finalPath);
    await file.writeAsBytes(zipData);
    return file;
  }

  @override
  Future<BackupManifest> inspectBackup(File backupFile, {required String password}) async {
    if (!await backupFile.exists()) {
      throw const BackupFailure('Backup file does not exist');
    }

    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const BackupFailure('Invalid backup file: manifest.json missing');
    }

    final manifestJson = jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
    final manifest = BackupManifest.fromJson(manifestJson);

    // Verify password by attempting to decrypt the data file
    final dataFile = archive.findFile('data.enc');
    if (dataFile == null) {
      throw const BackupFailure('Invalid backup file: encrypted data payload missing');
    }

    final encryptedString = utf8.decode(dataFile.content as List<int>);
    try {
      final decrypted = EncryptionService.decryptText(encryptedString, password);
      final decryptedBytes = utf8.encode(decrypted);
      final computedChecksum = EncryptionService.calculateChecksum(decryptedBytes);

      if (computedChecksum != manifest.checksum) {
        throw const BackupFailure('Checksum mismatch: backup file data may be corrupted.');
      }
    } catch (e) {
      if (e is BackupFailure) rethrow;
      throw const BackupFailure('Incorrect backup password or corrupted data file.');
    }

    return manifest;
  }

  @override
  Future<void> restoreBackup(File backupFile, {required String password}) async {
    final bytes = await backupFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final dataFile = archive.findFile('data.enc');
    if (dataFile == null) {
      throw const BackupFailure('Invalid backup: data.enc missing');
    }

    final encryptedString = utf8.decode(dataFile.content as List<int>);
    final decryptedString = EncryptionService.decryptText(encryptedString, password);
    final data = jsonDecode(decryptedString) as Map<String, dynamic>;

    final db = await databaseHelper.database;

    await db.transaction((txn) async {
      // 1. Restore Folders
      final folders = data['folders'] as List<dynamic>? ?? [];
      for (final f in folders) {
        await txn.insert('folders', f as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 2. Restore Tags
      final tags = data['tags'] as List<dynamic>? ?? [];
      for (final t in tags) {
        await txn.insert('tags', t as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 3. Restore Notes
      final notes = data['notes'] as List<dynamic>? ?? [];
      for (final n in notes) {
        final noteMap = n as Map<String, dynamic>;
        await txn.insert('notes', noteMap, conflictAlgorithm: ConflictAlgorithm.replace);

        // Sync FTS
        final isLocked = (noteMap['is_locked'] as int? ?? 0) == 1;
        final isDeleted = noteMap['deleted_at'] != null;
        if (!isLocked && !isDeleted) {
          try {
            await txn.delete('notes_fts', where: 'note_id = ?', whereArgs: [noteMap['id']]);
            await txn.insert('notes_fts', {
              'note_id': noteMap['id'],
              'title': noteMap['title'] ?? '',
              'plain_text_body': TextUtils.stripMarkdown(noteMap['body_delta'] ?? ''),
              'tag_names': '',
              'ocr_text': '',
            });
          } catch (_) {}
        }
      }

      // 4. Restore Note Tags
      final noteTags = data['note_tags'] as List<dynamic>? ?? [];
      for (final nt in noteTags) {
        await txn.insert('note_tags', nt as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<String> exportNoteAsMarkdown(Note note) async {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln('**Type:** ${note.noteType.name}  ');
    buffer.writeln('**Created:** ${note.createdAt.toIso8601String()}  ');
    buffer.writeln('**Last Updated:** ${note.updatedAt.toIso8601String()}  ');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(note.bodyDelta);
    return buffer.toString();
  }

  @override
  Future<String> exportNoteAsPlainText(Note note) async {
    final buffer = StringBuffer();
    buffer.writeln(note.title);
    buffer.writeln('=' * note.title.length);
    buffer.writeln();
    buffer.writeln(TextUtils.stripMarkdown(note.bodyDelta));
    return buffer.toString();
  }

  @override
  Future<String> exportNoteAsJson(Note note) async {
    final map = {
      'id': note.id,
      'title': note.title,
      'body': note.bodyDelta,
      'type': note.noteType.name,
      'pinned': note.isPinned,
      'favorite': note.isFavorite,
      'archived': note.isArchived,
      'tags': note.tagIds,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
