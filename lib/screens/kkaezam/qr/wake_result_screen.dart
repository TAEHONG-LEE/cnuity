import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WakeResultScreen extends StatelessWidget {
  final String seatName; // 🔥 seatId 대신 seatName
  final String resultType;
  final String wakerNickname;
  final DateTime sleepStart;
  final DateTime wakeTime;
  final int sleepDuration; // 초 단위
  final int pointsEarned;

  const WakeResultScreen({
    super.key,
    required this.seatName,
    required this.resultType,
    required this.wakerNickname,
    required this.sleepStart,
    required this.wakeTime,
    required this.sleepDuration,
    required this.pointsEarned,
  });

  @override
  Widget build(BuildContext context) {
    final actualSleepMinutes = wakeTime.difference(sleepStart).inMinutes;
    final targetSleepMinutes = sleepDuration ~/ 60;
    final formatter = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('기상 결과 요약'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 자리: $seatName', style: _titleStyle),
            const SizedBox(height: 12),
            Text(
              '🛌 수면 시작 시간: ${formatter.format(sleepStart)}',
              style: _normalStyle,
            ),
            Text(
              '🌞 기상 시간: ${formatter.format(wakeTime)}',
              style: _normalStyle,
            ),
            const SizedBox(height: 12),
            Text('⏳ 실제 수면 시간: ${actualSleepMinutes}분', style: _normalStyle),
            Text('🎯 목표 수면 시간: ${targetSleepMinutes}분', style: _normalStyle),
            const SizedBox(height: 12),
            Text('🙋 깨워준 사람: $wakerNickname', style: _normalStyle),
            Text('📋 기상 방식: $resultType', style: _normalStyle),
            const SizedBox(height: 12),
            Text('🏆 획득한 포인트: $pointsEarned점', style: _pointStyle),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('홈으로 돌아가기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _titleStyle =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  TextStyle get _normalStyle => const TextStyle(fontSize: 16);

  TextStyle get _pointStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  );
}
