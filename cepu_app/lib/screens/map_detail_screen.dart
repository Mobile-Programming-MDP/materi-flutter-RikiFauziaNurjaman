import 'package:cepu_app/models/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapDetailScreen extends StatelessWidget {
  final Post post;
  const MapDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(post.latitude ?? '');
    final lng = double.tryParse(post.longitude ?? '');
    final hasLocation = lat != null && lng != null;
    final point = hasLocation ? LatLng(lat, lng) : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(post.category ?? 'Map detail'),
      ),
      body: hasLocation
          ? FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cepu_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const Center(
              child: Text('No location data available'),
            ),
    );
  }
}