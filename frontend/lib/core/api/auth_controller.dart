import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import 'auth_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

/// Holds the current admin JWT (null when logged out) and whether the
/// stored token has finished loading from persistent storage yet.
class AuthState {
  final String? token;
  final bool loading;

  const AuthState({this.token, this.loading = true});

  bool get isLoggedIn => token != null;

  AuthState copyWith({String? token, bool? loading}) =>
      AuthState(token: token ?? this.token, loading: loading ?? this.loading);
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState(loading: true);
  }

  Future<void> _restore() async {
    final token = await ref.read(authStorageProvider).readToken();
    state = AuthState(token: token, loading: false);
  }

  Future<void> login(String email, String password) async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    await ref.read(authStorageProvider).writeToken(token);
    state = state.copyWith(token: token, loading: false);
  }

  Future<void> logout() async {
    await ref.read(authStorageProvider).clearToken();
    state = const AuthState(token: null, loading: false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// A Dio instance that automatically attaches the admin bearer token (if any)
/// and logs the admin out on a 401 response from the API.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(authControllerProvider).token;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        ref.read(authControllerProvider.notifier).logout();
      }
      handler.next(error);
    },
  ));

  return dio;
});
