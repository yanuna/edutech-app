import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../utils/storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor());
    // Network logging is dev-only — it never runs in release builds, so no
    // request/response metadata is written to production logs.
    if (kDebugMode) {
      _dio.interceptors.add(
        // requestHeader:false so the `Authorization: Bearer <token>` header is
        // never printed to the console.
        LogInterceptor(
          requestHeader: false,
          responseBody: false,
          requestBody: false,
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  /// Invoked when an authenticated request gets a 401 (token revoked by the
  /// single-device policy, or expired). Wired in app.dart to reset auth state
  /// so the router redirects to /login.
  static void Function()? onUnauthorized;

  Dio get dio => _dio;

  // ─── Convenience wrappers ──────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postForm(String path, FormData form) =>
      _dio.post(path, data: form);
}

class _AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AppStorage.instance.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // A 401 on a request that DID carry a token means the token is no longer
    // valid (the backend revokes other devices' tokens on login). Clear it and
    // signal the app to return to the login screen. Requests without a token
    // (e.g. a failed login attempt) are left alone.
    final hadToken = err.requestOptions.headers.containsKey('Authorization');
    if (err.response?.statusCode == 401 && hadToken) {
      await AppStorage.instance.clearAll();
      ApiClient.onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Parse DioException into a human-readable message.
String apiErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      if (data['errors'] != null) {
        final errors = data['errors'] as Map;
        return errors.values.first is List
            ? (errors.values.first as List).first.toString()
            : errors.values.first.toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return e.toString();
}
