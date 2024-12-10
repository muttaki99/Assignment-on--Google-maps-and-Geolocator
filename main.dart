import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RealTimeLocationTracker(),
    );
  }
}

class RealTimeLocationTracker extends StatefulWidget {
  @override
  _RealTimeLocationTrackerState createState() => _RealTimeLocationTrackerState();
}

class _RealTimeLocationTrackerState extends State<RealTimeLocationTracker> {
  GoogleMapController? _mapController;
  Marker? _currentMarker;
  Polyline? _polyline;
  List<LatLng> _routeCoordinates = [];
  LatLng? _lastKnownLocation;

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  Future<void> _startTrackingLocation() async {
    // Check and request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return; // Permission denied
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return; // Permission permanently denied
    }

    // Start fetching location updates every 10 seconds
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      LatLng newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _lastKnownLocation = newPosition;

        // Add location to route
        _routeCoordinates.add(newPosition);

        // Update marker
        _currentMarker = Marker(
          markerId: const MarkerId('currentLocation'),
          position: newPosition,
          infoWindow: InfoWindow(
            title: 'My Current Location',
            snippet: 'Lat: ${position.latitude}, Lng: ${position.longitude}',
          ),
        );

        // Update polyline
        _polyline = Polyline(
          polylineId: const PolylineId('route'),
          points: _routeCoordinates,
          color: Colors.blue,
          width: 4,
        );

        // Animate camera
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Real-Time Location Tracker"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _lastKnownLocation ?? const LatLng(0, 0), // Default to 0,0
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          // Move camera to the last known location if available
          if (_lastKnownLocation != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_lastKnownLocation!),
            );
          }
        },
        markers: _currentMarker != null ? {_currentMarker!} : {},
        polylines: _polyline != null ? {_polyline!} : {},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
