import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Dio _pingClient;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;

  bool _isOnline = true;
  int _consecutiveSuccesses = 0;
  bool _isPinging = false;

  bool get isOnline => _isOnline;

  ConnectivityProvider({
    Dio? pingClient,
    Connectivity? connectivity,
  })  : _pingClient = pingClient ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                headers: {'Accept': 'application/json'},
              ),
            ),
        _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    // Initial check
    checkNow();

    // connectivity_plus only as a hint to trigger checks immediately
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none) && results.length == 1) {
        _consecutiveSuccesses = 0;
        if (_isOnline) {
          _isOnline = false;
          notifyListeners();
        }
      } else {
        checkNow();
      }
    });

    // Ping health.php every ~12s
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      _pingHealth();
    });
  }

  Future<void> checkNow() async {
    await _pingHealth();
  }

  Future<void> _pingHealth() async {
    if (_isPinging) return;
    _isPinging = true;

    try {
      final healthUrl = '${AppConstants.baseUrl}/health.php';
      final response = await _pingClient.get(healthUrl);

      final isOk = response.statusCode == 200 &&
          (response.data is Map ? response.data['status'] == 'ok' : true);

      if (isOk) {
        _consecutiveSuccesses++;
        if (_consecutiveSuccesses >= 2 && !_isOnline) {
          _isOnline = true;
          notifyListeners();
        }
      } else {
        _markOffline();
      }
    } catch (_) {
      _markOffline();
    } finally {
      _isPinging = false;
    }
  }

  void _markOffline() {
    _consecutiveSuccesses = 0;
    if (_isOnline) {
      _isOnline = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    _pingClient.close();
    super.dispose();
  }
}
