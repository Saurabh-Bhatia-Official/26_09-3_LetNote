class ChecklistItem {
  final String id;
  final String noteId;
  final String content;
  final bool isChecked;
  final int sortOrder;

  const ChecklistItem({
    required this.id,
    required this.noteId,
    required this.content,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  ChecklistItem copyWith({
    String? id,
    String? noteId,
    String? content,
    bool? isChecked,
    int? sortOrder,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      content: content ?? this.content,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
