import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/resident_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/router/app_router.dart';

enum AuthStatus { authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final ResidentRepository _residentRepository;
  final UserRepository _userRepository;

  UserModel? _user;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _error;
  String? _unverifiedEmail;

  final List<VoidCallback> _sessionResetCallbacks = [];
  void registerSessionReset(VoidCallback cb) { _sessionResetCallbacks.add(cb); }
  void _runSessionReset() { for (final cb in _sessionResetCallbacks) { cb(); } }

  AuthProvider(this._repository, this._residentRepository, this._userRepository) {
    _checkAuth();
  }

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  String? get unverifiedEmail => _unverifiedEmail;

  void _updateStatus(AuthStatus newStatus) {
    _status = newStatus;
    // Sync with router notifier
    AppRouter.authNotifier.value = newStatus;
    notifyListeners();
  }

  Future<void> _checkAuth() async {
    _user = await _repository.getCurrentUser();
    if (_user != null) {
      await _checkResidentLink();
      await refreshProfile(); // Load latest data on startup
    }
    _updateStatus(_user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated);
  }

  Future<void> _checkResidentLink() async {
    if (_user == null || _user?.role != 'Resident' || _user?.residentId != null) return;

    try {
      final resident = await _residentRepository.getResidentByUserId(_user!.id);
      if (resident != null) {
        _user = _user!.copyWith(residentId: resident.id);
        await _repository.saveUserLocally(_user!);
      }
    } catch (e) {
      debugPrint("Error checking resident link: $e");
    }
  }

  Future<bool> login(String loginInput, String password) async {
    _runSessionReset();
    _updateStatus(AuthStatus.authenticating);
    _error = null;
    _unverifiedEmail = null;

    try {
      _user = await _repository.login(loginInput, password);
      await _checkResidentLink();
      _updateStatus(AuthStatus.authenticated);
      return true;
    } on UnverifiedAccountException catch (e) {
      _error = e.message;
      _unverifiedEmail = e.email;
      _updateStatus(AuthStatus.unauthenticated);
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _unverifiedEmail = null;
      _updateStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<Map<String, dynamic>> socialConfig() => _repository.socialConfig();

  /// Resident quick sign-in (Google / Facebook). Returns false on failure; see [error].
  Future<bool> socialLogin(String provider, {String? accessToken, String? idToken}) async {
    _runSessionReset();
    _updateStatus(AuthStatus.authenticating);
    _error = null;
    _unverifiedEmail = null;
    try {
      _user = await _repository.socialLogin(provider, accessToken: accessToken, idToken: idToken);
      await _checkResidentLink();
      _updateStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _updateStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<void> setResidentId(int residentId) async {
    if (_user != null) {
      _user = _user!.copyWith(residentId: residentId);
      await _repository.saveUserLocally(_user!);
      notifyListeners();
    }
  }

  /// Gets a fresh security question. Does not touch AuthStatus.
  Future<Map<String, String>> fetchCaptcha() => _repository.fetchCaptcha();

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
    _updateStatus(AuthStatus.authenticating);
    _error = null;

    try {
      final res = await _repository.register(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        role: role,
        idNumber: idNumber,
        email: email,
        mobile: mobile,
        username: username,
        password: password,
        captchaId: captchaId,
        captchaAnswer: captchaAnswer,
        acceptedTerms: acceptedTerms,
      );

      if (res['otpRequired'] == true) {
        _updateStatus(AuthStatus.unauthenticated);
        return {
          'success': true,
          'otpRequired': true,
          'email': res['email'],
          'message': res['message'],
        };
      }

      if (res['isPending'] == true) {
        _updateStatus(AuthStatus.unauthenticated);
        return {
          'success': true,
          'isPending': true,
          'message': res['message'],
        };
      }

      _user = res['user'] as UserModel;
      _updateStatus(AuthStatus.authenticated);
      return {
        'success': true,
        'isPending': false,
        'otpRequired': false,
      };
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _updateStatus(AuthStatus.unauthenticated);
      return {
        'success': false,
        'error': _error,
      };
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    _updateStatus(AuthStatus.authenticating);
    _error = null;

    try {
      _user = await _repository.verifyOtp(email, code);
      await _checkResidentLink();
      _updateStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _updateStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<String> resendOtp(String email) async {
    try {
      return await _repository.resendOtp(email);
    } catch (e) {
      rethrow;
    }
  }

  // Password reset: deliberately does not touch AuthStatus, so the router
  // doesn't refresh (and rebuild the screen) while the user is mid-flow.
  Future<String> requestPasswordReset(String email) => _repository.requestPasswordReset(email);

  Future<void> verifyResetCode(String email, String code) =>
      _repository.verifyResetCode(email, code);

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      _repository.resetPassword(email, code, newPassword);

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _runSessionReset();
    _updateStatus(AuthStatus.unauthenticated);
  }

  /// Fetches the latest user data from the server
  Future<void> refreshProfile() async {
    if (_user == null) return;
    try {
      final updatedUser = await _userRepository.getUserDetails(_user!.id);
      // Merge with residentId which might not be in users table but is in local session
      _user = updatedUser.copyWith(residentId: _user!.residentId);
      await _repository.saveUserLocally(_user!);
      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing profile: $e");
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? contact,
    String? address,
    DateTime? birthDate,
  }) async {
    if (_user == null) return;

    try {
      final updatedUser = await _userRepository.updateProfile(_user!.id, {
        'name': name,
        'email': email,
        'contact_number': contact,
        'address': address,
        'birth_date': birthDate?.toIso8601String(),
      });

      // Merge with existing residentId
      _user = updatedUser.copyWith(residentId: _user!.residentId);
      await _repository.saveUserLocally(_user!);
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating profile: $e");
      rethrow;
    }
  }
}
