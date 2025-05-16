import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/disaster_provider.dart';
import 'login_screen.dart';
import 'dart:math';

class SupplierHomeScreen extends StatefulWidget {
  const SupplierHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupplierHomeScreen> createState() => _SupplierHomeScreenState();
}

class _SupplierHomeScreenState extends State<SupplierHomeScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);
    await disasterProvider.getClusters();
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);
    final clusters = disasterProvider.clusters;

    if (clusters == null) return;

    final markers = <Marker>{};
    final circles = <Circle>{};

    clusters.forEach((clusterId, locations) {
      if (locations is List) {
        double totalLat = 0;
        double totalLng = 0;
        int count = 0;

        for (var location in locations) {
          if (location is Map<String, dynamic>) {
            final lat = location['latitude'] as double;
            final lng = location['longitude'] as double;
            totalLat += lat;
            totalLng += lng;
            count++;
          }
        }

        if (count > 0) {
          final centerLat = totalLat / count;
          final centerLng = totalLng / count;

          markers.add(
            Marker(
              markerId: MarkerId('cluster_$clusterId'),
              position: LatLng(centerLat, centerLng),
              infoWindow: InfoWindow(
                title: 'Cluster $clusterId',
                snippet: '$count people',
              ),
            ),
          );

          circles.add(
            Circle(
              circleId: CircleId('cluster_$clusterId'),
              center: LatLng(centerLat, centerLng),
              radius: 500, // 500 meters radius
              fillColor: Colors.red.withOpacity(0.2),
              strokeColor: Colors.red,
              strokeWidth: 2,
            ),
          );
        }
      }
    });

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  Future<void> _calculateSupplies(String clusterId) async {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);
    await disasterProvider.calculateSupplies(clusterId);

    if (!mounted) return;

    final supplies = disasterProvider.supplies;
    if (supplies != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Required Supplies for Cluster $clusterId'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Water: ${supplies['water']} liters'),
              Text('Food: ${supplies['food']} meals'),
              Text('Medical Kits: ${supplies['medical_kits']}'),
              Text('Blankets: ${supplies['blankets']}'),
              Text('Tents: ${supplies['tents']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DisasterHelp - Supplier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<DisasterProvider>(
        builder: (context, disasterProvider, child) {
          if (disasterProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (disasterProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    disasterProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadClusters,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0), // Default position
                  zoom: 2,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                circles: _circles,
                onTap: (position) {
                  // Find the closest cluster
                  double minDistance = double.infinity;
                  String? closestClusterId;

                  disasterProvider.clusters?.forEach((clusterId, locations) {
                    if (locations is List) {
                      for (var location in locations) {
                        if (location is Map<String, dynamic>) {
                          final lat = location['latitude'] as double;
                          final lng = location['longitude'] as double;
                          final distance = _calculateDistance(
                            position.latitude,
                            position.longitude,
                            lat,
                            lng,
                          );

                          if (distance < minDistance) {
                            minDistance = distance;
                            closestClusterId = clusterId;
                          }
                        }     
                      }
                    }
                  });

                  if (closestClusterId != null) {
                    _calculateSupplies(closestClusterId!);
                  }
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Active Clusters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap on a cluster to view required supplies',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
} 