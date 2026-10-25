import 'package:flutter/material.dart';
import '../../data/models/case_model.dart';
import '../../data/repositories/complaint_repository.dart';

class ComplaintProvider extends ChangeNotifier {
  final ComplaintRepository _repository;
  
  List<ComplaintModel> _myComplaints = [];
  bool _isLoading = false;
  String? _error;

  ComplaintProvider(this._repository);

  List<ComplaintModel> get myComplaints => _myComplaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _myComplaints = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMyComplaints() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myComplaints = await _repository.getMyComplaints();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<IncidentPin>> loadIncidentPins({String? from, String? to}) => _repository.getIncidentMap(dateFrom: from, dateTo: to);

  Future<int> submitComplaint({
    required int complainantId,
    int? respondentId,
    required String category,
    required String location,
    required String date,
    required String time,
    required String details,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      int typeId = 1; 
      switch(category) {
        case 'Physical Injury': typeId = 1; break;
        case 'Theft/Robbery': typeId = 2; break;
        case 'Threats': typeId = 3; break;
        case 'Noise Complaint': typeId = 4; break;
        case 'Property Damage': typeId = 5; break;
      }

      final id = await _repository.fileComplaint({
        'complaint_type_id': typeId,
        'complainant_id': complainantId,
        'respondent_id': respondentId,
        'details': details,
        'location': location,
        if (latitude != null && longitude != null) 'latitude': latitude,
        if (latitude != null && longitude != null) 'longitude': longitude,
        'incident_date': date,
        'incident_time': time,
      });
      
      await fetchMyComplaints();
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
