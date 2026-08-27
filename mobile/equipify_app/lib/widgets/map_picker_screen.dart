import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';

/// Full-screen map where the user taps to place a draggable location pin.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initial = const LatLng(31.95, 35.91),
  });

  final LatLng initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _point = const LatLng(31.95, 35.91);

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_addressHint)),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 14,
              onTap: (_, p) => setState(() => _point = p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.equipify.app',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 46,
                  height: 46,
                  child: const Icon(Icons.location_on_rounded,
                      size: 44, color: EqColors.bad),
                ),
              ]),
            ],
          ),

          // Center crosshair hint card
          PositionedDirectional(
            bottom: 24,
            start: 24,
            end: 24,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: EqColors.accent,
                foregroundColor: EqColors.accentText,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => Navigator.pop(context, _point),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                '${_point.latitude.toStringAsFixed(4)}, ${_point.longitude.toStringAsFixed(4)}',
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _addressHint =>
      '${_point.latitude.toStringAsFixed(3)}, ${_point.longitude.toStringAsFixed(3)}';
}
