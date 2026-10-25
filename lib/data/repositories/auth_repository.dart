import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UnverifiedAccountException implements Exception {
  final String message;
  final String code;
  final String email;

  UnverifiedAccountException({
    required this.message,
    required this.code,
    required this.email,
  });

  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<UserModel> login(String loginInput, String password) async {
    try {
      final response = await _apiClient.post(AppConstants.login, data: {
        'email': loginInput,
        'username': loginInput,
        'password': password,
      });

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['code'] == 'unverified' && data['email'] != null) {
        throw UnverifiedAccountException(
          message: data['message']?.toString() ?? 'Please verify your email before signing in.',
          code: 'unverified',
          email: data['email'].toString(),
        );
      }
      final msg = data is Map && data['message'] != null
          ? data['message'].toString()
          : e.message ?? 'Login failed';
      throw Exception(msg);
    }
  }

  /// Which quick sign-in buttons the server has set up (Google / Facebook).
  Future<Map<String, dynamic>> socialConfig() async {
    final r = await _apiClient.get(AppConstants.socialConfig);
    return Map<String, dynamic>.from(r.data as Map);
  }

  Future<UserModel> socialLogin(String provider, {String? accessToken, String? idToken}) async {
    try {
      final response = await _apiClient.post(AppConstants.socialLogin, data: {
        'provider': provider,
        if (accessToken != null) 'access_token': accessToken,
        if (idToken != null) 'id_token': idToken,
      });
      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(data is Map && data['message'] != null ? data['message'].toString() : e.message ?? 'Quick sign-in failed');
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String role,
    String? idNumber,
    required String email,
    required String mobile,
    required String username,
    required String password,
    required String captchaId,
    required String captchaAnswer,
    required bool acceptedTerms,
  }) async {
    try {
      final response = await _apiClient.post(AppConstants.register, data: {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'role': role,
        'id_number': idNumber,
        'email': email,
        'mobile': mobile,
        'username': username,
        'password': password,
        'captcha_id': captchaId,
        'captcha_answer': captchaAnswer,
        'accepted_terms': acceptedTerms,
      });

      final data = response.data;
      if (data['status'] == 'otp_required') {
        return {
          'isPending': false,
          'otpRequired': true,
          'email': data['email'] ?? email,
          'message': data['message'] ?? 'Enter the 6-digit code sent to your email.',
        };
      }

      if (data['status'] == 'pending') {
        return {
          'isPending': true,
          'otpRequired': false,
          'message': data['message'] ?? 'Your account is awaiting administrator approval.',
        };
      }

      final user = await _handleAuthResponse(data);
      return {
        'isPending': false,
        'otpRequired': false,
        'user': user,
      };
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Registration failed';
      throw Exception(msg);
    }
  }

  Future<UserModel> verifyOtp(String email, String code) async {
    try {
      final response = await _apiClient.post(AppConstants.verifyOtp, data: {
        'email': email,
        'code': code,
      });

      return _handleAuthResponse(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Verification failed';
      throw Exception(msg);
    }
  }

  Future<String> resendOtp(String email) async {
    try {
      final response = await _apiClient.post(AppConstants.sendOtp, data: {
        'email': email,
      });

      return response.data['message']?.toString() ?? 'A new verification code has been sent.';
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Failed to resend verification code';
      throw Exception(msg);
    }
  }

  /// Fetches a one-time arithmetic security question for the registration form.
  Future<Map<String, String>> fetchCaptcha() async {
    try {
      final response = await _apiClient.get(AppConstants.captcha);
      final d = response.data;
      return {
        'captcha_id': d['captcha_id'].toString(),
        'question': d['question'].toString(),
      };
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Could not load the security check. Please try again.'));
    }
  }

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return e.message ?? fallback;
  }

  /// Step 1 of password reset: emails a 6-digit code (response is intentionally generic).
  Future<String> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.post(AppConstants.forgotPassword, data: {
        'email': email,
      });
      return response.data['message']?.toString() ??
          'If an account exists for this email, a reset code has been sent.';
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to send reset code'));
    }
  }

  /// Step 2: checks the code without consuming it. Throws on a wrong/expired code.
  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _apiClient.post(AppConstants.verifyResetOtp, data: {
        'email': email,
        'code': code,
      });
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Verification failed'));
    }
  }

  /// Step 3: consumes the code and sets the new password.
  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _apiClient.post(AppConstants.resetPassword, data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      return response.data['message']?.toString() ?? 'Your password has been reset.';
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Password reset failed'));
    }
  }

  Future<UserModel> _handleAuthResponse(Map<String, dynamic> data) async {
    final String token = data['token'];
    final Map<String, dynamic> userData = data['user'];

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await _storage.write(key: AppConstants.userDataKey, value: jsonEncode(userData));

    return UserModel.fromJson(userData);
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userDataKey);
  }

  Future<UserModel?> getCurrentUser() async {
    final data = await _storage.read(key: AppConstants.userDataKey);
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> saveUserLocally(UserModel user) async {
    await _storage.write(key: AppConstants.userDataKey, value: jsonEncode(user.toJson()));
  }
}
