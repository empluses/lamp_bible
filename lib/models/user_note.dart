class UserNote {
  final int? id;
  final int year;
  final int month;
  final int day;
  final String? verseReference;
  final String noteContent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserNote({
    this.id,
    required this.year,
    required this.month,
    required this.day,
    this.verseReference,
    required this.noteContent,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'day': day,
      'verse_reference': verseReference,
      'note_content': noteContent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserNote.fromMap(Map<String, dynamic> map) {
    return UserNote(
      id: map['id'],
      year: map['year'],
      month: map['month'],
      day: map['day'],
      verseReference: map['verse_reference'],
      noteContent: map['note_content'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
