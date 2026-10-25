import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/evidence_repository.dart';

class EvidenceProvider extends ChangeNotifier {
  final EvidenceRepository _repository;
  bool _isLoading = false;
  String? _error;

  EvidenceProvider(this._repository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> uploadEvidence({
    int? caseId,
    int? complaintId,
    required PlatformFile file,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.uploadEvidence(
        caseId: caseId,
        complaintId: complaintId,
        file: file,
        description: description,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getEvidenceForComplaint(int complaintId) {
    return _repository.getEvidenceForComplaint(complaintId);
  }

  Future<List<Map<String, dynamic>>> getEvidenceForCase(int caseId) {
    return _repository.getEvidenceForCase(caseId);
  }
}
