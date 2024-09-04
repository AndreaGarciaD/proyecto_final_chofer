import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_final_chofer/pages/crear_viaje_form.dart';


class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  _MapaPageState createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  late GoogleMapController mapController;
  LatLng _initialPosition = const LatLng(0.0, 0.0);
  LatLng _currentPosition = const LatLng(0.0, 0.0);
  late Location _location;
  bool _isSelectingOrigin = true;
  bool _isSelectingPickupPoints = false; 
  LatLng? _origin;
  LatLng? _destination;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final String _googleApiKey = 'AIzaSyCv4gvHsJ6hN_G6u_ccANIrOUrxQH38Nwg';
  bool _routePlotted = false;
  final List<LatLng> _pickupPoints = [];

  @override
  void initState() {
    super.initState();
    _location = Location();
    _setInitialLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
      ),
      body: Stack(
        children: [
          _initialPosition.latitude == 0.0
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  onCameraMove: _onCameraMove,
                  markers: _markers,
                  polylines: _polylines,
                  onTap: null, 
                ),
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 50.0,
              color: Colors.red,
            ),
          ),
          if (!_routePlotted)
            Positioned(
              bottom: 50,
              left: MediaQuery.of(context).size.width / 2 - 75,
              child: ElevatedButton(
                onPressed: _selectPosition,
                child: Text(_isSelectingOrigin
                    ? 'Seleccionar Origen'
                    : 'Seleccionar Destino'),
              ),
            ),
          if (_routePlotted && !_isSelectingPickupPoints)
            Positioned(
              bottom: 100,
              left: MediaQuery.of(context).size.width / 2 - 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _confirmRoute,
                    child: const Text('Confirmar ruta'),
                  ),
                  ElevatedButton(
                    onPressed: _retraceRoute,
                    child: const Text('Volver a trazar ruta'),
                  ),
                ],
              ),
            ),
          if (_isSelectingPickupPoints)
            Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width / 2 - 150,
              child: const Text(
                'Seleccione puntos de recogida dentro de la ruta',
                style: TextStyle(
                  backgroundColor: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isSelectingPickupPoints)
            Positioned(
              bottom: 50,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: ElevatedButton(
                onPressed: _addPickupPoint,
                child: const Text('Definir punto de recogida'),
              ),
            ),
          if (_isSelectingPickupPoints)
            Positioned(
              bottom: 100,
              left: MediaQuery.of(context).size.width / 2 - 75,
              child: ElevatedButton(
                onPressed: _navigateToFormularioViaje,
                child: const Text('Publicar Viaje'),
              ),
            ),
        ],
      ),
    );
  }

  void _setInitialLocation() async {
    var currentLocation = await _location.getLocation();
    setState(() {
      _initialPosition =
          LatLng(currentLocation.latitude!, currentLocation.longitude!);
      _currentPosition = _initialPosition;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _location.onLocationChanged.listen((l) {
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(l.latitude!, l.longitude!), zoom: 15),
        ),
      );
    });
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position.target;
  }

  void _selectPosition() async {
    setState(() {
      if (_isSelectingOrigin) {
        _origin = _currentPosition;
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
                        position: _origin!,
            infoWindow: const InfoWindow(title: 'Origen'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue),
          ),
        );
        _isSelectingOrigin = false;
      } else {
        _destination = _currentPosition;
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination!,
            infoWindow: const InfoWindow(title: 'Destino'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
          ),
        );
        _plotRoute();
      }
    });
  }

  void _plotRoute() async {
    if (_origin == null || _destination == null) return;

    final origin = '${_origin!.latitude},${_origin!.longitude}';
    final destination = '${_destination!.latitude},${_destination!.longitude}';
    final directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_googleApiKey';

    final response = await http.get(Uri.parse(directionsUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final polylinePoints = PolylinePoints();
        final points = polylinePoints
            .decodePolyline(data['routes'][0]['overview_polyline']['points']);
        final List<LatLng> routePoints = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
          _routePlotted = true;
          _isSelectingPickupPoints = true;
        });
      }
    }
  }

  void _confirmRoute() {
    setState(() {
      _isSelectingPickupPoints = true;
    });
  }

  void _retraceRoute() {
    setState(() {
      _markers.removeWhere((marker) =>
          marker.markerId.value == 'origin' ||
          marker.markerId.value == 'destination');
      _polylines.clear();
      _routePlotted = false;
      _isSelectingOrigin = true;
      _isSelectingPickupPoints = false;
      _origin = null;
      _destination = null;
      _pickupPoints.clear();
    });
  }

  void _addPickupPoint() {
    setState(() {
      _pickupPoints.add(_currentPosition);
      _markers.add(
        Marker(
          markerId: MarkerId('pickup_${_pickupPoints.length}'),
          position: _currentPosition,
          infoWindow: InfoWindow(
              title: 'Punto de recogida ${_pickupPoints.length}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
        ),
      );
    });
  }

  void _navigateToFormularioViaje() {
    if (_origin == null || _destination == null || _pickupPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione el origen, destino y al menos un punto de recogida.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioViajePage(
          origin: _origin!,
          destination: _destination!,
          pickupPoints: _pickupPoints,
        ),
      ),
    );
  }
}
