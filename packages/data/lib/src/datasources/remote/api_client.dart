import 'package:dio/dio.dart';
import 'dart:io';

class ApiClient {
  final Dio _dio;

  /// Default base URLs by platform:
  /// - Android Emulator: 10.0.2.2 (maps to host localhost)
  /// - iOS Simulator: localhost
  /// - Physical device: Use your machine's actual IP address
  static String get defaultBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? defaultBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Update base URL at runtime (useful for switching environments)
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — caller should handle refresh
    }
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = '''
Connection timeout. Please check:
1. Is the backend server running? (cd backend && npm run dev)
2. Are you using the correct IP address?
   - Android Emulator: 10.0.2.2
   - iOS Simulator: localhost
   - Physical device: Your machine's IP address
3. Is the port 3000 accessible?
        ''';
        break;
      case DioExceptionType.badResponse:
        errorMessage =
            'Server error: ${err.response?.statusMessage ?? 'Unknown'}';
        break;
      case DioExceptionType.connectionError:
        errorMessage = '''
Connection error. Please check:
1. Backend server is running on port 3000
2. No firewall is blocking the connection
3. Correct IP address is configured
        ''';
        break;
      default:
        errorMessage = err.message ?? 'Network error occurred';
    }

    // Wrap the error with a more descriptive message
    final enhancedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
      message: errorMessage,
    );

    handler.next(enhancedError);
  }
}
