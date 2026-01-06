import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
          const SnackBar(content: Text('YouTube를 열 수 없습니다')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메모 내용을 입력해주세요')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.koreanName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 정보
            Center(
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
                  const SizedBox(height: 15),
                  Text(
                    widget.book.koreanName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '📖 ${widget.book.testament == 'OLD' ? '구약성경' : '신약성경'} ${widget.book.bookNumber}권 / ${widget.book.chaptersCount}장',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 저자 정보
            if (widget.book.author != null) ...[
              _buildInfoRow('✍️ 저자', widget.book.author!),
              const SizedBox(height: 15),
            ],

            // YouTube 버튼
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _launchYouTube,
                icon: const Icon(Icons.play_circle_filled, size: 30),
                label: const Text(
                  '개요 영상 보기',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 요약
            if (widget.book.summary != null) ...[
              const Text(
                '📝 요약',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.book.summary!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],

            // 나의 메모
            const Text(
              '✍️ 나의 메모',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: '이 성경책에 대한 메모를 작성해보세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save),
                label: const Text(
                  '저장',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
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
