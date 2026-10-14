class BackupManifest {
  final String appVersion;
  final DateTime exportedAt;
  final int noteCount;
  final int folderCount;
  final int tagCount;
  final int attachmentCount;
  final String checksum;

  const BackupManifest({
    required this.appVersion,
    required this.exportedAt,
    required this.noteCount,
    required this.folderCount,
    required this.tagCount,
    required this.attachmentCount,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'appVersion': appVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'noteCount': noteCount,
    'folderCount': folderCount,
    'tagCount': tagCount,
    'attachmentCount': attachmentCount,
    'checksum': checksum,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appVersion: json['appVersion'] as String? ?? '1.0.0',
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      noteCount: json['noteCount'] as int? ?? 0,
      folderCount: json['folderCount'] as int? ?? 0,
      tagCount: json['tagCount'] as int? ?? 0,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      checksum: json['checksum'] as String? ?? '',
    );
  }
}
