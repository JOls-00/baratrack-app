import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

enum BaseMapKind { satellite, street }

const _ua = 'com.baratrack.app';
const _esri = 'https://server.arcgisonline.com/ArcGIS/rest/services';

/// Base map layers. Satellite = real aerial photos with road and place names on top.
/// Street = OpenStreetMap. Each one carries the credit its provider requires.
List<Widget> baseMapLayers(BaseMapKind kind) {
  if (kind == BaseMapKind.street) {
    return [
      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: _ua),
      RichAttributionWidget(attributions: [
        TextSourceAttribution('OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'))),
      ]),
    ];
  }
  return [
    TileLayer(urlTemplate: '$_esri/World_Imagery/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: _ua, maxNativeZoom: 18),
    TileLayer(urlTemplate: '$_esri/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: _ua, maxNativeZoom: 18),
    TileLayer(urlTemplate: '$_esri/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}', userAgentPackageName: _ua, maxNativeZoom: 18),
    RichAttributionWidget(attributions: [
      TextSourceAttribution('Esri, Vantor, Earthstar Geographics, and the GIS User Community',
          onTap: () => launchUrl(Uri.parse('https://goto.arcgisonline.com/maps/World_Imagery'))),
    ]),
  ];
}

/// Small Satellite / Map switch that sits on top of a map.
class MapStyleToggle extends StatelessWidget {
  final BaseMapKind value;
  final ValueChanged<BaseMapKind> onChanged;
  const MapStyleToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      child: SegmentedButton<BaseMapKind>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact, backgroundColor: Colors.white),
        segments: const [
          ButtonSegment(value: BaseMapKind.satellite, label: Text('Satellite')),
          ButtonSegment(value: BaseMapKind.street, label: Text('Map')),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
