import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isChecking;
  final String? token;
  final String? nombre;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isChecking = true,
    this.token,
    this.nombre,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isChecking,
    String? token,
    String? nombre,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isChecking: isChecking ?? this.isChecking,
      token: token ?? this.token,
      nombre: nombre ?? this.nombre,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _nombreKey = 'user_nombre';
  static const _url = 'https://50f7-190-152-93-126.ngrok-free.app/auth/login';

  @override
  AuthState build() {
    _init();
    return AuthState();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final nombre = prefs.getString(_nombreKey);

    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isChecking: false,
        token: token,
        nombre: nombre,
      );
    } else {
      state = state.copyWith(isAuthenticated: false, isChecking: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // print('━━━━━━━━━━━━━━━━━━━━ 🚀 LOGIN START ━━━━━━━━━━━━━━━━━━━━');
      // print('📍 URL: $_url');
      // print('👤 USER: $email');

      final response = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'x-client': 'mobile',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      // print('📡 STATUS: ${response.statusCode}');
      // print('📦 BODY: ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'];
        final token = data['token'];
        final nombre = data['nombre'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        if (nombre != null) await prefs.setString(_nombreKey, nombre);

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          token: token,
          nombre: nombre,
        );
        // print('✅ LOGIN SUCCESS: Bienvenido $nombre');
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              responseData['message'] ??
              "Error de autenticación (${response.statusCode})",
        );
        // print('⚠️ LOGIN FAILED: ${responseData['message']}');
      }
      // print('━━━━━━━━━━━━━━━━━━━━ 🏁 LOGIN END ━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      // print('❌ LOGIN ERROR: $e');
      state = state.copyWith(
        isLoading: false,
        error: "Error de conexión, por favor intente nuevamente",
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nombreKey);
    state = AuthState(isChecking: false);
    // print('🚪 SESSION CLOSED');
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
