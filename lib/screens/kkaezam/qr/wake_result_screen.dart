import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';

class WakeResultScreen extends StatefulWidget {
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
    required this.actualSleepMinutes,
    required this.overSleepMinutes,
  });

  @override
  _WakeResultScreenState createState() => _WakeResultScreenState();
}

class _WakeResultScreenState extends State<WakeResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 포인트가 0 이상일 때 빵빠레 애니메이션을 실행
    if (widget.pointsEarned > 0) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('HH:mm');
    final bool isGoalAchieved = widget.overSleepMinutes >= 10;

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
            // 빵빠레 애니메이션
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.yellow,
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 자리
            _buildInfoCard(
              title: '📍 자리',
              value: widget.seatName,
              icon: Icons.location_on,
            ),

            // 수면 시간
            _buildInfoCard(
              title: '🛌 수면 시작 시간',
              value: formatter.format(widget.sleepStart),
              icon: Icons.access_time,
            ),
            _buildInfoCard(
              title: '🌞 기상 시간',
              value: formatter.format(widget.wakeTime),
              icon: Icons.access_alarm,
            ),

            const SizedBox(height: 12),

            // 수면 상세 정보
            _buildInfoCard(
              title: '⏳ 실제 수면 시간',
              value: '${widget.actualSleepMinutes} 분',
              icon: Icons.hourglass_empty,
            ),
            _buildInfoCard(
              title: '🎯 목표 수면 시간',
              value: '${widget.sleepDuration ~/ 60} 분',
              icon: Icons.timer,
            ),

            const SizedBox(height: 12),

            // 기상 방식과 깨운 사람
            _buildInfoCard(
              title: '🙋 깨워준 사람',
              value: widget.wakerNickname,
              icon: Icons.person,
            ),
            _buildInfoCard(
              title: '📋 기상 방식',
              value: widget.resultType,
              icon: Icons.radio_button_checked,
            ),

            const SizedBox(height: 12),

            // 포인트
            _buildInfoCard(
              title: '🏆 획득한 포인트',
              value: '${widget.pointsEarned} 점',
              icon: Icons.stars,
              isPoints: true,
            ),

            const Spacer(),

            // "홈으로 돌아가기" 버튼
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('홈으로 돌아가기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blueAccent, // primary 대신 backgroundColor로 변경
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 카드 형태로 정보를 표시하는 위젯
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPoints = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(value, style: TextStyle(fontSize: isPoints ? 20 : 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
