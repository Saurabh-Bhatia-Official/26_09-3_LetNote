import '../entities/tag.dart';

abstract class TagRepository {
  Future<List<Tag>> getTags();
  Future<Tag?> getTagById(String id);
  Future<Tag> getOrCreateTag(String name, {String? colorHex});
  Future<void> updateTag(Tag tag);
  Future<void> deleteTag(String id);
}
