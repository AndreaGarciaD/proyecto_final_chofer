import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:proyecto_final_chofer/models/viaje.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comenzar_viaje_page.dart';

class ListaViajesPage extends StatefulWidget {
  const ListaViajesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ListaViajesPageState createState() => _ListaViajesPageState();
}

class _ListaViajesPageState extends State<ListaViajesPage> {
  late Future<List<Viaje>> _futureViajes;
  late Future<String> _futureDriverName;

  @override
  void initState() {
    super.initState();
    _futureViajes = fetchViajes();
    _futureDriverName = fetchDriverInfo();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _futureDriverName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Cargando...');
            } else if (snapshot.hasError) {
              return const Text('Error al cargar el nombre');
            } else if (!snapshot.hasData) {
              return const Text('Nombre no disponible');
            } else {
              return Text('Hola, ${snapshot.data}');
            }
          },
        ),
      ),
      body: FutureBuilder<List<Viaje>>(
        future: _futureViajes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay viajes pendientes'));
          }

          final List<Viaje> viajes = snapshot.data!;

          return ListView.builder(
            itemCount: viajes.length,
            itemBuilder: (context, index) {
              final Viaje viaje = viajes[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(viaje.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha: ${viaje.date.toLocal()}'),
                          Text('Hora de partida: ${viaje.startTime}'),
                          Text('Precio: \$${viaje.price}'),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComenzarViajePage(viajeId: viaje.id),
                              ),
                            );
                          },
                          child: const Text('Comenzar Viaje'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/mapa');
        },
        tooltip: 'Nuevo viaje',
        child: const Icon(Icons.map),
      ),
    );
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<List<Viaje>> fetchViajes() async {
    final String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final response = await http.get(
      Uri.parse('http://143.198.16.180/api/trips'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return viajeFromJson(response.body);
    } else {
      throw Exception('Failed to load trips');
    }
  }

  Future<String> fetchDriverInfo() async {
    final String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no encontrado');
    }

    final response = await http.get(
      Uri.parse('http://143.198.16.180/api/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['fullname'];
    } else {
      throw Exception('Failed to load driver information');
    }
  }
}
