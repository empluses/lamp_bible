import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bible_reading.dart';
import '../models/user_note.dart';
import '../providers/reading_history_provider.dart';
import '../services/database_helper.dart';

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

    // 기존 노트 로드
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
          const SnackBar(content: Text('YouTube를 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('묵상 내용을 입력해주세요')),
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
          const SnackBar(content: Text('저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.year}년 ${widget.month}월 ${widget.day}일'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reading != null) ...[
              // 제목
              Text(
                '📖 ${widget.reading!.title}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.reading!.chapterInfo != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.reading!.chapterInfo!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // YouTube 재생 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _launchYouTube,
                  icon: const Icon(Icons.play_circle_filled, size: 30),
                  label: Text(
                    widget.reading!.isSpecial ? '찬양 영상 보기' : 'YouTube 영상 재생',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ] else ...[
              const Center(
                child: Text(
                  '이 날짜에 대한 영상이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // 묵상 노트
            const Text(
              '✍️ 나의 묵상 노트',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _verseController,
              decoration: const InputDecoration(
                labelText: '성경 구절',
                hintText: '예: 창세기 1:1-3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '묵상 내용',
                hintText: '오늘 읽은 말씀에 대한 묵상을 기록해보세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 20),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleCompleted,
                    icon: Icon(_isCompleted
                        ? Icons.check_circle
                        : Icons.circle_outlined),
                    label: Text(_isCompleted ? '완료됨' : '완료 표시'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isCompleted ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveNote,
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
