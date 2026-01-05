import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FullScannerScreen extends StatefulWidget {
  final String title;
  const FullScannerScreen({super.key, required this.title});

  @override
  State<FullScannerScreen> createState() => _FullScannerScreenState();
}

class _FullScannerScreenState extends State<FullScannerScreen> {
  bool _isTorchOn = false;
  bool _isPopped = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isPopped) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _isPopped = true;
                HapticFeedback.vibrate();
                SystemSound.play(SystemSoundType.click);
                _controller.stop();
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
          
          // Scanner Overlay (Cutout)
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Torch Toggle
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                _controller.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
          ),

          // Title and Bottom Instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "Align barcode within the frame",
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    const double cutoutSize = 250.0;
    final double left = (size.width - cutoutSize) / 2;
    final double top = (size.height - cutoutSize) / 2;
    final Rect cutoutRect = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw Corners
    final borderPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const double cornerLength = 30.0;
    const double radius = 20.0;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutSize - cornerLength, top)
        ..lineTo(left + cutoutSize - radius, top)
        ..arcToPoint(Offset(left + cutoutSize, top + radius), radius: const Radius.circular(radius))
        ..lineTo(left + cutoutSize, top + cornerLength),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cutoutSize - cornerLength)
        ..lineTo(left, top + cutoutSize - radius)
        ..arcToPoint(Offset(left + radius, top + cutoutSize), radius: const Radius.circular(radius))
        ..lineTo(left + cornerLength, top + cutoutSize),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutSize - cornerLength, top + cutoutSize)
        ..lineTo(left + cutoutSize - radius, top + cutoutSize)
        ..arcToPoint(Offset(left + cutoutSize, top + cutoutSize - radius), radius: const Radius.circular(radius))
        ..lineTo(left + cutoutSize, top + cutoutSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
