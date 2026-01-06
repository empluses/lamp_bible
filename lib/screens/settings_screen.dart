import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/csv_import_provider.dart';
import '../providers/bible_reading_provider.dart';
import '../providers/bible_books_provider.dart';
import '../providers/reading_history_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showYearPicker(BuildContext context) async {
    final historyProvider = context.read<ReadingHistoryProvider>();
    final currentYear = historyProvider.currentYear;

    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('년도 선택'),
          children: List.generate(10, (index) {
            final year = DateTime.now().year - 5 + index;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, year),
              child: Text(
                '$year년',
                style: TextStyle(
                  fontWeight:
                      year == currentYear ? FontWeight.bold : FontWeight.normal,
                  color: year == currentYear ? Colors.blue : null,
                ),
              ),
            );
          }),
        );
      },
    );

    if (selectedYear != null && selectedYear != currentYear) {
      await historyProvider.setYear(selectedYear);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$selectedYear년으로 변경되었습니다')),
        );
      }
    }
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();

    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('테마 선택'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.brightness_auto,
                    color: themeProvider.themeMode == ThemeMode.system
                        ? Colors.blue
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '시스템 기본값',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.system
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    color: themeProvider.themeMode == ThemeMode.light
                        ? Colors.blue
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '라이트 모드',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.light
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.blue
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '다크 모드',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.dark
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 기본값';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '📥 데이터 업데이트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // 매일 읽기 URL 가져오기 (자동)
          Consumer2<CsvImportProvider, BibleReadingProvider>(
            builder: (context, csvProvider, readingProvider, child) {
              return ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.blue),
                title: const Text('매일 읽기 URL (자동)'),
                subtitle: const Text('URL 다운로드 또는 로컬 파일'),
                trailing: csvProvider.isDownloading || csvProvider.isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onTap: csvProvider.isDownloading || csvProvider.isImporting
                    ? null
                    : () async {
                        final success = await csvProvider.importReadingsAuto();
                        if (context.mounted) {
                          if (success) {
                            await readingProvider.loadAllReadings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${csvProvider.importedCount}개 항목이 가져와졌습니다',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  csvProvider.lastError ?? '가져오기 실패',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              );
            },
          ),

          // 매일 읽기 URL 가져오기 (수동)
          Consumer2<CsvImportProvider, BibleReadingProvider>(
            builder: (context, csvProvider, readingProvider, child) {
              return ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.blue),
                title: const Text('매일 읽기 URL (수동)'),
                subtitle: const Text('파일 선택'),
                trailing: csvProvider.isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open),
                onTap: csvProvider.isImporting
                    ? null
                    : () async {
                        final success =
                            await csvProvider.importReadingsFromFile();
                        if (context.mounted) {
                          if (success) {
                            await readingProvider.loadAllReadings();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${csvProvider.importedCount}개 항목이 가져와졌습니다',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  csvProvider.lastError ?? '가져오기 실패',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              );
            },
          ),

          // 성경 개요 URL 가져오기 (자동)
          Consumer2<CsvImportProvider, BibleBooksProvider>(
            builder: (context, csvProvider, booksProvider, child) {
              return ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.green),
                title: const Text('성경 개요 URL (자동)'),
                subtitle: const Text('URL 다운로드 또는 로컬 파일'),
                trailing: csvProvider.isDownloading || csvProvider.isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                onTap: csvProvider.isDownloading || csvProvider.isImporting
                    ? null
                    : () async {
                        final success = await csvProvider.importBooksAuto();
                        if (context.mounted) {
                          if (success) {
                            await booksProvider.loadAllBooks();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${csvProvider.importedCount}개 항목이 가져와졌습니다',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  csvProvider.lastError ?? '가져오기 실패',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              );
            },
          ),

          // 성경 개요 URL 가져오기 (수동)
          Consumer2<CsvImportProvider, BibleBooksProvider>(
            builder: (context, csvProvider, booksProvider, child) {
              return ListTile(
                leading: const Icon(Icons.folder_open, color: Colors.green),
                title: const Text('성경 개요 URL (수동)'),
                subtitle: const Text('파일 선택'),
                trailing: csvProvider.isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_open),
                onTap: csvProvider.isImporting
                    ? null
                    : () async {
                        final success = await csvProvider.importBooksFromFile();
                        if (context.mounted) {
                          if (success) {
                            await booksProvider.loadAllBooks();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${csvProvider.importedCount}개 항목이 가져와졌습니다',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  csvProvider.lastError ?? '가져오기 실패',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
              );
            },
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '🎨 테마 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: const Icon(Icons.palette, color: Colors.purple),
                title: const Text('테마 모드'),
                subtitle: Text(_getThemeModeText(themeProvider.themeMode)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showThemeDialog(context),
              );
            },
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '🗓️ 년도 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          Consumer<ReadingHistoryProvider>(
            builder: (context, provider, child) {
              return ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.orange),
                title: const Text('현재 년도'),
                subtitle: Text('${provider.currentYear}년'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _showYearPicker(context),
              );
            },
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '📊 통계',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          Consumer<ReadingHistoryProvider>(
            builder: (context, provider, child) {
              final year = provider.currentYear;
              final completed = provider.getCompletedCount(year);
              final progress = provider.getProgressPercentage(year);

              return ListTile(
                leading: const Icon(Icons.show_chart, color: Colors.purple),
                title: const Text('연간 완독률'),
                subtitle:
                    Text('$completed일 완료 / ${progress.toStringAsFixed(1)}%'),
                trailing: Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          const Divider(height: 32),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ℹ️ 앱 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          const ListTile(
            leading: Icon(Icons.info, color: Colors.blue),
            title: Text('버전'),
            subtitle: Text('1.0.0'),
          ),

          ListTile(
            leading: const Icon(Icons.description, color: Colors.green),
            title: const Text('CSV 형식 안내'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('CSV 파일 형식'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '매일 읽기 CSV:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'month,day,youtube_url,title,chapter_info,is_special',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '성경 66권 CSV:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'book_number,testament,korean_name,english_name,youtube_url,author,chapters_count,summary',
                          style:
                              TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
