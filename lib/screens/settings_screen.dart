import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/csv_import_provider.dart';
import '../providers/bible_reading_provider.dart';
import '../providers/bible_books_provider.dart';
import '../providers/reading_history_provider.dart';
import '../providers/theme_provider.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showYearPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final historyProvider = context.read<ReadingHistoryProvider>();
    final currentYear = historyProvider.currentYear;

    final selectedYear = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.selectYear),
          children: List.generate(10, (index) {
            final year = DateTime.now().year - 5 + index;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, year),
              child: Text(
                '${l10n.year(year)}',
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
          SnackBar(content: Text(l10n.yearChanged(selectedYear))),
        );
      }
    }
  }

  Future<void> _showThemeDialog(BuildContext context) async {
    final themeProvider = context.read<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.themeMode),
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
                    l10n.systemTheme,
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
                    l10n.lightTheme,
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
                    l10n.darkTheme,
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

  Future<void> _showResetConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(l10n.reset),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onConfirm();
    }
  }

  Future<void> _resetAllData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    _showResetConfirmDialog(
      context,
      l10n.resetAllDataTitle,
      l10n.resetAllDataMessage,
      () async {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.delete('bible_readings');
          await db.delete('bible_books');
          await db.delete('reading_history');
          await db.delete('user_notes');
          await db.delete('book_notes');

          if (context.mounted) {
            // 모든 provider 새로고침
            await context.read<BibleReadingProvider>().loadAllReadings();
            await context.read<BibleBooksProvider>().loadAllBooks();
            await context.read<ReadingHistoryProvider>().loadHistoryForYear(
                  DateTime.now().year,
                );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(l10n.resetAllDataSuccess),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.resetAllDataFailed(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _resetReadingHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    _showResetConfirmDialog(
      context,
      l10n.resetReadingHistoryTitle,
      l10n.resetReadingHistoryMessage,
      () async {
        try {
          final db = await DatabaseHelper.instance.database;
          await db.delete('reading_history');
          await db.delete('user_notes');
          await db.delete('book_notes');

          if (context.mounted) {
            await context.read<ReadingHistoryProvider>().loadHistoryForYear(
                  DateTime.now().year,
                );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(l10n.resetReadingHistorySuccess),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.resetReadingHistoryFailed(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handleCsvImport(
    BuildContext context,
    Future<bool> Function() importFunction,
    Function refreshFunction,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await importFunction();
    if (context.mounted) {
      if (success) {
        await refreshFunction();
        final csvProvider = context.read<CsvImportProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  l10n.csvUpdateSuccess(csvProvider.importedCount),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final csvProvider = context.read<CsvImportProvider>();
        final errorMessage = csvProvider.lastError ?? l10n.unknownError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailed(errorMessage)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getThemeModeText(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
      case ThemeMode.system:
        return l10n.systemTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSection(
            context,
            title: l10n.dataUpdate,
            children: [
              Consumer2<CsvImportProvider, BibleReadingProvider>(
                builder: (context, csvProvider, readingProvider, child) {
                  return ListTile(
                    leading:
                        const Icon(Icons.cloud_download, color: Colors.blue),
                    title: Text(l10n.dailyReadingUrlAuto),
                    subtitle: Text(l10n.urlDownloadOrLocal),
                    trailing: csvProvider.isDownloading ||
                            csvProvider.isImporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    onTap: csvProvider.isDownloading || csvProvider.isImporting
                        ? null
                        : () => _handleCsvImport(
                              context,
                              csvProvider.importReadingsAuto,
                              readingProvider.loadAllReadings,
                            ),
                  );
                },
              ),
              Consumer2<CsvImportProvider, BibleReadingProvider>(
                builder: (context, csvProvider, readingProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.folder_open, color: Colors.blue),
                    title: Text(l10n.dailyReadingUrlManual),
                    subtitle: Text(l10n.selectFile),
                    trailing: csvProvider.isImporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open),
                    onTap: csvProvider.isImporting
                        ? null
                        : () => _handleCsvImport(
                              context,
                              csvProvider.importReadingsFromFile,
                              readingProvider.loadAllReadings,
                            ),
                  );
                },
              ),
              Consumer2<CsvImportProvider, BibleBooksProvider>(
                builder: (context, csvProvider, booksProvider, child) {
                  return ListTile(
                    leading:
                        const Icon(Icons.cloud_download, color: Colors.green),
                    title: Text(l10n.bibleOverviewUrlAuto),
                    subtitle: Text(l10n.urlDownloadOrLocal),
                    trailing: csvProvider.isDownloading ||
                            csvProvider.isImporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    onTap: csvProvider.isDownloading || csvProvider.isImporting
                        ? null
                        : () => _handleCsvImport(
                              context,
                              csvProvider.importBooksAuto,
                              booksProvider.loadAllBooks,
                            ),
                  );
                },
              ),
              Consumer2<CsvImportProvider, BibleBooksProvider>(
                builder: (context, csvProvider, booksProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.folder_open, color: Colors.green),
                    title: Text(l10n.bibleOverviewUrlManual),
                    subtitle: Text(l10n.selectFile),
                    trailing: csvProvider.isImporting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_open),
                    onTap: csvProvider.isImporting
                        ? null
                        : () => _handleCsvImport(
                              context,
                              csvProvider.importBooksFromFile,
                              booksProvider.loadAllBooks,
                            ),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: l10n.dataResetSection,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: Text(l10n.resetReadingHistoryTitle),
                subtitle: Text(l10n.resetReadingHistorySubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _resetReadingHistory(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(l10n.resetAllDataTitle),
                subtitle: Text(l10n.resetAllDataSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _resetAllData(context),
              ),
            ],
          ),
          _buildSection(
            context,
            title: l10n.themeSettings,
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: const Icon(Icons.palette, color: Colors.purple),
                    title: Text(l10n.themeMode),
                    subtitle:
                        Text(_getThemeModeText(themeProvider.themeMode, l10n)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeDialog(context),
                  );
                },
              ),
              Consumer<ReadingHistoryProvider>(
                builder: (context, provider, child) {
                  return ListTile(
                    leading:
                        const Icon(Icons.calendar_month, color: Colors.orange),
                    title: Text(l10n.currentYear),
                    subtitle: Text(l10n.year(provider.currentYear)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showYearPicker(context),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context,
            title: l10n.statistics,
            children: [
              Consumer<ReadingHistoryProvider>(
                builder: (context, provider, child) {
                  final year = provider.currentYear;
                  final completed = provider.getCompletedCount(year);
                  final progress = provider.getProgressPercentage(year);

                  return ListTile(
                    leading: const Icon(Icons.show_chart, color: Colors.purple),
                    title: Text(l10n.completionRate),
                    subtitle: Text(
                      l10n.completionStatus(
                        completed,
                        progress.toStringAsFixed(1),
                      ),
                    ),
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
            ],
          ),
          _buildSection(
            context,
            title: l10n.appInfo,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: Text(l10n.version),
                subtitle: Text(l10n.appVersionValue),
              ),
              ListTile(
                leading: const Icon(Icons.copyright, color: Colors.blueGrey),
                title: Text(l10n.copyrightTitle),
                subtitle: Text(l10n.copyrightValue),
              ),
              ListTile(
                leading: const Icon(Icons.description, color: Colors.green),
                title: Text(l10n.csvFormat),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.csvFormatTitle),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.csvFormatDaily,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              l10n.csvFormatDailyColumns,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              l10n.csvFormatBooks,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              l10n.csvFormatBooksColumns,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              l10n.csvImportNotice,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      backLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade200
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: _buildDividedTiles(children, dividerColor),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDividedTiles(
    List<Widget> tiles,
    Color dividerColor,
  ) {
    final items = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      items.add(tiles[i]);
      if (i < tiles.length - 1) {
        items.add(Divider(height: 1, color: dividerColor));
      }
    }
    return items;
  }
}
