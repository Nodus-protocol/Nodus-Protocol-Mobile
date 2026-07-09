import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Returns the first non-empty raw value among [barcodes], or null if none
/// decoded to usable text. Factored out of the widget so it can be unit
/// tested without a real camera/platform channel.
String? firstValidRawValue(List<Barcode> barcodes) {
  for (final barcode in barcodes) {
    final value = barcode.rawValue;
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

/// Full-screen QR scanner. Pops the route with the first successfully
/// decoded barcode's raw string value once found, or null if the user
/// backs out without scanning anything.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key, this.title = 'Scan QR code'});

  final String title;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = firstValidRawValue(capture.barcodes);
    if (value == null) return;
    _handled = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) => _ScannerError(error: error),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Camera unavailable: '
              '${error.errorDetails?.message ?? error.errorCode}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
