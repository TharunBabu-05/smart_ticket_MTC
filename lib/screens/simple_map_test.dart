import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SimpleMapTest extends StatefulWidget {
  const SimpleMapTest({super.key});

  @override
  State<SimpleMapTest> createState() => _SimpleMapTestState();
}

class _SimpleMapTestState extends State<SimpleMapTest> {
  GoogleMapController? _controller;
  bool _mapLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
        backgroundColor: const Color(0xFF1DB584),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange[100],
            child: const Text(
              'If you see a blank area below, the Google Maps API key is not configured. Check SETUP_INSTRUCTIONS.md',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(13.0827, 80.2707), // Chennai coordinates
                zoom: 12.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
                setState(() {
                  _mapLoaded = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Map loaded successfully! API key is working.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              markers: {
                const Marker(
                  markerId: MarkerId('test'),
                  position: LatLng(13.0827, 80.2707),
                  infoWindow: InfoWindow(
                    title: 'Test Location',
                    snippet: 'Chennai, India',
                  ),
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              _mapLoaded ? 'Map Status: ✅ Loaded' : 'Map Status: ⏳ Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _mapLoaded ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
