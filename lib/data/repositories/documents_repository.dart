import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';

class DocumentsRepository {
  final ApiClient _apiClient;

  DocumentsRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getDocuments({int? residentId}) async {
    final response = await _apiClient.get('/documents.php', queryParameters: {
      if (residentId != null) 'resident_id': residentId,
    });
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<void> issueDocument({
    required int residentId,
    required String type,
    required PlatformFile file,
  }) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      if (file.bytes == null) throw Exception("File data is missing");
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      if (file.path == null) throw Exception("File path is missing");
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }

    final formData = FormData.fromMap({
      'resident_id': residentId,
      'type': type,
      'file': multipartFile,
    });

    await _apiClient.postMultipart('/documents.php', formData);
  }

  Future<void> deleteDocument(int id) async {
    await _apiClient.delete('/documents.php/$id');
  }

  Future<void> updateDocumentStatus(int id, String status) async {
    await _apiClient.put('/documents.php/$id', data: {'status': status});
  }
}
