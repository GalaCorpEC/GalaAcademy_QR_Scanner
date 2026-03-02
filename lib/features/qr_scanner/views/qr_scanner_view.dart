import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_provider.dart';

class QRScannerView extends ConsumerStatefulWidget {
  const QRScannerView({super.key});

  @override
  ConsumerState<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends ConsumerState<QRScannerView> {
  final MobileScannerController controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isModalOpen = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final size = MediaQuery.of(context).size;
    final double scanAreaSize = size.width * 0.75;

    ref.listen(scanProvider, (previous, next) {
      if (previous?.isProcessing == true &&
          next.isProcessing == false &&
          next.lastResult != null &&
          !_isModalOpen) {
        setState(() => _isModalOpen = true);
        _showResultDialog(context, next.lastResult!, next.isError);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: scanAreaSize,
              height: scanAreaSize,
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty &&
                  !scanState.isProcessing &&
                  !_isModalOpen &&
                  scanState.lastResult == null) {
                final String code = barcodes.first.rawValue ?? "";
                if (code.isNotEmpty) {
                  ref.read(scanProvider.notifier).processUrl(code);
                }
              }
            },
          ),

          _buildScannerOverlay(context),

          Positioned(
            top: 50,
            left: 20,
            child: _buildCircleButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: Color(0xFFE57700),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Encuadra el código en el centro',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (scanState.isProcessing)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE57700)),
                    SizedBox(height: 20),
                    Text(
                      'VALIDANDO...',
                      style: TextStyle(
                        color: Color(0xFFE57700),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanAreaSize = size.width * 0.75;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: CustomPaint(
            painter: ScannerFramePainter(color: const Color(0xFFE57700)),
            size: Size(scanAreaSize, scanAreaSize),
          ),
        ),
      ],
    );
  }

  void _showResultDialog(BuildContext context, String message, bool isError) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Opacity(
          opacity: anim1.value,
          child: Transform.scale(
            scale: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.only(
                top: 40,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.warning_rounded : Icons.verified_rounded,
                      size: 40,
                      color: isError ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isError ? 'ADVERTENCIA' : 'VALIDADO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isError ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isError ? Colors.red : Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isModalOpen = false);
                        ref.read(scanProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'CONTINUAR',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  final Color color;
  ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final double l = 40.0;
    final double r = 28.0;

    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(l, 0),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - l, 0)
        ..lineTo(size.width - r, 0)
        ..quadraticBezierTo(size.width, 0, size.width, r)
        ..lineTo(size.width, l),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - l)
        ..lineTo(0, size.height - r)
        ..quadraticBezierTo(0, size.height, r, size.height)
        ..lineTo(l, size.height),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - l, size.height)
        ..lineTo(size.width - r, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - r,
        )
        ..lineTo(size.width, size.height - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
