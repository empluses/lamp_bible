class BookNote {
  final int? id;
  final int bookId;
  final String noteContent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookNote({
    this.id,
    required this.bookId,
    required this.noteContent,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'note_content': noteContent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BookNote.fromMap(Map<String, dynamic> map) {
    return BookNote(
      id: map['id'],
      bookId: map['book_id'],
      noteContent: map['note_content'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
