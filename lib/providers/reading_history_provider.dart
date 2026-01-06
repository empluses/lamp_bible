import 'package:flutter/foundation.dart';
import '../models/reading_history.dart';
import '../services/database_helper.dart';
import '../services/date_helper.dart';

class ReadingHistoryProvider extends ChangeNotifier {
  Map<String, ReadingHistory> _history = {};
  int _currentYear = DateTime.now().year;
  bool _isLoading = false;

  Map<String, ReadingHistory> get history => _history;
  int get currentYear => _currentYear;
  bool get isLoading => _isLoading;

  String _getKey(int year, int month, int day) {
    return '$year-$month-$day';
  }

  Future<void> setYear(int year) async {
    _currentYear = year;
    await loadHistoryForYear(year);
  }

  Future<void> loadHistoryForYear(int year) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'reading_history',
        where: 'year = ?',
        whereArgs: [year],
      );

      _history.clear();
      for (var map in maps) {
        final h = ReadingHistory.fromMap(map);
        _history[_getKey(h.year, h.month, h.day)] = h;
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isCompleted(int year, int month, int day) {
    final key = _getKey(year, month, day);
    return _history[key]?.isCompleted ?? false;
  }

  Future<void> markAsCompleted(
      int year, int month, int day, bool completed) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final key = _getKey(year, month, day);

      if (_history.containsKey(key)) {
        await db.update(
          'reading_history',
          {
            'is_completed': completed ? 1 : 0,
            'completed_at': completed ? DateTime.now().toIso8601String() : null,
          },
          where: 'year = ? AND month = ? AND day = ?',
          whereArgs: [year, month, day],
        );
      } else {
        await db.insert(
          'reading_history',
          {
            'year': year,
            'month': month,
            'day': day,
            'is_completed': completed ? 1 : 0,
            'completed_at': completed ? DateTime.now().toIso8601String() : null,
          },
        );
      }

      await loadHistoryForYear(year);
    } catch (e) {
      debugPrint('Error marking as completed: $e');
    }
  }

  int getCompletedCount(int year) {
    return _history.values.where((h) => h.year == year && h.isCompleted).length;
  }

  int getUncompletedCount(int year) {
    final total = DateHelper.getTotalDaysInYear(year);
    final today = DateTime.now();

    if (year > today.year) return 0;

    int targetDays = total;
    if (year == today.year) {
      targetDays = today.difference(DateTime(year, 1, 1)).inDays + 1;
    }

    return targetDays - getCompletedCount(year);
  }

  int getStreakDays(int year) {
    final today = DateTime.now();
    if (year != today.year) return 0;

    int streak = 0;
    DateTime current = today;

    while (true) {
      if (!isCompleted(current.year, current.month, current.day)) {
        break;
      }
      streak++;
      current = current.subtract(const Duration(days: 1));
      if (current.year != year) break;
    }

    return streak;
  }

  double getProgressPercentage(int year) {
    final total = DateHelper.getTotalDaysInYear(year);
    final completed = getCompletedCount(year);
    return (completed / total) * 100;
  }
}
