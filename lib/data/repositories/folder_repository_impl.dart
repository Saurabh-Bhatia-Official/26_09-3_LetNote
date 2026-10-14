import 'package:sqflite/sqflite.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/database_helper.dart';
import '../models/folder_model.dart';

class FolderRepositoryImpl implements FolderRepository {
  final DatabaseHelper databaseHelper;

  FolderRepositoryImpl({DatabaseHelper? dbHelper})
      : databaseHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Folder>> getFolders({String? parentFolderId}) async {
    final db = await databaseHelper.database;
    List<Map<String, dynamic>> results;

    if (parentFolderId != null) {
      if (parentFolderId.isEmpty) {
        results = await db.query(
          'folders',
          where: 'parent_folder_id IS NULL',
          orderBy: 'sort_order ASC, name ASC',
        );
      } else {
        results = await db.query(
          'folders',
          where: 'parent_folder_id = ?',
          whereArgs: [parentFolderId],
          orderBy: 'sort_order ASC, name ASC',
        );
      }
    } else {
      results = await db.query('folders', orderBy: 'sort_order ASC, name ASC');
    }

    return results.map((e) => FolderModel.fromMap(e)).toList();
  }

  @override
  Future<Folder?> getFolderById(String id) async {
    final db = await databaseHelper.database;
    final results = await db.query('folders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return FolderModel.fromMap(results.first);
  }

  @override
  Future<void> createFolder(Folder folder) async {
    final db = await databaseHelper.database;
    final model = FolderModel.fromEntity(folder);
    await db.insert('folders', model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateFolder(Folder folder) async {
    final db = await databaseHelper.database;
    final model = FolderModel.fromEntity(folder);
    await db.update('folders', model.toMap(), where: 'id = ?', whereArgs: [folder.id]);
  }

  @override
  Future<void> deleteFolder(String id) async {
    final db = await databaseHelper.database;
    await db.transaction((txn) async {
      // Notes in this folder become uncategorized (folder_id = null)
      await txn.update('notes', {'folder_id': null}, where: 'folder_id = ?', whereArgs: [id]);
      await txn.delete('folders', where: 'id = ?', whereArgs: [id]);
    });
  }
}
