class BibleBook {
  final int? id;
  final int bookNumber;
  final String testament;
  final String koreanName;
  final String englishName;
  final String youtubeUrl;
  final String? author;
  final int chaptersCount;
  final String? summary;

  BibleBook({
    this.id,
    required this.bookNumber,
    required this.testament,
    required this.koreanName,
    required this.englishName,
    required this.youtubeUrl,
    this.author,
    required this.chaptersCount,
    this.summary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_number': bookNumber,
      'testament': testament,
      'korean_name': koreanName,
      'english_name': englishName,
      'youtube_url': youtubeUrl,
      'author': author,
      'chapters_count': chaptersCount,
      'summary': summary,
    };
  }

  factory BibleBook.fromMap(Map<String, dynamic> map) {
    return BibleBook(
      id: map['id'],
      bookNumber: map['book_number'],
      testament: map['testament'],
      koreanName: map['korean_name'],
      englishName: map['english_name'],
      youtubeUrl: map['youtube_url'],
      author: map['author'],
      chaptersCount: map['chapters_count'],
      summary: map['summary'],
    );
  }
}
