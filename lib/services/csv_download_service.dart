import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CsvDownloadService {
  static const String baseUrl = 'https://lamp.empluses.com/csv/';
  static const String dailyReadingFileName = 'daily_readings.csv';
  static const String bibleBooksFileName = 'bible_books.csv';

  // 매일 읽기 CSV 다운로드 또는 로컬에서 가져오기
  static Future<File?> getDailyReadingsCsv() async {
    return await _downloadOrGetLocal(
        dailyReadingFileName, 'assets/csv/daily_readings.csv');
  }

  // 성경 66권 CSV 다운로드 또는 로컬에서 가져오기
  static Future<File?> getBibleBooksCsv() async {
    return await _downloadOrGetLocal(
        bibleBooksFileName, 'assets/csv/bible_books.csv');
  }

  static Future<File?> _downloadOrGetLocal(
      String fileName, String assetPath) async {
    try {
      // 1. 먼저 URL에서 다운로드 시도
      final url = '$baseUrl$fileName';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        // 다운로드 성공 - 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('Download failed, trying local asset: $e');
    }

    // 2. 다운로드 실패 시 로컬 assets에서 가져오기
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      print('Failed to load local asset: $e');
      return null;
    }
  }

  // CSV가 URL에서 사용 가능한지 확인
  static Future<bool> isAvailableOnline(String fileName) async {
    try {
      final url = '$baseUrl$fileName';
      final response = await http.head(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
