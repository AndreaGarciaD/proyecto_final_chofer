import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormularioViajePage extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final List<LatLng> pickupPoints;

  const FormularioViajePage({
    super.key,
    required this.origin,
    required this.destination,
    required this.pickupPoints,
  });

  @override
  // ignore: library_private_types_in_public_api
  _FormularioViajePageState createState() => _FormularioViajePageState();
}

class _FormularioViajePageState extends State<FormularioViajePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _dateController = TextEditingController();
  List<TextEditingController> _pickupTimeControllers = [];
  String? _originAddress;
  String? _destinationAddress;
  List<String?> _pickupAddresses = [];

  @override
  void initState() {
    super.initState();
    _initializePickupTimeControllers();
    _fetchAddresses();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulario de Viaje'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Nombre del viaje'),
              _buildDatePicker(_dateController, 'Fecha'),
              _buildTextField(_priceController, 'Precio'),
              _buildTextField(_seatsController, 'Número de asientos'),
              _buildTimePicker(_startTimeController, 'Hora de inicio'),
              const SizedBox(height: 20.0),
              if (_originAddress != null)
                _buildLocationField('Origen', _originAddress!),
              if (_destinationAddress != null)
                _buildLocationField('Destino', _destinationAddress!),
              const SizedBox(height: 20.0),
              const Text('Puntos de recogida'),
              for (int i = 0; i < widget.pickupPoints.length; i++)
                Column(
                  children: [
                    if (_pickupAddresses.isNotEmpty)
                      _buildLocationField(
                          'Parada ${i + 1}', _pickupAddresses[i]!),
                    _buildTimePicker(_pickupTimeControllers[i],
                        'Hora de llegada a la parada ${i + 1}'),
                  ],
                ),
              const SizedBox(height: 30.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 101, 173, 240),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Publicar Viaje',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.grey[200],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: labelText,
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese $labelText';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(TextEditingController controller, String labelText) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
          setState(() {
            controller.text = formattedDate;
          });
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(controller, labelText),
      ),
    );
  }

  Widget _buildTimePicker(TextEditingController controller, String labelText) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            controller.text = pickedTime.format(context);
          });
        }
      },
      child: AbsorbPointer(
        child: _buildTextField(controller, labelText),
      ),
    );
  }

  Widget _buildLocationField(String title, String address) {
    return ListTile(
      title: Text(title),
      subtitle: Text(address),
    );
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final viaje = {
        'name': _nameController.text,
        'latOrigin': widget.origin.latitude.toString(),
        'lngOrigin': widget.origin.longitude.toString(),
        'latDestination': widget.destination.latitude.toString(),
        'lngDestination': widget.destination.longitude.toString(),
        'date': _dateController.text,
        'price': _priceController.text,
        'seats': int.parse(_seatsController.text),
        'stops': widget.pickupPoints
            .asMap()
            .entries
            .map((entry) => {
                  'lat': entry.value.latitude.toString(),
                  'lng': entry.value.longitude.toString(),
                  'time': _pickupTimeControllers[entry.key].text.toString()
                })
            .toList(),
        'startTime': _startTimeController.text.toString()
      };

      final String? token = await _getToken();
      if (token == null) {
        throw Exception('Token no encontrado');
      }

      final response = await http.post(
        Uri.parse('http://143.198.16.180/api/trips'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(viaje),
      );

      if (response.statusCode == 201) {
        _showDialog(
            'Viaje publicado', 'El viaje ha sido publicado exitosamente.');
      } else {
        _showDialog('Error', 'Hubo un error al publicar el viaje.');
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              if (title == 'Viaje publicado') {
                Navigator.pushNamed(context, '/viajes');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAddresses() async {
    _originAddress = await _getAddressFromLatLng(widget.origin);
    _destinationAddress = await _getAddressFromLatLng(widget.destination);
    _pickupAddresses = await Future.wait(
        widget.pickupPoints.map((point) => _getAddressFromLatLng(point)));

    setState(() {});
  }

  Future<String?> _getAddressFromLatLng(LatLng position) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=AIzaSyCv4gvHsJ6hN_G6u_ccANIrOUrxQH38Nwg';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['results'][0]['formatted_address'];
      }
    }
    return null;
  }

  void _initializePickupTimeControllers() {
    _pickupTimeControllers = List.generate(
        widget.pickupPoints.length, (index) => TextEditingController());
  }
}
