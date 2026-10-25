import 'package:flutter/material.dart';
import '../../data/repositories/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final ReportsRepository _repository;
  
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;
  String? _error;

  ReportsProvider(this._repository);

  Map<String, dynamic>? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _reportData = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reportData = await _repository.getReports();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
