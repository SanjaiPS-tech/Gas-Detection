import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class WarningScreen extends StatefulWidget {
  const WarningScreen({super.key});

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startAlarm();
  }

  void _startAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Using a reliable HTTPS URL for a siren sound.
      // Ensure the device is online for this to work, otherwise catch block handles it.
      await _player.play(
        UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3',
        ),
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    _loopVibration();
  }

  void _loopVibration() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    while (mounted && (hasVibrator ?? false)) {
      Vibration.vibrate();
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 150,
                color: Colors.yellow,
              ),
              const SizedBox(height: 40),
              const Text(
                'GAS LEAK DETECTED',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'EVACUATE IMMEDIATELY',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
