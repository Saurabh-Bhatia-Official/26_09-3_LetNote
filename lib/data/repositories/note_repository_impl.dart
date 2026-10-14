import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/text_utils.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_version.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/database_helper.dart';
import '../models/note_model.dart';
import '../models/note_version_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final DatabaseHelper databaseHelper;
  final Uuid _uuid = const Uuid();

  NoteRepositoryImpl({DatabaseHelper? dbHelper})
      : databaseHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Note>> getNotes({
    String? folderId,
    String? tagId,
    bool includeArchived = false,
    bool includeTrash = false,
    bool pinnedOnly = false,
    bool favoritesOnly = false,
    NoteType? noteType,
  }) async {
    final db = await databaseHelper.database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // Trash condition
    if (includeTrash) {
      whereClauses.add('n.deleted_at IS NOT NULL');
    } else {
      whereClauses.add('n.deleted_at IS NULL');

      // Archive condition
      if (!includeArchived) {
        whereClauses.add('n.is_archived = 0');
      }
    }

    // Folder condition
    if (folderId != null) {
      if (folderId.isEmpty) {
        whereClauses.add('n.folder_id IS NULL');
      } else {
        whereClauses.add('n.folder_id = ?');
        whereArgs.add(folderId);
      }
    }

    // Pin condition
    if (pinnedOnly) {
      whereClauses.add('n.is_pinned = 1');
    }

    // Favorite condition
    if (favoritesOnly) {
      whereClauses.add('n.is_favorite = 1');
    }

    // Note Type condition
    if (noteType != null) {
      whereClauses.add('n.note_type = ?');
      whereArgs.add(noteType.name.toLowerCase());
    }

    String query;
    if (tagId != null) {
      query = '''
        SELECT DISTINCT n.* FROM notes n
        INNER JOIN note_tags nt ON n.id = nt.note_id
        WHERE nt.tag_id = ?
        ${whereClauses.isNotEmpty ? 'AND ${whereClauses.join(' AND ')}' : ''}
        ORDER BY n.is_pinned DESC, n.updated_at DESC
      ''';
      whereArgs.insert(0, tagId);
    } else {
      query = '''
        SELECT n.* FROM notes n
        ${whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : ''}
        ORDER BY n.is_pinned DESC, n.updated_at DESC
      ''';
    }

    final result = await db.rawQuery(query, whereArgs);

    final notes = <Note>[];
    for (final row in result) {
      final noteId = row['id'] as String;
      final tags = await _getTagsForNote(db, noteId);
      notes.add(NoteModel.fromMap(row, tags));
    }
    return notes;
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final db = await databaseHelper.database;
    final result = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    final tags = await _getTagsForNote(db, id);
    return NoteModel.fromMap(result.first, tags);
  }

  @override
  Future<void> saveNote(Note note) async {
    final db = await databaseHelper.database;
    final model = NoteModel.fromEntity(note);

    await db.transaction((txn) async {
      await txn.insert(
        'notes',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update tags
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      for (final tagId in note.tagIds) {
        await txn.insert('note_tags', {
          'note_id': note.id,
          'tag_id': tagId,
        });
      }

      // Update FTS table
      await _syncFTS(txn, note);
    });
  }

  @override
  Future<void> updateNote(Note note) async {
    final db = await databaseHelper.database;
    final model = NoteModel.fromEntity(note);

    await db.transaction((txn) async {
      await txn.update(
        'notes',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );

      // Update tags
      await txn.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
      for (final tagId in note.tagIds) {
        await txn.insert('note_tags', {
          'note_id': note.id,
          'tag_id': tagId,
        });
      }

      // Update FTS table
      await _syncFTS(txn, note);
    });
  }

  @override
  Future<void> softDeleteNote(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'notes',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreNote(String id) async {
    final db = await databaseHelper.database;
    await db.update(
      'notes',
      {
        'deleted_at': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> permanentlyDeleteNote(String id) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('notes', where: 'id = ?', whereArgs: [id]);
      try {
        await txn.delete('notes_fts', where: 'note_id = ?', whereArgs: [id]);
      } catch (_) {}
    });
  }

  @override
  Future<void> emptyTrash() async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'notes',
        columns: ['id'],
        where: 'deleted_at IS NOT NULL',
      );
      for (final row in rows) {
        final id = row['id'] as String;
        try {
          await txn.delete('notes_fts', where: 'note_id = ?', whereArgs: [id]);
        } catch (_) {}
      }
      await txn.delete('notes', where: 'deleted_at IS NOT NULL');
    });
  }

  @override
  Future<List<Note>> searchNotesFTS(
    String query, {
    String? folderId,
    String? tagId,
    NoteType? noteType,
    bool includeArchived = false,
  }) async {
    if (query.trim().isEmpty) {
      return getNotes(
        folderId: folderId,
        tagId: tagId,
        noteType: noteType,
        includeArchived: includeArchived,
      );
    }

    final db = await databaseHelper.database;
    final sanitized = query.trim().replaceAll('"', '""');
    List<String> matchedNoteIds = [];

    // 1. Try SQLite FTS5 query first
    try {
      final ftsQuery = '''
        SELECT note_id FROM notes_fts
        WHERE notes_fts MATCH ?
      ''';
      // Search with prefix wildcards
      final results = await db.rawQuery(ftsQuery, ['"$sanitized"*']);
      matchedNoteIds = results.map((e) => e['note_id'] as String).toList();
    } catch (_) {
      // Fallback to standard LIKE if FTS query syntax error
      final likePattern = '%$query%';
      final likeResults = await db.rawQuery(
        'SELECT id FROM notes WHERE title LIKE ? OR body_delta LIKE ?',
        [likePattern, likePattern],
      );
      matchedNoteIds = likeResults.map((e) => e['id'] as String).toList();
    }

    if (matchedNoteIds.isEmpty) {
      return [];
    }

    // 2. Fetch full notes with user constraints (excluding Trash and locked notes)
    final placeholders = List.filled(matchedNoteIds.length, '?').join(',');
    final whereArgs = <dynamic>[...matchedNoteIds];
    final whereClauses = <String>[
      'n.id IN ($placeholders)',
      'n.deleted_at IS NULL',
      'n.is_locked = 0', // Per PRD Section 22: locked notes excluded from unauthenticated FTS
    ];

    if (!includeArchived) {
      whereClauses.add('n.is_archived = 0');
    }

    if (folderId != null) {
      if (folderId.isEmpty) {
        whereClauses.add('n.folder_id IS NULL');
      } else {
        whereClauses.add('n.folder_id = ?');
        whereArgs.add(folderId);
      }
    }

    if (noteType != null) {
      whereClauses.add('n.note_type = ?');
      whereArgs.add(noteType.name.toLowerCase());
    }

    String sql;
    if (tagId != null) {
      sql = '''
        SELECT DISTINCT n.* FROM notes n
        INNER JOIN note_tags nt ON n.id = nt.note_id
        WHERE nt.tag_id = ? AND ${whereClauses.join(' AND ')}
        ORDER BY n.updated_at DESC
      ''';
      whereArgs.insert(0, tagId);
    } else {
      sql = '''
        SELECT n.* FROM notes n
        WHERE ${whereClauses.join(' AND ')}
        ORDER BY n.updated_at DESC
      ''';
    }

    final rows = await db.rawQuery(sql, whereArgs);
    final notes = <Note>[];
    for (final row in rows) {
      final noteId = row['id'] as String;
      final tags = await _getTagsForNote(db, noteId);
      notes.add(NoteModel.fromMap(row, tags));
    }
    return notes;
  }

  @override
  Future<void> togglePin(String id, bool isPinned) async {
    final db = await databaseHelper.database;
    await db.update(
      'notes',
      {
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await databaseHelper.database;
    await db.update(
      'notes',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> toggleArchive(String id, bool isArchived) async {
    final db = await databaseHelper.database;
    await db.update(
      'notes',
      {
        'is_archived': isArchived ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> createVersionSnapshot(String noteId, String title, String bodyDelta) async {
    final db = await databaseHelper.database;
    final version = NoteVersionModel(
      id: _uuid.v4(),
      noteId: noteId,
      titleSnapshot: title,
      bodyDeltaSnapshot: bodyDelta,
      createdAt: DateTime.now(),
    );
    await db.insert('note_versions', version.toMap());
  }

  @override
  Future<List<NoteVersion>> getVersionHistory(String noteId) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'note_versions',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'created_at DESC',
    );
    return results.map((e) => NoteVersionModel.fromMap(e)).toList();
  }

  @override
  Future<void> restoreVersion(String noteId, NoteVersion version) async {
    final current = await getNoteById(noteId);
    if (current != null) {
      // Create snapshot of current state before replacing
      await createVersionSnapshot(noteId, current.title, current.bodyDelta);

      final updated = current.copyWith(
        title: version.titleSnapshot,
        bodyDelta: version.bodyDeltaSnapshot,
        updatedAt: DateTime.now(),
        wordCount: TextUtils.countWords(version.bodyDeltaSnapshot),
        charCount: TextUtils.countCharacters(version.bodyDeltaSnapshot),
      );
      await updateNote(updated);
    }
  }

  @override
  Future<int> getTotalNotesCount() async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE deleted_at IS NULL AND is_archived = 0',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<int> getTrashNotesCount() async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE deleted_at IS NOT NULL',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<int> getArchivedNotesCount() async {
    final db = await databaseHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE deleted_at IS NULL AND is_archived = 1',
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<String>> _getTagsForNote(DatabaseExecutor db, String noteId) async {
    final rows = await db.query(
      'note_tags',
      columns: ['tag_id'],
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
    return rows.map((e) => e['tag_id'] as String).toList();
  }

  Future<void> _syncFTS(DatabaseExecutor txn, Note note) async {
    try {
      await txn.delete('notes_fts', where: 'note_id = ?', whereArgs: [note.id]);

      // If note is locked or in trash, do not index in plaintext FTS per PRD Section 22
      if (note.isLocked || note.isDeleted) return;

      final plainBody = TextUtils.stripMarkdown(note.bodyDelta);
      await txn.insert('notes_fts', {
        'note_id': note.id,
        'title': note.title,
        'plain_text_body': plainBody,
        'tag_names': '',
        'ocr_text': '',
      });
    } catch (_) {}
  }
}
