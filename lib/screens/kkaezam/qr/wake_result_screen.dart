import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../kkaezam_home_screen.dart'; // 홈으로 이동

class WakeResultScreen extends StatefulWidget {
  final String seatName;
  final String resultType;
  final String wakerNickname;
  final DateTime sleepStart;
  final DateTime wakeTime;
  final int sleepDuration;
  final int pointsEarned;
  final int actualSleepMinutes;
  final int overSleepMinutes;

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
  State<WakeResultScreen> createState() => _WakeResultScreenState();
}

class _WakeResultScreenState extends State<WakeResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('기상 결과 요약'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60), // for confetti space

                _buildInfoCard('📍 자리', widget.seatName, Icons.location_on),
                _buildInfoCard(
                  '🛌 수면 시작 시간',
                  formatter.format(widget.sleepStart),
                  Icons.access_time,
                ),
                _buildInfoCard(
                  '🌞 기상 시간',
                  formatter.format(widget.wakeTime),
                  Icons.access_alarm,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  '⏳ 실제 수면 시간',
                  '${widget.actualSleepMinutes} 분',
                  Icons.hourglass_empty,
                ),
                _buildInfoCard(
                  '🎯 목표 수면 시간',
                  '${widget.sleepDuration ~/ 60} 분',
                  Icons.timer,
                ),
                const SizedBox(height: 12),
                _buildInfoCard('🙋 깨워준 사람', widget.wakerNickname, Icons.person),
                _buildInfoCard(
                  '📋 기상 방식',
                  widget.resultType,
                  Icons.radio_button_checked,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  '🏆 획득한 포인트',
                  '${widget.pointsEarned} 점',
                  Icons.stars,
                  isPoints: true,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => KkaezamHomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5197FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '깨잠 홈으로 돌아가기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🎉 Confetti (위에 보이게)
          Align(
            alignment: Alignment.topCenter,
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
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon, {
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
