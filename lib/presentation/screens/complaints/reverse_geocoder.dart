import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:latlong2/latlong.dart';

/// Turns a map point into a short, readable address using OpenStreetMap's Nominatim.
/// Uses its own Dio on purpose: the BaraTrack login token must never be sent to a third party.
class ReverseGeocoder {
  static final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));

  /// e.g. "Maharlika Highway, Rosario, Santiago City". Returns null when nothing was found.
  static Future<String?> lookup(LatLng p) async {
    final res = await _dio.get(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {'format': 'jsonv2', 'lat': p.latitude, 'lon': p.longitude, 'zoom': 18, 'addressdetails': 1},
      // Browsers set their own User-Agent; apps should identify themselves (Nominatim usage policy).
      options: Options(headers: {'Accept-Language': 'en', if (!kIsWeb) 'User-Agent': 'BaraTrack/1.0'}),
    );
    final data = res.data;
    if (data is! Map) return null;
    final a = data['address'];
    if (a is Map) {
      String? pick(List<String> keys) {
        for (final k in keys) {
          final v = a[k];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;
      }

      final parts = <String>[];
      void add(String? v) {
        if (v != null && !parts.contains(v)) parts.add(v);
      }

      add(pick(['road', 'pedestrian', 'path', 'footway']));
      add(pick(['neighbourhood', 'quarter', 'hamlet', 'suburb', 'village']));
      add(pick(['city', 'town', 'municipality', 'county']));
      if (parts.isNotEmpty) return parts.join(', ');
    }
    final name = data['display_name'];
    if (name is String && name.isNotEmpty) return name.split(',').take(3).map((e) => e.trim()).join(', ');
    return null;
  }
}
