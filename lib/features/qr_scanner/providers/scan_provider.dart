import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

class ScanState {
  final bool isProcessing;
  final String? lastResult;
  final bool isError;
  final int? selectedEventId;

  ScanState({
    this.isProcessing = false,
    this.lastResult,
    this.isError = false,
    this.selectedEventId,
  });

  ScanState copyWith({
    bool? isProcessing,
    String? lastResult,
    bool? isError,
    int? selectedEventId,
  }) {
    return ScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      lastResult: lastResult ?? this.lastResult,
      isError: isError ?? this.isError,
      selectedEventId: selectedEventId ?? this.selectedEventId,
    );
  }
}

class ScanNotifier extends Notifier<ScanState> {
  @override
  ScanState build() {
    return ScanState();
  }

  void setEvent(int eventId) {
    // print('━━━━━━━━━━━━━━━━━━━━ 🎯 EVENT SELECTED ━━━━━━━━━━━━━━━━━━━━');
    // print('🆔 ID EVENTO: $eventId');
    // print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    state = state.copyWith(selectedEventId: eventId);
  }

  Future<void> processUrl(String qrData) async {
    if (state.isProcessing) return;
    if (state.selectedEventId == null) {
      state = state.copyWith(
        lastResult: "Error: No se ha seleccionado un evento",
        isError: true,
      );
      return;
    }

    state = state.copyWith(
      isProcessing: true,
      isError: false,
      lastResult: null,
    );

    final authState = ref.read(authProvider);
    final token = authState.token;
    final eventId = state.selectedEventId;

    try {
      // Validamos que el QR sea un ID válido (no una URL externa)
      if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
        state = state.copyWith(
          isProcessing: false,
          lastResult: "Error: QR inválido. Escanea un código de ticket válido.",
          isError: true,
        );
        return;
      }

      // Extraemos el ID del ticket del QR (asumiendo que viene al final o es el dato puro)
      String ticketId = qrData;
      if (qrData.contains('/')) {
        ticketId = qrData.split('/').last;
      }

      // Validación adicional: el ticketId debe ser un UUID o string simple
      if (ticketId.isEmpty || ticketId.length < 10) {
        state = state.copyWith(
          isProcessing: false,
          lastResult: "Error: Código QR no válido.",
          isError: true,
        );
        return;
      }

      final String apiUrl =
          '${dotenv.env['API_BASE_URL']}/eventos/$eventId/validar-entrada/$ticketId';

      // print('━━━━━━━━━━━━━━━━━━━━ 🔍 SCAN POST START ━━━━━━━━━━━━━━━━━━━━');
      // print('📍 URL FINAL: $apiUrl');
      // print('🎫 TICKET ID: $ticketId');
      // print('📅 EVENTO ID: $eventId');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'x-client': 'mobile',
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 3));

      // print('📡 STATUS: ${response.statusCode}');
      // print('📦 RESPONSE: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          isProcessing: false,
          lastResult:
              responseData['mensaje'] ??
              responseData['message'] ??
              "¡Entrada Validada!",
          isError: false,
        );
      } else {
        // Manejo de errores específicos del backend (404, 409, etc.)
        String errorMsg = "Error (${response.statusCode})";
        if (responseData['error'] != null &&
            responseData['error']['mensaje'] != null) {
          errorMsg = responseData['error']['mensaje'];
        } else if (responseData['mensaje'] != null) {
          errorMsg = responseData['mensaje'];
        }

        state = state.copyWith(
          isProcessing: false,
          lastResult: errorMsg,
          isError: true,
        );
      }
      // print('━━━━━━━━━━━━━━━━━━━━ 🏁 SCAN END ━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      // print('❌ SCAN ERROR: $e');
      state = state.copyWith(
        isProcessing: false,
        lastResult: "Error: $e",
        isError: true,
      );
    }
  }

  void reset() {
    state = ScanState(selectedEventId: state.selectedEventId);
  }
}

final scanProvider = NotifierProvider<ScanNotifier, ScanState>(() {
  return ScanNotifier();
});
