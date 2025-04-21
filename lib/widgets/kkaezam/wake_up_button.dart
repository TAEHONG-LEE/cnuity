import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WakeUpButton extends StatefulWidget {
  final VoidCallback onComplete;

  const WakeUpButton({super.key, required this.onComplete});

  @override
  State<WakeUpButton> createState() => _WakeUpButtonState();
}

class _WakeUpButtonState extends State<WakeUpButton> {
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  bool _isProcessing = false;

  Future<void> _handleWakeUp() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('seats')
            .where('reservedBy', isEqualTo: uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final seatDoc = snapshot.docs.first;
      final seatRef = seatDoc.reference;

      await seatRef.update({
        'status': 'woken_by_self',
        'wakeTime': Timestamp.now(),
        'wasWokenByOther': false,
        'isCompleted': true,
      });

      // 빵빠레 시작
      _confettiController.play();

      // 2초 대기 후 onComplete 호출
      await Future.delayed(const Duration(seconds: 3));
      widget.onComplete();
    }

    setState(() => _isProcessing = false);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : _handleWakeUp,
          icon: const Icon(Icons.sunny),
          label: const Text('일어나기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 20,
          emissionFrequency: 0.05,
          gravity: 0.2,
        ),
      ],
    );
  }
}
