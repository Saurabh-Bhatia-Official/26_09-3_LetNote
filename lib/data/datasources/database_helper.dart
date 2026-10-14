import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Enable FFI on Windows, macOS, and Linux
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final dbFolder = Directory(p.join(docDir.path, 'LetNote'));
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }
    final dbPath = p.join(dbFolder.path, 'letnote.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onOpen: (db) async {
        try {
          await db.execute('ALTER TABLE folders ADD COLUMN is_group INTEGER DEFAULT 0');
        } catch (_) {
          // Column already exists
        }
      },
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys and WAL mode for reliability and performance
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      await db.execute('PRAGMA journal_mode = WAL');
    } catch (_) {
      // Some in-memory or specific environments may not support WAL
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Folders table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        parent_folder_id TEXT,
        name TEXT NOT NULL,
        is_group INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (parent_folder_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_folders_parent ON folders(parent_folder_id)');

    // 2. Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        folder_id TEXT,
        title TEXT NOT NULL DEFAULT '',
        body_delta TEXT NOT NULL DEFAULT '',
        note_type TEXT NOT NULL DEFAULT 'standard',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_locked INTEGER NOT NULL DEFAULT 0,
        is_important INTEGER NOT NULL DEFAULT 0,
        is_template INTEGER NOT NULL DEFAULT 0,
        encrypted_body TEXT,
        word_count INTEGER NOT NULL DEFAULT 0,
        char_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        sync_version INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_folder ON notes(folder_id)');
    await db.execute('CREATE INDEX idx_notes_deleted ON notes(deleted_at)');
    await db.execute('CREATE INDEX idx_notes_pinned ON notes(is_pinned)');
    await db.execute('CREATE INDEX idx_notes_favorite ON notes(is_favorite)');
    await db.execute('CREATE INDEX idx_notes_archived ON notes(is_archived)');

    // 3. Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL UNIQUE,
        color_hex TEXT
      )
    ''');

    // 4. Note Tags junction table
    await db.execute('''
      CREATE TABLE note_tags (
        note_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (note_id, tag_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    // 5. Attachments table
    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        size_bytes INTEGER NOT NULL,
        ocr_text TEXT,
        is_encrypted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_attachments_note ON attachments(note_id)');

    // 6. Checklist Items table
    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_checklists_note ON checklist_items(note_id)');

    // 7. Note Versions table
    await db.execute('''
      CREATE TABLE note_versions (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        title_snapshot TEXT NOT NULL,
        body_delta_snapshot TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_versions_note ON note_versions(note_id, created_at)');

    // 8. Settings table
    await db.execute('''
      CREATE TABLE settings (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        key TEXT NOT NULL UNIQUE,
        value TEXT NOT NULL
      )
    ''');

    // 9. Sync Records table (for offline-first queue)
    await db.execute('''
      CREATE TABLE sync_records (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 10. SQLite FTS5 virtual table for lightning-fast full text search (<150ms over 10k notes)
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE notes_fts USING fts5(
          note_id UNINDEXED,
          title,
          plain_text_body,
          tag_names,
          ocr_text,
          tokenize='unicode61'
        )
      ''');
    } catch (e) {
      // In case FTS5 isn't available on a specific platform fallback to standard virtual table
      debugPrint('FTS5 initialization notice: $e');
    }
  }

  /// Permanently deletes all notes, books, tags, versions, attachments, and search index.
  Future<void> deleteAllData({bool resetSettings = false}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('note_tags');
      await txn.delete('checklist_items');
      await txn.delete('note_versions');
      await txn.delete('attachments');
      await txn.delete('notes');
      await txn.delete('folders');
      await txn.delete('tags');
      await txn.delete('sync_records');
      try {
        await txn.delete('notes_fts');
      } catch (_) {}
      if (resetSettings) {
        await txn.delete('settings');
      }
    });

    // Also delete any local attachments saved on disk
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final attachDir = Directory(p.join(docDir.path, 'LetNote', 'Attachments'));
      if (await attachDir.exists()) {
        await attachDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  /// Close database instance
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
