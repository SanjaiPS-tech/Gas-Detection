import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/mqtt_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MqttService _mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    // Do not auto-connect; let HomeScreen handle it
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: HomeScreen(mqttService: _mqttService),
    );
  }
}
