import 'package:flutter/material.dart';

class EncouragementWidget extends StatelessWidget {
  final double progress;

  const EncouragementWidget({
    super.key,
    required this.progress,
  });

  String _getIcon() {
    if (progress >= 100) return '🏆';
    if (progress >= 80) return '🎉';
    if (progress >= 60) return '⭐';
    if (progress >= 40) return '🔥';
    if (progress >= 20) return '💪';
    return '😊';
  }

  String _getMessage() {
    if (progress >= 100) return '완독 축하합니다!';
    if (progress >= 80) return '거의 다 왔어요!';
    if (progress >= 60) return '정말 잘하고 있어요!';
    if (progress >= 40) return '절반을 넘었어요!';
    if (progress >= 20) return '힘내세요!';
    return '시작이 반입니다!';
  }

  Color _getColor() {
    if (progress >= 100) return Colors.red;
    if (progress >= 80) return Colors.purple;
    if (progress >= 60) return Colors.amber;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: _getColor().withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
              _getIcon(),
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 10),
            Text(
              _getMessage(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '계속 이어가세요!',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressBarWidget extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const ProgressBarWidget({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
  });

  Color _getColor() {
    if (progress >= 100) return Colors.red;
    if (progress >= 80) return Colors.purple;
    if (progress >= 60) return Colors.amber;
    if (progress >= 40) return Colors.orange;
    if (progress >= 20) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          minHeight: 20,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
        ),
        const SizedBox(height: 10),
        Text(
          '$completed / $total일',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
