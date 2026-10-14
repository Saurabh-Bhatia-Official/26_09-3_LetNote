import '../../domain/entities/checklist_item.dart';

class ChecklistItemModel extends ChecklistItem {
  const ChecklistItemModel({
    required super.id,
    required super.noteId,
    required super.content,
    super.isChecked,
    super.sortOrder,
  });

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      id: map['id'] as String,
      noteId: map['note_id'] as String,
      content: map['content'] as String,
      isChecked: (map['is_checked'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'content': content,
      'is_checked': isChecked ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory ChecklistItemModel.fromEntity(ChecklistItem item) {
    return ChecklistItemModel(
      id: item.id,
      noteId: item.noteId,
      content: item.content,
      isChecked: item.isChecked,
      sortOrder: item.sortOrder,
    );
  }
}
