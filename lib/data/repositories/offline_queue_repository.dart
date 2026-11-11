import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_queue_item.dart';

class OfflineQueueRepository extends ChangeNotifier {
  static const String _storageKey = 'offline_drafts_v2';
  static const String _legacyKey = 'complaint_offline_draft';
  final _uuid = const Uuid();

  final List<OfflineQueueItem> _items = [];
  bool _initialized = false;

  List<OfflineQueueItem> get items => List.unmodifiable(_items);

  int get draftCount => _items.where((i) => i.state == 'draft' || i.state == 'failed').length;

  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Check and migrate legacy draft once
    if (prefs.containsKey(_legacyKey)) {
      try {
        final legacyStr = prefs.getString(_legacyKey);
        if (legacyStr != null && legacyStr.isNotEmpty) {
          final decoded = jsonDecode(legacyStr);
          if (decoded is Map<String, dynamic>) {
            final migratedItem = OfflineQueueItem(
              id: _uuid.v4(),
              type: 'complaint',
              payload: decoded,
              deviceTime: DateTime.now(),
              state: 'draft',
            );
            _items.add(migratedItem);
          }
        }
      } catch (e) {
        debugPrint('[OfflineQueueRepository] Legacy migration error: $e');
      } finally {
        await prefs.remove(_legacyKey);
      }
    }

    // 2. Load v2 items
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final entry in list) {
            if (entry is Map<String, dynamic>) {
              // Avoid duplicates if legacy was appended
              final item = OfflineQueueItem.fromJson(entry);
              if (!_items.any((existing) => existing.id == item.id)) {
                _items.add(item);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[OfflineQueueRepository] Load error: $e');
      }
    }

    // Sort newest first
    _items.sort((a, b) => b.deviceTime.compareTo(a.deviceTime));
    _initialized = true;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((i) => i.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<OfflineQueueItem>> getAll({int? ownerId}) async {
    await initialize();
    if (ownerId == null) return List.unmodifiable(_items);
    return _items.where((i) => i.ownerId == null || i.ownerId == ownerId).toList();
  }

  Future<OfflineQueueItem?> getById(String id) async {
    await initialize();
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(OfflineQueueItem item) async {
    await initialize();
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.insert(0, item);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> updateState(String id, String state, {String? error}) async {
    await initialize();
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(state: state, lastError: error);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    await initialize();
    final item = _items.where((i) => i.id == id).firstOrNull;
    if (item != null) {
      // Clean up copied evidence files if possible
      for (final path in item.evidencePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      _items.removeWhere((i) => i.id == id);
      await _persist();
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await initialize();
    for (final item in _items) {
      for (final path in item.evidencePaths) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  Future<String> copyEvidenceToAppDir(String sourcePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${appDir.path}/offline_evidence');
      if (!await evidenceDir.exists()) {
        await evidenceDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split(Platform.pathSeparator).last}';
      final targetPath = '${evidenceDir.path}/$fileName';
      final sourceFile = File(sourcePath);
      final copied = await sourceFile.copy(targetPath);
      return copied.path;
    } catch (e) {
      debugPrint('[OfflineQueueRepository] Copy evidence error: $e');
      return sourcePath;
    }
  }

  String newUuid() => _uuid.v4();
}
