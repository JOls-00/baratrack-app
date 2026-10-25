import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../data/models/case_model.dart';
import '../../providers/complaint_provider.dart';
import '../complaints/location_picker.dart' show defaultMapCenter;
import '../complaints/map_layers.dart';

Color incidentStatusColor(String status) {
  switch (status) {
    case 'Pending':
      return const Color(0xFFD01418);
    case 'Reviewed':
      return const Color(0xFFF59A2B);
    case 'Converted to Case':
      return const Color(0xFF3B6FD0);
    case 'Dismissed':
      return const Color(0xFF8A8A8A);
    default:
      return const Color(0xFF1F8A4C);
  }
}

/// Staff and admin only: where complaints were reported, with filters.
class IncidentMapScreen extends StatefulWidget {
  const IncidentMapScreen({super.key});

  @override
  State<IncidentMapScreen> createState() => _IncidentMapScreenState();
}

class _IncidentMapScreenState extends State<IncidentMapScreen> {
  static const _statuses = ['Pending', 'Reviewed', 'Converted to Case', 'Dismissed'];
  final _ymd = DateFormat('yyyy-MM-dd');
  final _pretty = DateFormat('MMM d, yyyy');

  DateTimeRange _range = DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now());
  List<IncidentPin> _all = [];
  bool _loading = true;
  String? _error;
  String? _category;
  String? _status;
  IncidentPin? _selected;
  BaseMapKind _style = BaseMapKind.satellite;
  bool _labels = true; // incident type above each pin
  bool _names = true; // complainant name in the label

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final pins = await context.read<ComplaintProvider>().loadIncidentPins(from: _ymd.format(_range.start), to: _ymd.format(_range.end));
      if (mounted) setState(() => _all = pins);
    } catch (e) {
      if (mounted) setState(() => _error = 'Hindi ma-load ang mapa. Subukan ulit.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _range,
    );
    if (r != null) {
      setState(() => _range = r);
      _load();
    }
  }

  List<IncidentPin> get _shown =>
      _all.where((p) => (_category == null || p.typeName == _category) && (_status == null || p.status == _status)).toList();

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final categories = _all.map((p) => p.typeName).toSet().toList()..sort();
    final primary = Theme.of(context).colorScheme.primary;
    final pts = shown.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Incident Map', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Saan naiulat ang mga reklamo. Staff lamang ang nakakakita nito.', style: TextStyle(color: Colors.grey.shade700)),
                ]),
              ),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text('${_pretty.format(_range.start)} – ${_pretty.format(_range.end)}'),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            ChoiceChip(label: const Text('All categories'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
            for (final c in categories)
              ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = _category == c ? null : c)),
            const SizedBox(width: 12),
            for (final s in _statuses)
              FilterChip(
                avatar: CircleAvatar(radius: 5, backgroundColor: incidentStatusColor(s)),
                label: Text(s),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = _status == s ? null : s),
              ),
            const SizedBox(width: 12),
            FilterChip(label: const Text('Labels'), selected: _labels, onSelected: (v) => setState(() => _labels = v)),
            FilterChip(label: const Text('Names'), selected: _names, onSelected: (v) => setState(() => _names = v)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    key: ValueKey('${_range.start}${_range.end}$_category$_status${_all.length}'),
                    options: MapOptions(
                      initialCenter: defaultMapCenter,
                      initialZoom: 14,
                      maxZoom: 19,
                      initialCameraFit: pts.isEmpty ? null : CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(70), maxZoom: 17),
                      onTap: (_, __) => setState(() => _selected = null),
                    ),
                    children: [
                      ...baseMapLayers(_style),
                      MarkerLayer(markers: [
                        for (final p in shown)
                          Marker(
                            point: LatLng(p.latitude, p.longitude),
                            width: 180,
                            height: _labels ? 96 : 52,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => setState(() => _selected = p),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_labels) _PinLabel(pin: p, showName: _names, color: incidentStatusColor(p.status)),
                                  Icon(Icons.location_on,
                                      size: _selected?.id == p.id ? 52 : 42,
                                      color: incidentStatusColor(p.status),
                                      shadows: const [Shadow(color: Colors.black87, blurRadius: 8)]),
                                ],
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                  Positioned(right: 12, bottom: 28, child: MapStyleToggle(value: _style, onChanged: (k) => setState(() => _style = k))),
                  if (_loading) const Positioned.fill(child: ColoredBox(color: Color(0x66FFFFFF), child: Center(child: CircularProgressIndicator()))),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(_error ?? '${shown.length} ${shown.length == 1 ? 'report' : 'reports'} sa mapa', style: TextStyle(fontWeight: FontWeight.w600, color: _error != null ? Colors.red.shade700 : null)),
                      ),
                    ),
                  ),
                  if (!_loading && _error == null && _all.isEmpty)
                    Positioned.fill(
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text('Walang reklamong may pin sa napiling petsa.\nLalabas dito ang mga bagong reklamo na may lokasyon.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    bottom: 24,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          for (final s in _statuses)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                CircleAvatar(radius: 5, backgroundColor: incidentStatusColor(s)),
                                const SizedBox(width: 8),
                                Text(s, style: const TextStyle(fontSize: 12)),
                              ]),
                            ),
                        ]),
                      ),
                    ),
                  ),
                  if (_selected != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      width: 280,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Row(children: [
                              Expanded(child: Text(_selected!.caseNumber ?? 'Complaint #${_selected!.id}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700))),
                              InkWell(onTap: () => setState(() => _selected = null), child: const Icon(Icons.close, size: 18)),
                            ]),
                            const SizedBox(height: 4),
                            Text(_selected!.typeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: incidentStatusColor(_selected!.status).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                              child: Text(_selected!.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: incidentStatusColor(_selected!.status))),
                            ),
                            const SizedBox(height: 10),
                            if (_selected!.complainantName.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text('Complainant', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              Text(_selected!.complainantName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                            Text('${_pretty.format(_selected!.incidentDate)} · ${_selected!.incidentTime}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(_selected!.location, style: const TextStyle(fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small tag above a pin: what happened, and who reported it.
class _PinLabel extends StatelessWidget {
  final IncidentPin pin;
  final bool showName;
  final Color color;
  const _PinLabel({required this.pin, required this.showName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 172),
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pin.typeName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          if (showName && pin.complainantName.isNotEmpty)
            Text(pin.complainantName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
