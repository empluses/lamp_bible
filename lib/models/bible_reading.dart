class BibleReading {
  final int? id;
  final int month;
  final int day;
  final String youtubeUrl;
  final String title;
  final String? chapterInfo;
  final bool isSpecial;

  BibleReading({
    this.id,
    required this.month,
    required this.day,
    required this.youtubeUrl,
    required this.title,
    this.chapterInfo,
    this.isSpecial = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'day': day,
      'youtube_url': youtubeUrl,
      'title': title,
      'chapter_info': chapterInfo,
      'is_special': isSpecial ? 1 : 0,
    };
  }

  factory BibleReading.fromMap(Map<String, dynamic> map) {
    return BibleReading(
      id: map['id'],
      month: map['month'],
      day: map['day'],
      youtubeUrl: map['youtube_url'],
      title: map['title'],
      chapterInfo: map['chapter_info'],
      isSpecial: map['is_special'] == 1,
    );
  }

  bool isAvailableForYear(int year) {
    if (month == 2 && day == 29) {
      return _isLeapYear(year);
    }
    return true;
  }

  bool _isLeapYear(int year) {
    if (year % 400 == 0) return true;
    if (year % 100 == 0) return false;
    if (year % 4 == 0) return true;
    return false;
  }
}
