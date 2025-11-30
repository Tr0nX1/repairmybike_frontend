import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'search_page.dart';
import 'widgets/rm_app_bar.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final supportsScanner = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: const RMAppBar(title: 'Scan QR Code'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (supportsScanner)
            MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.normal,
                facing: CameraFacing.back,
              ),
              onDetect: (capture) {
                if (_handled) return;
                final List<Barcode> barcodes = capture.barcodes;
                final code = barcodes
                    .map((b) => b.rawValue)
                    .whereType<String>()
                    .firstWhere((v) => v.isNotEmpty, orElse: () => '');
                if (code.isNotEmpty) {
                  _handled = true;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => SearchPage(initialQuery: code)),
                  );
                }
              },
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2, color: Colors.white54, size: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'QR scanning is not available on this platform.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please type or paste the code in the search field.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SearchPage()),
                        );
                      },
                      child: const Text('Open Search'),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0x80000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  supportsScanner
                      ? 'Point camera at QR code. On success, search opens.'
                      : 'Scanning disabled. Use search instead to paste or type the code.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
