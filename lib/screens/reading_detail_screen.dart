import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bible_reading.dart';
import '../models/user_note.dart';
import '../providers/reading_history_provider.dart';
import '../services/database_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReadingDetailScreen extends StatefulWidget {
  final int year;
  final int month;
  final int day;
  final BibleReading? reading;

  const ReadingDetailScreen({
    super.key,
    required this.year,
    required this.month,
    required this.day,
    this.reading,
  });

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final _verseController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isCompleted = false;
  UserNote? _existingNote;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _verseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final historyProvider = context.read<ReadingHistoryProvider>();
    _isCompleted = historyProvider.isCompleted(
      widget.year,
      widget.month,
      widget.day,
    );

    final db = await DatabaseHelper.instance.database;
    final notes = await db.query(
      'user_notes',
      where: 'year = ? AND month = ? AND day = ?',
      whereArgs: [widget.year, widget.month, widget.day],
    );

    if (notes.isNotEmpty) {
      _existingNote = UserNote.fromMap(notes.first);
      _verseController.text = _existingNote?.verseReference ?? '';
      _noteController.text = _existingNote?.noteContent ?? '';
    }

    setState(() {});
  }

  Future<void> _launchYouTube() async {
    if (widget.reading == null) return;

    final url = Uri.parse(widget.reading!.youtubeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.cannotOpenYoutube)),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterMemoContent)),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      if (_existingNote != null) {
        await db.update(
          'user_notes',
          {
            'verse_reference': _verseController.text.trim(),
            'note_content': _noteController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_existingNote!.id],
        );
      } else {
        await db.insert('user_notes', {
          'year': widget.year,
          'month': widget.month,
          'day': widget.day,
          'verse_reference': _verseController.text.trim(),
          'note_content': _noteController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.saved),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.saveFailed(e.toString())),
        ));
      }
    }
  }

  Future<void> _toggleCompleted() async {
    final historyProvider = context.read<ReadingHistoryProvider>();
    await historyProvider.markAsCompleted(
      widget.year,
      widget.month,
      widget.day,
      !_isCompleted,
    );
    setState(() {
      _isCompleted = !_isCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              expandedHeight: screenHeight * 0.12,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                title: FittedBox(
                  child: Text(
                    l10n.readingDetail(widget.year, widget.month, widget.day),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.reading != null) ...[
                      // 제목 카드
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reading!.isSpecial ? '🎵' : '📖',
                              style: TextStyle(fontSize: isSmallScreen ? 28 : 36),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              widget.reading!.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (widget.reading!.chapterInfo != null) ...[
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                widget.reading!.chapterInfo!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // YouTube 재생 버튼
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _launchYouTube,
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 18,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    size: isSmallScreen ? 28 : 32,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Flexible(
                                    child: Text(
                                      widget.reading!.isSpecial
                                          ? l10n.playPraise
                                          : l10n.playVideo,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.08),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                          children: [
                            Icon(
                              Icons.videocam_off_outlined,
                              size: isSmallScreen ? 48 : 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Text(
                              l10n.noVideoAvailable,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                    ],

                    // 묵상 노트 섹션
                    Text(
                      '✍️ ${l10n.myNotes}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

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
                        children: [
                          TextField(
                            controller: _verseController,
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            decoration: InputDecoration(
                              labelText: l10n.verseReference,
                              labelStyle:
                                  TextStyle(fontSize: isSmallScreen ? 13 : 15),
                              hintText: l10n.verseHint,
                              hintStyle:
                                  TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              prefixIcon: Icon(
                                Icons.bookmark_outline,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          TextField(
                            controller: _noteController,
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                            decoration: InputDecoration(
                              labelText: l10n.noteContent,
                              labelStyle:
                                  TextStyle(fontSize: isSmallScreen ? 13 : 15),
                              hintText: l10n.noteHint,
                              hintStyle:
                                  TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              prefixIcon: Icon(
                                Icons.edit_outlined,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            maxLines: isSmallScreen ? 6 : 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ],
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
            child: Row(
              children: [
                _buildFooterAction(
                  icon: Icons.arrow_back_rounded,
                  label: backLabel,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.maybePop(context);
                  },
                  color: isDark ? Colors.white : Colors.black,
                  labelColor:
                      isDark ? Colors.grey.shade200 : Colors.grey.shade700,
                ),
                _buildFooterAction(
                  icon:
                      _isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  label: _isCompleted ? l10n.completed : l10n.markCompleted,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _toggleCompleted();
                  },
                  color: _isCompleted ? Colors.green.shade500 : Colors.grey,
                  labelColor:
                      _isCompleted ? Colors.green.shade600 : Colors.grey,
                ),
                _buildFooterAction(
                  icon: Icons.save_outlined,
                  label: l10n.save,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    _saveNote();
                  },
                  color: Colors.blue.shade500,
                  labelColor: Colors.blue.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterAction({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
    required Color labelColor,
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
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
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
