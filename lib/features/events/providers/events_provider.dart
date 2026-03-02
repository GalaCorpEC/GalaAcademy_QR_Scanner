import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

class Event {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? fecha;
  final String? lugar;
  final String? imagen;

  Event({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fecha,
    this.lugar,
    this.imagen,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      nombre: json['nombre_evento']?.toString() ?? 'Evento sin nombre',
      descripcion: json['descripcion']?.toString(),
      fecha: json['fecha_inicio']?.toString(),
      lugar: json['lugar']?.toString(),
      imagen: json['imagen']?.toString(),
    );
  }
}

class EventsState {
  final bool isLoading;
  final List<Event> events;
  final String? error;

  EventsState({this.isLoading = false, this.events = const [], this.error});

  EventsState copyWith({bool? isLoading, List<Event>? events, String? error}) {
    return EventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      error: error,
    );
  }
}

class EventsNotifier extends Notifier<EventsState> {
  static const _url = 'https://50f7-190-152-93-126.ngrok-free.app/eventos';

  @override
  EventsState build() {
    return EventsState();
  }

  Future<void> fetchEvents() async {
    state = state.copyWith(isLoading: true, error: null);

    final authState = ref.read(authProvider);
    final token = authState.token;

    try {
      // print('━━━━━━━━━━━━━━━━━━━━ 📅 FETCH EVENTS START ━━━━━━━━━━━━━━━━━━━━');
      // print('📍 URL: $_url');

      final response = await http
          .get(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'x-client': 'mobile',
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 15));

      // print('📡 STATUS: ${response.statusCode}');
      // print('📦 RESPONSE: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = responseData['data'] ?? [];
        final eventsList = data.map((json) => Event.fromJson(json)).toList();

        state = state.copyWith(isLoading: false, events: eventsList);
        /*
        print(
          '✅ FETCH EVENTS SUCCESS: ${eventsList.length} eventos encontrados',
        );
        */
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              responseData['message'] ??
              "Error al cargar eventos (${response.statusCode})",
        );
      }
      // print('━━━━━━━━━━━━━━━━━━━━ 🏁 FETCH EVENTS END ━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      // print('❌ FETCH EVENTS ERROR: $e');
      // print('📚 STACKTRACE: $stackTrace');
      state = state.copyWith(isLoading: false, error: "Error: $e");
    }
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, EventsState>(() {
  return EventsNotifier();
});
