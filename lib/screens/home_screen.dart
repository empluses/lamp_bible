import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/reading_history_provider.dart';
import '../services/date_helper.dart';
import 'calendar_screen.dart';
import 'bible_books_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyProvider = context.read<ReadingHistoryProvider>();
      historyProvider.loadHistoryForYear(DateTime.now().year);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getEncouragementIcon(double progress) {
    if (progress >= 100) return '🏆';
    if (progress >= 80) return '🎉';
    if (progress >= 60) return '⭐';
    if (progress >= 40) return '🔥';
    if (progress >= 20) return '💪';
    return '😊';
  }

  String _getEncouragementMessage(BuildContext context, double progress) {
    final l10n = AppLocalizations.of(context)!;
    if (progress >= 100) return l10n.encouragement100;
    if (progress >= 80) return l10n.encouragement80;
    if (progress >= 60) return l10n.encouragement60;
    if (progress >= 40) return l10n.encouragement40;
    if (progress >= 20) return l10n.encouragement20;
    return l10n.encouragement0;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 100) return Colors.red.shade400;
    if (progress >= 80) return Colors.purple.shade400;
    if (progress >= 60) return Colors.amber.shade400;
    if (progress >= 40) return Colors.orange.shade400;
    if (progress >= 20) return Colors.green.shade400;
    return Colors.blue.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isSmallScreen = screenWidth < 360;
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            12,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Consumer<ReadingHistoryProvider>(
              builder: (context, historyProvider, child) {
                final year = historyProvider.currentYear;
                final totalDays = DateHelper.getTotalDaysInYear(year);
                final completedDays = historyProvider.getCompletedCount(year);
                final uncompletedDays =
                    historyProvider.getUncompletedCount(year);
                final streakDays = historyProvider.getStreakDays(year);
                final progress = historyProvider.getProgressPercentage(year);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final cardPadding = isSmallScreen ? 14.0 : 18.0;
                    final circleSize = (availableHeight * 0.32)
                        .clamp(140.0, isSmallScreen ? 170.0 : 200.0);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.homeTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getProgressColor(progress).withOpacity(0.2),
                                _getProgressColor(progress).withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.yearlyReading(year),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: _getProgressColor(progress),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        Colors.grey.shade900,
                                        Colors.grey.shade800
                                      ]
                                    : [Colors.white, Colors.grey.shade50],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: _getProgressColor(progress)
                                      .withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                children: [
                                  Text(
                                    l10n.progressStatus,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 17,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Center(
                                            child: SizedBox(
                                              width: circleSize,
                                              height: circleSize,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: circleSize,
                                                    height: circleSize,
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: progress / 100,
                                                      strokeWidth: isSmallScreen
                                                          ? 10
                                                          : 12,
                                                      backgroundColor:
                                                          Colors.grey.shade300,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        _getProgressColor(
                                                          progress,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      FittedBox(
                                                        child: Text(
                                                          '${progress.toStringAsFixed(1)}%',
                                                          style: TextStyle(
                                                            fontSize:
                                                                circleSize *
                                                                    0.18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                _getProgressColor(
                                                              progress,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      FittedBox(
                                                        child: Text(
                                                          '$completedDays / ${l10n.days(totalDays)}',
                                                          style: TextStyle(
                                                            fontSize:
                                                                circleSize *
                                                                    0.08,
                                                            color: Colors
                                                                .grey.shade600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (isSmallScreen) ...[
                                                _buildCompactStat(
                                                  '✅',
                                                  l10n.days(completedDays),
                                                  Colors.green,
                                                  isDark,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildCompactStat(
                                                  '⏳',
                                                  l10n.days(uncompletedDays),
                                                  Colors.orange,
                                                  isDark,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildCompactStat(
                                                  '🔥',
                                                  l10n.days(streakDays),
                                                  Colors.red,
                                                  isDark,
                                                ),
                                              ] else ...[
                                                _buildStatCard(
                                                  context,
                                                  '✅',
                                                  l10n.completed,
                                                  l10n.days(completedDays),
                                                  Colors.green,
                                                  isDark,
                                                  isSmallScreen,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildStatCard(
                                                  context,
                                                  '⏳',
                                                  l10n.remaining,
                                                  l10n.days(uncompletedDays),
                                                  Colors.orange,
                                                  isDark,
                                                  isSmallScreen,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildStatCard(
                                                  context,
                                                  '🔥',
                                                  l10n.streak,
                                                  l10n.days(streakDays),
                                                  Colors.red,
                                                  isDark,
                                                  isSmallScreen,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getProgressColor(progress)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getEncouragementIcon(progress),
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 24 : 28,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _getEncouragementMessage(
                                              context,
                                              progress,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _getProgressColor(progress),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            screenHeight * 0.02,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildFooterAction(
                context,
                icon: Icons.calendar_today_rounded,
                label: l10n.todayReading,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CalendarScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildFooterAction(
                context,
                icon: Icons.menu_book_rounded,
                label: l10n.bibleOverview,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BibleBooksScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildFooterAction(
                context,
                icon: Icons.settings_outlined,
                label: l10n.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String icon,
    String label,
    String value,
    Color color,
    bool isDark,
    bool isSmallScreen,
  ) {
    return Container(
      constraints: BoxConstraints(
        minWidth: isSmallScreen ? 90 : 100,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: isSmallScreen ? 20 : 24)),
          SizedBox(height: isSmallScreen ? 4 : 6),
          FittedBox(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
    String icon,
    String value,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isDark ? Colors.white : Colors.black,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
