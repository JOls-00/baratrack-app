import 'dart:convert';

class OfflineQueueItem {
  final String id;
  final String type; // 'complaint' | 'note' | 'hearing_outcome' | 'status_change'
  final Map<String, dynamic> payload;
  final List<String> evidencePaths;
  final int? ownerId;
  final String? ownerName;
  final DateTime deviceTime;
  final String state; // 'draft' | 'sending' | 'synced' | 'failed' | 'conflict'
  final String? lastError;
  final String? baseUpdatedAt;

  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    this.evidencePaths = const [],
    this.ownerId,
    this.ownerName,
    required this.deviceTime,
    this.state = 'draft',
    this.lastError,
    this.baseUpdatedAt,
  });

  OfflineQueueItem copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    List<String>? evidencePaths,
    int? ownerId,
    String? ownerName,
    DateTime? deviceTime,
    String? state,
    String? lastError,
    String? baseUpdatedAt,
  }) {
    return OfflineQueueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      evidencePaths: evidencePaths ?? this.evidencePaths,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      deviceTime: deviceTime ?? this.deviceTime,
      state: state ?? this.state,
      lastError: lastError ?? this.lastError,
      baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'evidencePaths': evidencePaths,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'deviceTime': deviceTime.toIso8601String(),
      'state': state,
      'lastError': lastError,
      'baseUpdatedAt': baseUpdatedAt,
    };
  }

  factory OfflineQueueItem.fromJson(Map<String, dynamic> map) {
    return OfflineQueueItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'complaint',
      payload: map['payload'] is Map ? Map<String, dynamic>.from(map['payload']) : {},
      evidencePaths: (map['evidencePaths'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      ownerId: map['ownerId'] is int ? map['ownerId'] as int : int.tryParse(map['ownerId']?.toString() ?? ''),
      ownerName: map['ownerName']?.toString(),
      deviceTime: map['deviceTime'] != null
          ? (DateTime.tryParse(map['deviceTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      state: map['state']?.toString() ?? 'draft',
      lastError: map['lastError']?.toString(),
      baseUpdatedAt: map['baseUpdatedAt']?.toString(),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
