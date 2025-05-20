import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// 앱 실행 시 호출: 권한 요청 + 토큰 저장 + 리스너 등록
  static Future<void> init() async {
    // (1) 권한 요청
    await _messaging.requestPermission();

    // (2) 현재 토큰 저장
    await _saveToken();

    // (3) 토큰 갱신 시 다시 저장
    _messaging.onTokenRefresh.listen((token) => _saveToken());

    // ✅ (4) 포그라운드 수신 알림 표시
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '알림';
      final body = message.notification?.body ?? '';

      print('📩 FCM 수신됨: $title - $body');

      // 실제 사용자에게 표시 (예: 토스트)
      Fluttertoast.showToast(msg: '$title\n$body');
    });
  }

  static Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _db
        .collection("users")
        .doc(user.uid)
        .collection("fcmTokens")
        .doc(token)
        .set({'updatedAt': FieldValue.serverTimestamp()});
  }
}
