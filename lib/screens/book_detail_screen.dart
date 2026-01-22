import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/book_note.dart';
import '../models/bible_book.dart';
import '../services/database_helper.dart';

class BookDetailScreen extends StatefulWidget {
  final BibleBook book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _noteController = TextEditingController();
  BookNote? _existingNote;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    final db = await DatabaseHelper.instance.database;
    final notes = await db.query(
      'book_notes',
      where: 'book_id = ?',
      whereArgs: [widget.book.id],
    );

    if (notes.isNotEmpty) {
      _existingNote = BookNote.fromMap(notes.first);
      _noteController.text = _existingNote?.noteContent ?? '';
    }

    setState(() {});
  }

  Future<void> _launchYouTube() async {
    final url = Uri.parse(widget.book.youtubeUrl);
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
          'book_notes',
          {
            'note_content': _noteController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [_existingNote!.id],
        );
      } else {
        await db.insert('book_notes', {
          'book_id': widget.book.id,
          'note_content': _noteController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saved)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
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
                    l10n.bookDetail,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: widget.book.testament == 'OLD'
                                  ? Colors.blue
                                  : Colors.red,
                              child: Text(
                                '${widget.book.bookNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.book.koreanName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 26,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '📖 ${widget.book.testament == 'OLD' ? l10n.oldTestament(widget.book.bookNumber) : l10n.newTestament(widget.book.bookNumber)} ${l10n.chapters(widget.book.chaptersCount)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 저자 정보
                    if (widget.book.author != null) ...[
                      _buildInfoRow('✍️ ${l10n.author}', widget.book.author!),
                      const SizedBox(height: 15),
                    ],

                    // YouTube 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _launchYouTube,
                        icon: const Icon(Icons.play_circle_filled, size: 30),
                        label: Text(
                          l10n.viewOverview,
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 요약
                    if (widget.book.summary != null) ...[
                      Text(
                        '📝 ${l10n.summary}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.9,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey.shade900 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.25 : 0.06,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: 16,
                              ),
                              child: Text(
                                widget.book.summary!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  height: 1.5,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // 나의 메모
                    Text(
                      '✍️ ${l10n.myMemo}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _noteController,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        decoration: InputDecoration(
                          labelText: l10n.myMemo,
                          labelStyle:
                              TextStyle(fontSize: isSmallScreen ? 13 : 15),
                          hintText: l10n.memoHint,
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
                        maxLines: 6,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 10),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
