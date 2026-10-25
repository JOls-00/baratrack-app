import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/documents_repository.dart';

class DocumentsProvider extends ChangeNotifier {
  final DocumentsRepository _repository;
  
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  String? _error;

  DocumentsProvider(this._repository);

  List<Map<String, dynamic>> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _documents = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchDocuments({int? residentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _repository.getDocuments(residentId: residentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> issueDocument({
    required int residentId,
    required String type,
    required PlatformFile file,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.issueDocument(
        residentId: residentId,
        type: type,
        file: file,
      );
      await fetchDocuments(residentId: residentId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
