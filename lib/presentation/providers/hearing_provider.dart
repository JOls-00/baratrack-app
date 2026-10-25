import 'package:flutter/material.dart';
import '../../data/models/hearing_model.dart';
import '../../data/repositories/hearing_repository.dart';

class HearingProvider extends ChangeNotifier {
  final HearingRepository _repository;
  
  List<HearingModel> _hearings = [];
  bool _isLoading = false;
  String? _error;

  HearingProvider(this._repository);

  List<HearingModel> get hearings => _hearings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _hearings = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchHearings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _hearings = await _repository.getHearings(status: status);
      // Sort by date ascending
      _hearings.sort((a, b) => a.hearingDate.compareTo(b.hearingDate));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> scheduleHearing(Map<String, dynamic> data) async {
    try {
      await _repository.scheduleHearing(data);
      await fetchHearings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHearing(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateHearing(id, data);
      await fetchHearings();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
