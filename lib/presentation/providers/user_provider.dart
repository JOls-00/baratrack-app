import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  UserProvider(this._repository);

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void reset() {
    _users = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchUsers({String? status, String? role}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers(status: status, role: role);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(int id, {String? currentStatusFilter}) async {
    try {
      await _repository.approveUser(id);
      await fetchUsers(status: currentStatusFilter);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectUser(int id, {String? currentStatusFilter}) async {
    try {
      await _repository.rejectUser(id);
      await fetchUsers(status: currentStatusFilter);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
