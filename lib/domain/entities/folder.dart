class Folder {
  final String id;
  final String? userId;
  final String? parentFolderId;
  final String name;
  final bool isGroup;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Folder({
    required this.id,
    this.userId,
    this.parentFolderId,
    required this.name,
    this.isGroup = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Folder copyWith({
    String? id,
    String? userId,
    String? parentFolderId,
    String? name,
    bool? isGroup,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool setParentFolderIdNull = false,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      parentFolderId: setParentFolderIdNull ? null : (parentFolderId ?? this.parentFolderId),
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
