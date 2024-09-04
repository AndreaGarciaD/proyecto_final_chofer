import 'package:flutter/material.dart';
import 'package:proyecto_final_chofer/pages/comenzar_viaje_page.dart';
import 'package:proyecto_final_chofer/pages/lista_viajes_page.dart';
import 'package:proyecto_final_chofer/pages/login_page.dart';
import 'package:proyecto_final_chofer/pages/mapa_page.dart';
import 'package:proyecto_final_chofer/pages/registro_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:  ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/registro':(context) => const RegistroPage(),
        '/viajes':(context) => const ListaViajesPage(),
        '/mapa':(context) => const MapaPage(),
        '/comenzarViaje':(context) => const ComenzarViajePage(viajeId: 1),
      },
    );
  }
}

