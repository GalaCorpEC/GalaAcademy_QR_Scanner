import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ToastificationWrapper es necesario para manejar las notificaciones
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Gala Academy QR Scanner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const QRScannerPage(),
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  Future<void> _handleScan(String? code) async {
    // Evitamos escanear varias veces mientras procesamos una petición
    if (code == null || _isProcessing) return;

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      // Validamos que sea una URL antes de intentar la petición
      final uri = Uri.tryParse(code);
      if (uri == null || !uri.hasScheme) {
        _showToast(
          title: 'QR Inválido',
          description: 'Contenido: $code',
          type: ToastificationType.warning,
        );
      } else {
        // Realizamos la petición a la API
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          _showToast(
            title: '¡Éxito!',
            description: 'Entrada validada correctamente.',
            type: ToastificationType.success,
          );
        } else {
          _showToast(
            title: 'Error de Servidor (${response.statusCode})',
            description:
                'Respuesta: ${response.body.isNotEmpty ? response.body : "Sin detalles"}',
            type: ToastificationType.error,
          );
        }
      }
    } catch (e) {
      _showToast(
        title: 'Error de Red / QR',
        description: 'Detalle: $e',
        type: ToastificationType.error,
      );
    } finally {
      // Esperamos 3 segundos antes de volver a habilitar el scanner
      // Esto evita peticiones infinitas si el QR sigue en pantalla
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showToast({
    required String title,
    required String description,
    required ToastificationType type,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: Text(description),
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12),
      showProgressBar: true,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El tamaño del cuadrado de escaneo
    const double scanAreaSize = 250.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Validador de Entradas'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Scanner en el centro con ventana de escaneo limitada
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: MobileScanner(
                  controller: _controller,
                  // Solo escanea lo que está dentro de este widget
                  fit: BoxFit.cover,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      _handleScan(barcodes.first.rawValue);
                    }
                  },
                ),
              ),
            ),
          ),

          // 2. Fondo blanco con hueco central (opcional si prefieres que el resto sea blanco puro)
          // Aquí simplemente dejamos el Scaffold blanco y centramos el scanner.

          // 3. Overlay para procesando (solo sobre el área del scanner o toda la pantalla)
          if (_isProcessing)
            Center(
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),

          // 4. Borde del área de escaneo
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.grey : Colors.blue,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          // 5. Instrucciones (ARRIBA del recuadro)
          Positioned(
            bottom:
                (MediaQuery.of(context).size.height / 2) +
                (scanAreaSize / 2) +
                20,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Coloca el código QR dentro del recuadro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
