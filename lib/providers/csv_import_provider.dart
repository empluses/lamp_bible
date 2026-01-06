import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bible_reading.dart';
import '../models/bible_book.dart';
import '../services/database_helper.dart';
import '../services/csv_download_service.dart';

class CsvImportProvider extends ChangeNotifier {
  bool _isImporting = false;
  String? _lastError;
  int _importedCount = 0;
  bool _isDownloading = false;

  bool get isImporting => _isImporting;
  String? get lastError => _lastError;
  int get importedCount => _importedCount;
  bool get isDownloading => _isDownloading;

  Future<bool> importReadingsAuto() async {
    _isDownloading = true;
    notifyListeners();

    final file = await CsvDownloadService.getDailyReadingsCsv();

    _isDownloading = false;
    notifyListeners();

    if (file != null) {
      return await importReadingsFromCsv(file);
    } else {
      _lastError = 'CSV 파일을 가져올 수 없습니다';
      notifyListeners();
      return false;
    }
  }

  Future<bool> importBooksAuto() async {
    _isDownloading = true;
    notifyListeners();

    final file = await CsvDownloadService.getBibleBooksCsv();

    _isDownloading = false;
    notifyListeners();

    if (file != null) {
      return await importBooksFromCsv(file);
    } else {
      _lastError = 'CSV 파일을 가져올 수 없습니다';
      notifyListeners();
      return false;
    }
  }

  Future<bool> importReadingsFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return false;

      final file = File(result.files.single.path!);
      return await importReadingsFromCsv(file);
    } catch (e) {
      _lastError = '파일 선택 실패: $e';
      notifyListeners();
      return false;
    }
  }

  // CSV 파일을 여러 인코딩으로 시도해서 읽기
  Future<String?> _readCsvFile(File file) async {
    // 시도할 인코딩 목록
    final encodings = [
      utf8, // UTF-8
      latin1, // Latin-1 (ISO-8859-1)
      systemEncoding, // 시스템 기본 인코딩
    ];

    for (var encoding in encodings) {
      try {
        final bytes = await file.readAsBytes();

        // BOM 제거 (UTF-8 BOM: EF BB BF)
        var startIndex = 0;
        if (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF) {
          startIndex = 3;
        }

        final content = encoding.decode(bytes.sublist(startIndex));

        // 디코딩이 성공하고 내용이 있으면 반환
        if (content.isNotEmpty) {
          debugPrint('Successfully decoded with ${encoding.name}');
          return content;
        }
      } catch (e) {
        debugPrint('Failed to decode with ${encoding.name}: $e');
        continue;
      }
    }

    return null;
  }

  Future<bool> importReadingsFromCsv(File file) async {
    _isImporting = true;
    _lastError = null;
    _importedCount = 0;
    notifyListeners();

    try {
      final input = await _readCsvFile(file);

      if (input == null) {
        throw Exception('파일을 읽을 수 없습니다. 파일 인코딩을 확인해주세요.');
      }

      final List<List<dynamic>> rows = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        shouldParseNumbers: false,
      ).convert(input);

      if (rows.isEmpty) {
        throw Exception('CSV 파일이 비어있습니다');
      }

      // 헤더 확인 (대소문자 구분 없이)
      final headers =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      debugPrint('CSV Headers: $headers');

      if (!headers.contains('month') ||
          !headers.contains('day') ||
          !headers.contains('youtube_url')) {
        throw Exception(
            'CSV 형식이 올바르지 않습니다.\n필요한 컬럼: month, day, youtube_url\n현재 헤더: $headers');
      }

      // 헤더 인덱스 찾기
      final monthIdx = headers.indexOf('month');
      final dayIdx = headers.indexOf('day');
      final urlIdx = headers.indexOf('youtube_url');
      final titleIdx = headers.indexOf('title');
      final chapterIdx = headers.indexOf('chapter_info');
      final specialIdx = headers.indexOf('is_special');

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];

          // 빈 행 건너뛰기
          if (row.isEmpty ||
              row.every((cell) => cell.toString().trim().isEmpty)) {
            continue;
          }

          try {
            final reading = BibleReading(
              month: int.parse(row[monthIdx].toString().trim()),
              day: int.parse(row[dayIdx].toString().trim()),
              youtubeUrl: row[urlIdx].toString().trim(),
              title: titleIdx >= 0 && row.length > titleIdx
                  ? row[titleIdx].toString().trim()
                  : '',
              chapterInfo: chapterIdx >= 0 && row.length > chapterIdx
                  ? row[chapterIdx].toString().trim()
                  : null,
              isSpecial: specialIdx >= 0 && row.length > specialIdx
                  ? row[specialIdx].toString().trim() == '1'
                  : false,
            );

            await txn.insert(
              'bible_readings',
              reading.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _importedCount++;
          } catch (e) {
            debugPrint('Error parsing row $i: $e');
            debugPrint('Row data: $row');
          }
        }
      });

      _isImporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'CSV 가져오기 실패: $e';
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> importBooksFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return false;

      final file = File(result.files.single.path!);
      return await importBooksFromCsv(file);
    } catch (e) {
      _lastError = '파일 선택 실패: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> importBooksFromCsv(File file) async {
    _isImporting = true;
    _lastError = null;
    _importedCount = 0;
    notifyListeners();

    try {
      final input = await _readCsvFile(file);

      if (input == null) {
        throw Exception('파일을 읽을 수 없습니다. 파일 인코딩을 확인해주세요.');
      }

      final List<List<dynamic>> rows = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        shouldParseNumbers: false,
      ).convert(input);

      if (rows.isEmpty) {
        throw Exception('CSV 파일이 비어있습니다');
      }

      // 헤더 확인
      final headers =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      debugPrint('CSV Headers: $headers');

      // 헤더 인덱스 찾기
      final bookNumIdx = headers.indexOf('book_number');
      final testamentIdx = headers.indexOf('testament');
      final koreanNameIdx = headers.indexOf('korean_name');
      final englishNameIdx = headers.indexOf('english_name');
      final urlIdx = headers.indexOf('youtube_url');
      final authorIdx = headers.indexOf('author');
      final chaptersIdx = headers.indexOf('chapters_count');
      final summaryIdx = headers.indexOf('summary');

      if (bookNumIdx < 0 ||
          testamentIdx < 0 ||
          koreanNameIdx < 0 ||
          urlIdx < 0) {
        throw Exception(
            'CSV 형식이 올바르지 않습니다.\n필요한 컬럼: book_number, testament, korean_name, youtube_url');
      }

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];

          // 빈 행 건너뛰기
          if (row.isEmpty ||
              row.every((cell) => cell.toString().trim().isEmpty)) {
            continue;
          }

          try {
            final book = BibleBook(
              bookNumber: int.parse(row[bookNumIdx].toString().trim()),
              testament: row[testamentIdx].toString().trim(),
              koreanName: row[koreanNameIdx].toString().trim(),
              englishName: englishNameIdx >= 0 && row.length > englishNameIdx
                  ? row[englishNameIdx].toString().trim()
                  : '',
              youtubeUrl: row[urlIdx].toString().trim(),
              author: authorIdx >= 0 && row.length > authorIdx
                  ? row[authorIdx].toString().trim()
                  : null,
              chaptersCount: chaptersIdx >= 0 && row.length > chaptersIdx
                  ? int.parse(row[chaptersIdx].toString().trim())
                  : 0,
              summary: summaryIdx >= 0 && row.length > summaryIdx
                  ? row[summaryIdx].toString().trim()
                  : null,
            );

            await txn.insert(
              'bible_books',
              book.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            _importedCount++;
          } catch (e) {
            debugPrint('Error parsing row $i: $e');
            debugPrint('Row data: $row');
          }
        }
      });

      _isImporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'CSV 가져오기 실패: $e';
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }
}
