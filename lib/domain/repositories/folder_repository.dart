import '../entities/folder.dart';

abstract class FolderRepository {
  Future<List<Folder>> getFolders({String? parentFolderId});
  Future<Folder?> getFolderById(String id);
  Future<void> createFolder(Folder folder);
  Future<void> updateFolder(Folder folder);
  Future<void> deleteFolder(String id);
}
