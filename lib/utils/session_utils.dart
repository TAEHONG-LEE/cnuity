// lib/utils/session_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// [uid] - 사용자 고유 ID
/// [seatId] - 사용한 좌석 ID
/// [roomDocId] - 좌석이 속한 열람실 문서 ID
/// [sleepStart] - 수면 시작 시간 (Timestamp)
/// [sleepDuration] - 사용자가 설정한 수면 시간 (초 단위)
/// [wakeTime] - 실제 기상 시각 (Timestamp)
/// [wokeBy] - 기상하게 만든 주체 (자기자신 또는 타인 UID)
/// [result] - 기상 결과 ('self_wake', 'forced_wake', 'fail' 등)
/// [pointsGiven] - 수면 시작 시 차감한 포인트
/// [pointsRewardedToOther] - 타인이 기상시켰을 경우 지급한 보상 포인트
/// [wasWokenByOther] - 타인에 의해 기상했는지 여부
/// [isCompleted] - 세션이 완료되었는지 여부

class SleepSessionService {
  static Future<void> saveSleepSession({
    required String seatId,
    required String roomDocId,
    required Timestamp sleepStart,
    required Timestamp wakeTime,
    required int sleepDuration,
    required String result,
    required int pointsGiven,
    String wokeBy = '',
    int pointsRewardedToOther = 0,
  }) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final int actualSleepTime =
        wakeTime.toDate().difference(sleepStart.toDate()).inSeconds;

    final sessionRef =
        FirebaseFirestore.instance.collection('sleep_sessions').doc();

    await sessionRef.set({
      'sessionId': sessionRef.id,
      'uid': uid,
      'seatId': seatId,
      'roomDocId': roomDocId,
      'sleepStart': sleepStart,
      'wakeTime': wakeTime,
      'sleepDuration': sleepDuration,
      'actualSleepTime': actualSleepTime,
      'wokeBy': wokeBy,
      'result': result,
      'pointsGiven': pointsGiven,
      'pointsRewardedToOther': pointsRewardedToOther,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
