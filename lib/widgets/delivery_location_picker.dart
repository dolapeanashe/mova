import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DeliveryLocationPicker extends StatelessWidget {
  final LatLng pickupPoint;
  final LatLng? selectedPoint;
  final ValueChanged<LatLng> onPointSelected;
  final double height;

  const DeliveryLocationPicker({
    super.key,
    required this.pickupPoint,
    required this.selectedPoint,
    required this.onPointSelected,
    this.height = 320,
  });

  static const Color wine = Color(0xFF651F35);

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: pickupPoint,
        width: 48,
        height: 52,
        child: const Icon(Icons.storefront, color: wine, size: 40),
      ),
    ];

    if (selectedPoint != null) {
      markers.add(
        Marker(
          point: selectedPoint!,
          width: 48,
          height: 52,
          child: const Icon(Icons.location_on, color: Colors.red, size: 44),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: selectedPoint ?? pickupPoint,
                initialZoom: 16,
                minZoom: 13,
                maxZoom: 19,
                onTap: (tapPosition, point) {
                  onPointSelected(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mova',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
