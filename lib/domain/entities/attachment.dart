class Attachment {
  final String id;
  final String noteId;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int sizeBytes;
  final String? ocrText;
  final bool isEncrypted;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.sizeBytes,
    this.ocrText,
    this.isEncrypted = false,
    required this.createdAt,
  });

  Attachment copyWith({
    String? id,
    String? noteId,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? sizeBytes,
    String? ocrText,
    bool? isEncrypted,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      ocrText: ocrText ?? this.ocrText,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
