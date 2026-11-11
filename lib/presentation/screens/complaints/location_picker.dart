import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_layers.dart';
import 'reverse_geocoder.dart';

/// Starting view of every map (Santiago City). Only used before a pin exists.
const defaultMapCenter = LatLng(16.688, 121.548);

enum _LocMode { gps, pin, address }

/// Lets a resident say where the incident happened:
///  - use my current location (GPS, only if they allow it),
///  - pin the exact spot on the map (best when it happened somewhere else),
///  - or skip the pin and just type the address in the form.
/// Sharing location is never required to file a complaint.
class LocationPicker extends StatefulWidget {
  final LatLng? value;
  final ValueChanged<LatLng?> onChanged;

  /// Called with a readable address once the pin lands somewhere (so the form can fill itself in).
  final ValueChanged<String>? onAddress;
  const LocationPicker({super.key, required this.value, required this.onChanged, this.onAddress});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _map = MapController();
  _LocMode _mode = _LocMode.pin;
  BaseMapKind _style = BaseMapKind.satellite;
  bool _locating = false;
  String? _msg;
  String? _geoNote;
  Timer? _geoTimer;
  int _geoSeq = 0;

  @override
  void dispose() {
    _geoTimer?.cancel();
    super.dispose();
  }

  /// Looks up the address a moment after the pin stops moving (keeps within Nominatim's rate limit).
  void _scheduleLookup(LatLng p) {
    if (widget.onAddress == null) return;
    _geoTimer?.cancel();
    final seq = ++_geoSeq;
    setState(() => _geoNote = 'Hinahanap ang address…');
    _geoTimer = Timer(const Duration(milliseconds: 700), () async {
      String? a;
      try {
        a = await ReverseGeocoder.lookup(p);
      } catch (_) {}
      if (!mounted || seq != _geoSeq) return;
      if (a != null) {
        widget.onAddress!(a);
        setState(() => _geoNote = 'Napunan na ang Place of Incident. Puwede mo itong baguhin o dagdagan ng purok at landmark.');
      } else {
        setState(() => _geoNote = 'Hindi makuha ang address. I-type na lang sa "Place of Incident".');
      }
    });
  }

  Future<void> _useGps() async {
    setState(() {
      _locating = true;
      _msg = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fail('Naka-off ang location ng device mo. Puwede mong i-pin sa mapa o i-type ang address.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _fail('Hindi pinayagan ang location. Okay lang iyon: i-pin sa mapa o i-type ang address.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      final p = LatLng(pos.latitude, pos.longitude);
      widget.onChanged(p);
      _scheduleLookup(p);
      _map.move(p, 17);
      if (mounted) {
        setState(() {
          _mode = _LocMode.pin;
          _msg = 'Nakuha ang kinalalagyan mo. Kung ibang lugar ang pinangyarihan, i-tap ang mapa para ilipat ang pin.';
        });
      }
    } catch (_) {
      _fail('Hindi makuha ang location. I-pin sa mapa o i-type ang address.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _fail(String m) {
    if (mounted) {
      setState(() {
        _msg = m;
        _locating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final point = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_LocMode>(
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: const [
            ButtonSegment(value: _LocMode.gps, icon: Icon(Icons.my_location, size: 16), label: Text('GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ButtonSegment(value: _LocMode.pin, icon: Icon(Icons.push_pin_outlined, size: 16), label: Text('Pin Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ButtonSegment(value: _LocMode.address, icon: Icon(Icons.edit_location_alt_outlined, size: 16), label: Text('Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          selected: {_mode},
          onSelectionChanged: (s) {
            final m = s.first;
            if (m == _LocMode.gps) {
              _useGps();
            } else {
              setState(() {
                _mode = m;
                _msg = null;
              });
              if (m == _LocMode.address) widget.onChanged(null); // address only, no pin
            }
          },
        ),
        const SizedBox(height: 10),
        if (_mode == _LocMode.address)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
            child: const Text('Walang pin. Ilagay ang address sa "Place of Incident" sa itaas. Puwede mo pa ring i-pin sa mapa anumang oras.'),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: point ?? defaultMapCenter,
                      initialZoom: point == null ? 14 : 17,
                      maxZoom: 19,
                      onTap: (_, p) {
                        widget.onChanged(p);
                        _scheduleLookup(p);
                      },
                    ),
                    children: [
                      ...baseMapLayers(_style),
                      if (point != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: point,
                            width: 48,
                            height: 56,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.location_on, size: 48, color: primary, shadows: const [Shadow(color: Colors.black87, blurRadius: 8)]),
                          ),
                        ]),
                    ],
                  ),
                  Positioned(left: 10, top: 10, child: MapStyleToggle(value: _style, onChanged: (k) => setState(() => _style = k))),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      elevation: 3,
                      shape: const CircleBorder(),
                      color: Theme.of(context).colorScheme.surface,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _locating ? null : _useGps,
                        child: Tooltip(
                          message: 'Gamitin ang kasalukuyang lokasyon',
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: _locating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                                  )
                                : Icon(Icons.my_location, size: 20, color: primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  point == null
                      ? 'I-tap ang mapa para ilagay ang pin sa pinangyarihan.'
                      : 'Lat ${point.latitude.toStringAsFixed(5)} · Lng ${point.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ),
              if (point != null)
                TextButton(
                  onPressed: () {
                    _geoSeq++;
                    _geoTimer?.cancel();
                    widget.onChanged(null);
                    setState(() => _geoNote = null);
                  },
                  child: const Text('Clear pin'),
                ),
            ],
          ),
          if (_geoNote != null) Text(_geoNote!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
        ],
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_msg!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          ),
      ],
    );
  }
}
