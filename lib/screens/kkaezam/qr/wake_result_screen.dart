import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WakeResultScreen extends StatelessWidget {
  final String seatName;
  final String resultType;
  final String wakerNickname;
  final DateTime sleepStart;
  final DateTime wakeTime;
  final int sleepDuration;
  final int pointsEarned;
  final int actualSleepMinutes; // 실제 수면 시간
  final int overSleepMinutes; // 초과 수면 시간

  const WakeResultScreen({
    super.key,
    required this.seatName,
    required this.resultType,
    required this.wakerNickname,
    required this.sleepStart,
    required this.wakeTime,
    required this.sleepDuration,
    required this.pointsEarned,
    required this.actualSleepMinutes, // 실제 수면 시간
    required this.overSleepMinutes, // 초과 수면 시간
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');

    // 디버깅 정보를 출력
    debugPrint('📍 자리: $seatName');
    debugPrint('🛌 수면 시작 시간: ${formatter.format(sleepStart)}');
    debugPrint('🌞 기상 시간: ${formatter.format(wakeTime)}');
    debugPrint('⏳ 실제 수면 시간: $actualSleepMinutes 분');
    debugPrint('🎯 목표 수면 시간: ${sleepDuration ~/ 60} 분');
    debugPrint('📝 실제 수면 시간 초과: $overSleepMinutes 분');
    debugPrint(
      '💡 예약된 목표 수면 시간 초과 여부: ${overSleepMinutes >= 30 ? '30분 초과 (-10P)' : (overSleepMinutes >= 10 ? '10분 초과 (-5P)' : '정상 수면')}',
    );
    debugPrint('🏆 획득한 포인트: $pointsEarned 점');

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
            Text('⏳ 실제 수면 시간: $actualSleepMinutes 분', style: _normalStyle),
            Text('🎯 목표 수면 시간: ${sleepDuration ~/ 60} 분', style: _normalStyle),
            const SizedBox(height: 12),
            Text('🙋 깨워준 사람: $wakerNickname', style: _normalStyle),
            Text('📋 기상 방식: $resultType', style: _normalStyle),
            const SizedBox(height: 12),
            Text('🏆 획득한 포인트: $pointsEarned 점', style: _pointStyle),
            const SizedBox(height: 12),
            // 디버깅 정보 추가
            Text('📝 실제 수면 시간 초과: $overSleepMinutes 분', style: _debugStyle),
            Text(
              '💡 예약된 목표 수면 시간 초과 여부: ${overSleepMinutes >= 30 ? '30분 초과 (-10P)' : (overSleepMinutes >= 10 ? '10분 초과 (-5P)' : '정상 수면')}',
              style: _debugStyle,
            ),
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

  TextStyle get _debugStyle => const TextStyle(
    fontSize: 14,
    color: Colors.red,
    fontWeight: FontWeight.bold,
  );
}
