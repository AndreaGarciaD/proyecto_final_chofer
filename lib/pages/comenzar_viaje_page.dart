import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_final_chofer/models/Viaje2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ComenzarViajePage extends StatefulWidget {
  final int viajeId;

  const ComenzarViajePage({super.key, required this.viajeId});

  @override
  // ignore: library_private_types_in_public_api
  _ComenzarViajePageState createState() => _ComenzarViajePageState();
}

class _ComenzarViajePageState extends State<ComenzarViajePage> {
  late Future<Viaje2> _futureViaje;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final String _googleApiKey = 'AIzaSyCv4gvHsJ6hN_G6u_ccANIrOUrxQH38Nwg';

  @override
  void initState() {
    super.initState();
    _futureViaje = fetchViaje(widget.viajeId);
  }

  void _onMapCreated(GoogleMapController controller) {
    _futureViaje.then((viaje) {
      _setMarkers(viaje);
      _plotRoute(viaje);
    });
  }

  void _setMarkers(Viaje2 viaje) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(
              double.parse(viaje.latOrigin), double.parse(viaje.lngOrigin)),
          infoWindow: const InfoWindow(title: 'Origen'),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(double.parse(viaje.latDestination),
              double.parse(viaje.lngDestination)),
          infoWindow: const InfoWindow(title: 'Destino'),
        ),
      );

      for (var stop in viaje.stops) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: LatLng(double.parse(stop.lat), double.parse(stop.lng)),
            infoWindow: InfoWindow(
              title: 'Punto de recogida',
              snippet: 'Pasajeros: ${stop.passengerQty}',
            ),
          ),
        );
      }
    });
  }

  void _plotRoute(Viaje2 viaje) async {
    final origin = '${viaje.latOrigin},${viaje.lngOrigin}';
    final destination = '${viaje.latDestination},${viaje.lngDestination}';
    List<LatLng> waypoints = [];
    for (var stop in viaje.stops) {
      waypoints.add(LatLng(double.parse(stop.lat), double.parse(stop.lng)));
    }

    final directionsUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&waypoints=${waypoints.map((waypoint) => 'via:${waypoint.latitude},${waypoint.longitude}').join('%7C')}&key=$_googleApiKey';

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
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Viaje2>(
          future: _futureViaje,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            } else if (snapshot.hasError) {
              return const Text('Error al cargar el viaje');
            } else if (!snapshot.hasData) {
              return const Text('Viaje no disponible');
            } else {
              return Text(snapshot.data!.name);
            }
          },
        ),
      ),
      body: FutureBuilder<Viaje2>(
        future: _futureViaje,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Viaje no disponible'));
          }

          final Viaje2 viaje = snapshot.data!;

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  double.parse(viaje.latOrigin), double.parse(viaje.lngOrigin)),
              zoom: 12.0,
            ),
            markers: _markers,
            polylines: _polylines,
          );
        },
      ),
    );
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<Viaje2> fetchViaje(int id) async {
    final String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final response = await http.get(
      Uri.parse('http://143.198.16.180/api/trips/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Viaje2.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load trip');
    }
  }
}
