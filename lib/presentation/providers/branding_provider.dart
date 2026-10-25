import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/branding_repository.dart';

/// Holds the barangay's profile (name, logo, colour, about, contact) and its officials.
class BrandingProvider with ChangeNotifier {
  final BrandingRepository _repository;
  BrandingProvider(this._repository);

  BrandingInfo _info = const BrandingInfo(
    name: 'Barangay Rosario',
    city: 'Santiago City',
    hasLogo: false,
    logoVersion: '0',
  );
  List<Official> _officials = [];

  BrandingInfo get info => _info;
  List<Official> get officials => _officials;

  Future<void> load() async {
    try {
      _info = await _repository.fetch();
      notifyListeners();
    } catch (_) {
      // Keep the defaults if the server can't be reached.
    }
    await loadOfficials();
  }

  Future<void> loadOfficials() async {
    try {
      _officials = await _repository.fetchOfficials();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> save(Map<String, String> fields, {PlatformFile? logo}) async {
    _info = await _repository.save(fields, logo: logo);
    notifyListeners();
  }

  Future<void> saveOfficial({
    int? id,
    required String name,
    required String position,
    required String group,
    required int sortOrder,
    PlatformFile? photo,
    bool removePhoto = false,
  }) async {
    await _repository.saveOfficial(
      id: id,
      name: name,
      position: position,
      group: group,
      sortOrder: sortOrder,
      photo: photo,
      removePhoto: removePhoto,
    );
    await loadOfficials();
  }

  Future<void> deleteOfficial(int id) async {
    await _repository.deleteOfficial(id);
    await loadOfficials();
  }
}
