import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_constants.dart';
import '../router/app_router.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // QUICK FIX: Set this to true for offline UI testing without a backend
  static const bool useMockApi = false;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add Auth Token Interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        final data = e.response?.data;
        String friendly;
        if (data is Map && data['message'] is String) {
          friendly = data['message'] as String; // the server's own explanation
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          friendly = 'The server is taking too long to answer. It may be waking up, so please try again in a minute.';
        } else if (e.type == DioExceptionType.connectionError) {
          friendly = 'Cannot reach the server. Please check your internet connection.';
          AppRouter.promptOfflineMode();
        } else {
          friendly = 'Something went wrong (${e.response?.statusCode ?? 'no response'}). Please try again.';
        }
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: e.error,
          message: friendly,
        ));
      },
    ));

    // QUICK FIX: Add Mock Interceptor for Offline Mode
    if (useMockApi) {
      _dio.interceptors.add(MockInterceptor());
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  Future<Response> postMultipart(String path, FormData formData) async {
    return await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}

/// A dedicated Interceptor to simulate server responses for offline testing
class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final path = options.path;

    // Define mock data for different endpoints
    Map<String, dynamic> mockData = {
      'status': 'success',
      'message': 'Mock Response: Operation Successful!',
    };

    if (path.contains(AppConstants.login) || path.contains(AppConstants.register)) {
      final email = options.data is Map ? options.data['email'] : '';
      
      if (email == 'Resident@gmail.com') {
        mockData = {
          'token': 'mock_resident_token_456',
          'user': {
            'id': 101,
            'name': 'Juan Dela Cruz',
            'email': 'Resident@gmail.com',
            'role': 'Resident',
            'status': 'Active',
          },
        };
      } else {
        mockData = {
          'token': 'mock_jwt_token_xyz_123',
          'user': {
            'id': 1,
            'name': 'System Administrator',
            'email': 'Admin@gmail.com',
            'role': 'Admin',
            'status': 'Active',
          },
        };
      }
    }

    // Intercept the request and return the mock response instead of calling the server
    return handler.resolve(
      Response(
        requestOptions: options,
        data: mockData,
        statusCode: 200,
      ),
    );
  }
}
