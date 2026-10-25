import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'BaraTrack';
  
  // The API address is set at build time, never hard-coded:
  //   flutter run   --dart-define=API_BASE_URL=http://10.0.2.2/barangay_api      (Android emulator + XAMPP)
  //   flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API.onrender.com
  // Release builds must use HTTPS. If no value is given, debug builds fall back to local XAMPP.
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl.endsWith('/') ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1) : _apiBaseUrl;
    }
    if (kDebugMode) {
      return kIsWeb ? 'http://127.0.0.1/barangay_api' : 'http://10.0.2.2/barangay_api';
    }
    throw StateError('API_BASE_URL was not set. Build with --dart-define=API_BASE_URL=https://your-api-host');
  }

  // Endpoints
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';
  static const String socialLogin = '/auth/social-login.php';
  static const String socialConfig = '/auth/social-config.php';
  static const String captcha = '/auth/captcha.php';
  static const String verifyOtp = '/auth/verify-otp.php';
  static const String sendOtp = '/auth/send-otp.php';
  static const String forgotPassword = '/auth/forgot-password.php';
  static const String verifyResetOtp = '/auth/verify-reset-otp.php';
  static const String resetPassword = '/auth/reset-password.php';
  // Public portal (no login)
  static const String publicFaqs = '/public/faqs.php';
  static const String publicAnnouncements = '/public/announcements.php';
  static const String publicTrack = '/public/track.php';
  static const String publicChat = '/public/chat.php';
  static const String publicBranding = '/public/branding.php';
  static const String adminBranding = '/branding.php';
  static const String adminAnnouncements = '/announcements.php';
  static const String adminFaqs = '/faqs.php';
  static const String notifications = '/notifications.php';
  static String get logoUrl => '$baseUrl/public/logo.php';
  static const String residents = '/residents.php';
  static const String complaints = '/complaints.php';
  static const String incidentMap = '/incident-map.php';
  static const String cases = '/cases.php';
  static const String hearings = '/hearings.php';
  static const String evidence = '/evidence.php';
  
  // Shared Pref Keys
  static const String tokenKey = 'jwt_token';
  static const String userDataKey = 'user_data';
}
