import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  static final _local = FlutterLocalNotificationsPlugin();

  /// 앱 실행 시 호출
  static Future<void> init() async {
    // (1) 알림 권한 요청
    await _messaging.requestPermission();

    // (2) FCM 토큰 저장
    await _saveToken();

    // (3) 토큰 갱신 감지
    _messaging.onTokenRefresh.listen((token) => _saveToken());

    // ✅ (4) 로컬 알림 초기화
    await _initLocalNotification();

    // ✅ (5) 포그라운드 알림 수신 시 로컬 알림 표시
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? '알림';
      final body = message.notification?.body ?? '';
      _local.show(
        0,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'kkaezam_channel', // 채널 ID
            'Kkaezam 알림',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
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

  static Future<void> _initLocalNotification() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _local.initialize(settings);
  }
}
