class ReadingHistory {
  final int? id;
  final int year;
  final int month;
  final int day;
  final bool isCompleted;
  final DateTime? completedAt;

  ReadingHistory({
    this.id,
    required this.year,
    required this.month,
    required this.day,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'day': day,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'],
      year: map['year'],
      month: map['month'],
      day: map['day'],
      isCompleted: map['is_completed'] == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
    );
  }
}
