import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/colors.dart';

/// QR scanner screen for scanning the borrower's handover code.
///
/// Displays the camera viewfinder, detects QR codes, and returns the
/// scanned [String] code to the caller via [Navigator.pop].
class QrScannerScreen extends StatefulWidget {
  /// Creates a [QrScannerScreen] with an optional [key].
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isScanning ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: () async {
              await _controller?.toggleTorch();
              if (mounted) setState(() => _isScanning = !_isScanning);
            },
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final String? code = barcodes.firstOrNull?.rawValue;
          if (code != null && _isScanning && mounted) {
            setState(() => _isScanning = false);
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
