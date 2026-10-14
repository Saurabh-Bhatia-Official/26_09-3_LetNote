import 'package:uuid/uuid.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../datasources/database_helper.dart';
import '../models/tag_model.dart';

class TagRepositoryImpl implements TagRepository {
  final DatabaseHelper databaseHelper;
  final Uuid _uuid = const Uuid();

  TagRepositoryImpl({DatabaseHelper? dbHelper})
      : databaseHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<Tag>> getTags() async {
    final db = await databaseHelper.database;
    final results = await db.query('tags', orderBy: 'name ASC');
    return results.map((e) => TagModel.fromMap(e)).toList();
  }

  @override
  Future<Tag?> getTagById(String id) async {
    final db = await databaseHelper.database;
    final results = await db.query('tags', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isEmpty) return null;
    return TagModel.fromMap(results.first);
  }

  @override
  Future<Tag> getOrCreateTag(String name, {String? colorHex}) async {
    final cleanName = name.trim().replaceAll(RegExp(r'^#'), '');
    final db = await databaseHelper.database;

    final existing = await db.query(
      'tags',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [cleanName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return TagModel.fromMap(existing.first);
    }

    final newTag = Tag(
      id: _uuid.v4(),
      name: cleanName,
      colorHex: colorHex ?? '#10B981',
    );
    final model = TagModel.fromEntity(newTag);
    await db.insert('tags', model.toMap());
    return newTag;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final db = await databaseHelper.database;
    final model = TagModel.fromEntity(tag);
    await db.update('tags', model.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  @override
  Future<void> deleteTag(String id) async {
    final db = await databaseHelper.database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}
