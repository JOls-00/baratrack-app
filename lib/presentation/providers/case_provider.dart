import 'package:flutter/material.dart';
import '../../data/models/case_model.dart';
import '../../data/repositories/case_repository.dart';

class CaseProvider extends ChangeNotifier {
  final CaseRepository _repository;
  
  List<CaseModel> _cases = [];
  bool _isLoading = false;
  String? _error;

  CaseProvider(this._repository);

  List<CaseModel> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _cases = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchCases({String? query, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cases = await _repository.getCases(query: query, status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<CaseModel> fetchCaseDetails(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final detail = await _repository.getCaseDetails(id);
      
      // Update the item in the local list if it exists
      final index = _cases.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cases[index] = detail;
      } else {
        _cases.add(detail);
      }
      
      return detail;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> convertToCase(int complaintId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createCaseFromComplaint(complaintId);
      await fetchCases();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(int caseId, String status, String remarks) async {
    try {
      await _repository.updateCaseStatus(caseId, status, remarks);
      await fetchCaseDetails(caseId); // Refresh only this case
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
