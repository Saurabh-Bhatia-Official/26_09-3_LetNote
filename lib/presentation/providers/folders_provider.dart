import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../data/repositories/folder_repository_impl.dart';

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl();
});

class FoldersNotifier extends AsyncNotifier<List<Folder>> {
  final _uuid = const Uuid();

  @override
  Future<List<Folder>> build() async {
    final repo = ref.read(folderRepositoryProvider);
    return await repo.getFolders();
  }

  Future<Folder> createBookGroup(String name) async {
    final repo = ref.read(folderRepositoryProvider);
    final now = DateTime.now();
    final group = Folder(
      id: _uuid.v4(),
      name: name.trim(),
      isGroup: true,
      parentFolderId: null,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createFolder(group);
    ref.invalidateSelf();
    return group;
  }

  Future<Folder> createBook(String name, {String? groupId}) async {
    final repo = ref.read(folderRepositoryProvider);
    final now = DateTime.now();
    final book = Folder(
      id: _uuid.v4(),
      name: name.trim(),
      isGroup: false,
      parentFolderId: groupId,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createFolder(book);
    ref.invalidateSelf();
    return book;
  }

  Future<void> createFolder(String name, {String? parentFolderId, bool isGroup = false}) async {
    final repo = ref.read(folderRepositoryProvider);
    final now = DateTime.now();
    final folder = Folder(
      id: _uuid.v4(),
      name: name.trim(),
      isGroup: isGroup,
      parentFolderId: parentFolderId,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createFolder(folder);
    ref.invalidateSelf();
  }

  Future<void> moveBookToGroup(String bookId, String? targetGroupId) async {
    final repo = ref.read(folderRepositoryProvider);
    final existing = await repo.getFolderById(bookId);
    if (existing != null) {
      final updated = existing.copyWith(
        parentFolderId: targetGroupId,
        setParentFolderIdNull: targetGroupId == null,
        updatedAt: DateTime.now(),
      );
      await repo.updateFolder(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    final repo = ref.read(folderRepositoryProvider);
    final existing = await repo.getFolderById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        name: newName.trim(),
        updatedAt: DateTime.now(),
      );
      await repo.updateFolder(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> deleteFolder(String id) async {
    final repo = ref.read(folderRepositoryProvider);
    // Unparent any child books so their notes aren't lost
    final all = await repo.getFolders();
    final children = all.where((f) => f.parentFolderId == id).toList();
    for (final child in children) {
      await repo.updateFolder(child.copyWith(setParentFolderIdNull: true));
    }
    await repo.deleteFolder(id);
    ref.invalidateSelf();
  }
}

final foldersNotifierProvider = AsyncNotifierProvider<FoldersNotifier, List<Folder>>(FoldersNotifier.new);
