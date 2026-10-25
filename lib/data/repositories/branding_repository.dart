import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';

/// Barangay profile shown across the app: name, logo, theme colour, about and contact info.
class BrandingInfo {
  final String name;
  final String city;
  final bool hasLogo;
  final String logoVersion;
  final String primaryHex;
  final String about;
  final String history;
  final String slogan;
  final String album;
  final String mission;
  final String vision;
  final String address;
  final String phone;
  final String email;
  final String officeHours;

  const BrandingInfo({
    required this.name,
    required this.city,
    required this.hasLogo,
    required this.logoVersion,
    this.primaryHex = '#D61314',
    this.about = '',
    this.history = '',
    this.slogan = '',
    this.album = '',
    this.mission = '',
    this.vision = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.officeHours = '',
  });

  /// Photo links for the Album page: one http(s) link per line.
  List<String> get albumUrls =>
      album.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.startsWith('http')).toList();

  /// The admin-chosen theme colour (falls back to the seal's red).
  Color get primary {
    final h = primaryHex.replaceAll('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return Color(v ?? 0xFFD61314);
  }
}

class Official {
  final int id;
  final String name;
  final String position;
  final String group; // captain | council | sk | staff
  final int sortOrder;
  final bool hasPhoto;
  final int photoVersion;

  const Official({
    required this.id,
    required this.name,
    required this.position,
    required this.group,
    required this.sortOrder,
    required this.hasPhoto,
    required this.photoVersion,
  });

  String get photoUrl => '${AppConstants.baseUrl}/public/official_photo.php?id=$id&v=$photoVersion';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class BrandingRepository {
  final ApiClient _apiClient;
  BrandingRepository(this._apiClient);

  static const _publicOfficials = '/public/officials.php';
  static const _adminOfficials = '/officials.php';

  BrandingInfo _parse(Map<String, dynamic> d) => BrandingInfo(
        name: d['barangay_name']?.toString() ?? 'Barangay',
        city: d['city_name']?.toString() ?? '',
        hasLogo: d['has_logo'] == true,
        logoVersion: d['logo_version']?.toString() ?? '1',
        primaryHex: d['primary_color']?.toString() ?? '#D61314',
        about: d['about_text']?.toString() ?? '',
        history: d['history']?.toString() ?? '',
        slogan: d['slogan']?.toString() ?? '',
        album: d['album']?.toString() ?? '',
        mission: d['mission']?.toString() ?? '',
        vision: d['vision']?.toString() ?? '',
        address: d['address']?.toString() ?? '',
        phone: d['contact_phone']?.toString() ?? '',
        email: d['contact_email']?.toString() ?? '',
        officeHours: d['office_hours']?.toString() ?? '',
      );

  String _error(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return fallback;
  }

  Future<MultipartFile> _file(PlatformFile f) async {
    if (f.bytes != null) return MultipartFile.fromBytes(f.bytes!, filename: f.name);
    if (f.path != null) return MultipartFile.fromFile(f.path!, filename: f.name);
    throw Exception('The selected image could not be read.');
  }

  Future<BrandingInfo> fetch() async {
    final response = await _apiClient.get(AppConstants.publicBranding);
    return _parse(response.data['data'] as Map<String, dynamic>);
  }

  /// Admin only. [fields] uses the server's field names (barangay_name, primary_color, about_text, ...).
  Future<BrandingInfo> save(Map<String, String> fields, {PlatformFile? logo}) async {
    final map = <String, dynamic>{...fields};
    if (logo != null) map['logo'] = await _file(logo);
    try {
      final response = await _apiClient.postMultipart(AppConstants.adminBranding, FormData.fromMap(map));
      return _parse(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_error(e, 'Could not save. Please check your connection and try again.'));
    }
  }

  Future<List<Official>> fetchOfficials() async {
    final response = await _apiClient.get(_publicOfficials);
    final list = (response.data['data'] as List?) ?? [];
    return list.map((o) {
      final m = o as Map<String, dynamic>;
      return Official(
        id: (m['id'] as num).toInt(),
        name: m['name']?.toString() ?? '',
        position: m['position']?.toString() ?? '',
        group: m['group']?.toString() ?? 'council',
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
        hasPhoto: m['has_photo'] == true,
        photoVersion: (m['photo_version'] as num?)?.toInt() ?? 0,
      );
    }).toList();
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
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'position': position,
      'role_group': group,
      'sort_order': sortOrder,
      if (removePhoto) 'remove_photo': '1',
    };
    if (photo != null) map['photo'] = await _file(photo);
    try {
      await _apiClient.postMultipart(_adminOfficials, FormData.fromMap(map));
    } on DioException catch (e) {
      throw Exception(_error(e, 'Could not save the official.'));
    }
  }

  Future<void> deleteOfficial(int id) async {
    try {
      await _apiClient.postMultipart(_adminOfficials, FormData.fromMap({'action': 'delete', 'id': id}));
    } on DioException catch (e) {
      throw Exception(_error(e, 'Could not delete the official.'));
    }
  }
}
