import 'package:flutter/material.dart';
import '../../data/models/resident_model.dart';
import '../../data/repositories/resident_repository.dart';

class ResidentProvider extends ChangeNotifier {
  final ResidentRepository _repository;
  
  List<ResidentModel> _residents = [];
  bool _isLoading = false;
  String? _error;

  ResidentProvider(this._repository);

  List<ResidentModel> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _residents = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchResidents({String? query, String? zone, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _residents = await _repository.getResidents(query: query, zone: zone, status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Minimal name lookup used when a resident picks who they are filing a
  /// complaint against. The server only returns id, name and zone for this,
  /// and it doesn't touch the shared [residents] list.
  Future<List<ResidentModel>> searchRespondents(String query) {
    return _repository.getResidents(query: query);
  }

  Future<void> createResident(Map<String, dynamic> data) async {
    try {
      await _repository.createResident(data);
      await fetchResidents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateResident(int id, Map<String, dynamic> data) async {
    try {
      await _repository.updateResident(id, data);
      await fetchResidents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteResident(int id) async {
    try {
      await _repository.deleteResident(id);
      await fetchResidents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
