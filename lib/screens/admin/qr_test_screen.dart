import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../utils/qr_helper.dart'; // QR 디코드 유틸

class QrTestScreen extends StatefulWidget {
  const QrTestScreen({super.key});

  @override
  State<QrTestScreen> createState() => _QrTestScreenState();
}

class _QrTestScreenState extends State<QrTestScreen> {
  final MobileScannerController _controller = MobileScannerController();
  String _scanResult = 'QR 코드를 스캔하면 결과가 여기에 표시됩니다.';

  Future<void> _handleScan(String? rawData) async {
    if (rawData == null) return;

    try {
      final decoded = QrHelper.decodeQrData(rawData);
      setState(() {
        _scanResult = decoded.toString(); // 📦 디코딩된 데이터를 문자열로 표시
      });
    } catch (e) {
      setState(() {
        _scanResult = 'QR 디코드 실패: $e';
      });
    } finally {
      _controller.stop(); // 스캔 일시정지
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 테스트 (Admin)'),
        backgroundColor: const Color(0xFF5197FF),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                final rawValue = barcode.rawValue;
                _handleScan(rawValue);
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.grey[200],
              child: SingleChildScrollView(
                child: Text(_scanResult, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
