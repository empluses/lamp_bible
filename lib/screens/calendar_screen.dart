import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/bible_reading_provider.dart';
import '../providers/reading_history_provider.dart';
import '../services/date_helper.dart';
import 'reading_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleReadingProvider>().loadAllReadings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendar),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Consumer2<ReadingHistoryProvider, BibleReadingProvider>(
                builder: (context, historyProvider, readingProvider, child) {
                  return TableCalendar(
                    firstDay: DateTime(_focusedDay.year, 1, 1),
                    lastDay: DateTime(_focusedDay.year, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    rowHeight: 52,
                    daysOfWeekHeight: 32,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) async {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }

                      final reading = await readingProvider.getReadingByDate(
                        selectedDay.month,
                        selectedDay.day,
                      );

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingDetailScreen(
                              year: selectedDay.year,
                              month: selectedDay.month,
                              day: selectedDay.day,
                              reading: reading,
                            ),
                          ),
                        );
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(4),
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Colors.red.shade300,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      weekendStyle: TextStyle(
                        color: Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        final isCompleted = historyProvider.isCompleted(
                          date.year,
                          date.month,
                          date.day,
                        );

                        if (date.month == 2 && date.day == 29) {
                          if (DateHelper.isLeapYear(date.year)) {
                            return Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(l10n.playPraise,
                                    style: TextStyle(fontSize: 12)),
                              ),
                            );
                          }
                        }

                        if (isCompleted) {
                          return Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Text('✅',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          );
                        }

                        return null;
                      },
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      headerPadding: const EdgeInsets.symmetric(vertical: 8),
                      titleTextStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 범례 (간략 표시)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildLegendChip(l10n.completed, Colors.green),
                  _buildLegendChip(l10n.todayReading, Colors.orange),
                  _buildLegendChip(l10n.remaining, Colors.grey),
                  if (DateHelper.isLeapYear(_focusedDay.year))
                    _buildLegendChip(l10n.playPraise, Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _buildLegendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
