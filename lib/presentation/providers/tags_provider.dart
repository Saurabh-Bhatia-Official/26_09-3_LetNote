import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../data/repositories/tag_repository_impl.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepositoryImpl();
});

class TagsNotifier extends AsyncNotifier<List<Tag>> {
  @override
  Future<List<Tag>> build() async {
    final repo = ref.read(tagRepositoryProvider);
    return await repo.getTags();
  }

  Future<Tag> addTag(String name, {String? colorHex}) async {
    final repo = ref.read(tagRepositoryProvider);
    final tag = await repo.getOrCreateTag(name, colorHex: colorHex);
    ref.invalidateSelf();
    return tag;
  }

  Future<void> deleteTag(String id) async {
    final repo = ref.read(tagRepositoryProvider);
    await repo.deleteTag(id);
    ref.invalidateSelf();
  }
}

final tagsNotifierProvider = AsyncNotifierProvider<TagsNotifier, List<Tag>>(TagsNotifier.new);
