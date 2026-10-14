import '../../domain/entities/attachment.dart';

class AttachmentModel extends Attachment {
  const AttachmentModel({
    required super.id,
    required super.noteId,
    required super.fileName,
    required super.filePath,
    required super.mimeType,
    required super.sizeBytes,
    super.ocrText,
    super.isEncrypted,
    required super.createdAt,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      mimeType: map['mime_type'] as String,
      sizeBytes: map['size_bytes'] as int,
      ocrText: map['ocr_text'] as String?,
      isEncrypted: (map['is_encrypted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'ocr_text': ocrText,
      'is_encrypted': isEncrypted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AttachmentModel.fromEntity(Attachment attachment) {
    return AttachmentModel(
      id: attachment.id,
      noteId: attachment.noteId,
      fileName: attachment.fileName,
      filePath: attachment.filePath,
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
      ocrText: attachment.ocrText,
      isEncrypted: attachment.isEncrypted,
      createdAt: attachment.createdAt,
    );
  }
}
