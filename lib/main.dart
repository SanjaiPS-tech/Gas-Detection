import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const GasGuardianApp());
}

class GasGuardianApp extends StatelessWidget {
  const GasGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gas Guardian',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
