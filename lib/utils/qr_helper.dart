import 'dart:convert';

class QrHelper {
  /// QR 데이터 인코딩 (JSON → Base64 문자열)
  static String encodeQrData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return base64Encode(utf8.encode(jsonString));
  }

  /// QR 데이터 디코딩 (Base64 문자열 → JSON)
  static Map<String, dynamic> decodeQrData(String base64String) {
    try {
      final jsonString = utf8.decode(base64Decode(base64String));
      return jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('QR 디코딩 실패: $e');
    }
  }
}
