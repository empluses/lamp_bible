import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bible_reading.dart';
import '../models/bible_book.dart';
import '../services/database_helper.dart';

class BibleBooksProvider extends ChangeNotifier {
  List<BibleBook> _books = [];
  bool _isLoading = false;

  List<BibleBook> get books => _books;
  bool get isLoading => _isLoading;

  List<BibleBook> get oldTestamentBooks =>
      _books.where((b) => b.testament == 'OLD').toList();

  List<BibleBook> get newTestamentBooks =>
      _books.where((b) => b.testament == 'NEW').toList();

  Future<void> loadAllBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('bible_books', orderBy: 'book_number');
      _books = maps.map((map) => BibleBook.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading books: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  BibleBook? getBookByNumber(int bookNumber) {
    try {
      return _books.firstWhere((b) => b.bookNumber == bookNumber);
    } catch (e) {
      return null;
    }
  }

  BibleBook? getBookById(int id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  List<BibleBook> searchBooks(String keyword) {
    if (keyword.isEmpty) return _books;

    final lower = keyword.toLowerCase();
    return _books.where((b) {
      return b.koreanName.toLowerCase().contains(lower) ||
          (b.englishName?.toLowerCase().contains(lower) ?? false) ||
          (b.author?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  Future<void> insertBook(BibleBook book) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'bible_books',
        book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadAllBooks();
    } catch (e) {
      debugPrint('Error inserting book: $e');
    }
  }

  Future<void> deleteAllBooks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('bible_books');
      await loadAllBooks();
    } catch (e) {
      debugPrint('Error deleting books: $e');
    }
  }
}
