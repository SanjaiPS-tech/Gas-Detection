import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'settings_screen.dart';
import 'alert_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _channelId = '';
  String _apiKey = '';
  double _threshold = 100.0;
  double _currentGasLevel = 0.0;
  bool _isAlerting = false;
  bool _isLoading = false;
  String _statusMessage = '';
  Timer? _timer;
  final _settingsService = SettingsService();
  final _alertManager = AlertManager();

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStartPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _alertManager.stopAlert();
    super.dispose();
  }

  Future<void> _loadSettingsAndStartPolling() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _channelId = settings['channelId'];
      _apiKey = settings['apiKey'];
      _threshold = settings['threshold'];
    });
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    if (_channelId.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchData();
    });
    _fetchData(); // Fetch immediately
  }

  Future<void> _fetchData() async {
    if (_channelId.isEmpty) {
      setState(() => _statusMessage = 'Channel ID not set');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching data...';
    });

    try {
      // Construct URL. Assuming Field 1 is the gas data.
      String url =
          'https://api.thingspeak.com/channels/$_channelId/feeds/last.json';
      if (_apiKey.isNotEmpty) {
        url += '?api_key=$_apiKey';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final field1 = data['field1'];
        if (field1 != null) {
          final level = double.tryParse(field1.toString()) ?? 0.0;
          setState(() {
            _currentGasLevel = level;
            _isLoading = false;
            _statusMessage =
                'Last updated: ${DateTime.now().toString().split('.')[0]}';
          });
          _checkThreshold(level);
        } else {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Error: Field1 is null';
          });
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Connection Error';
      });
    }
  }

  void _checkThreshold(double level) {
    if (level > _threshold && !_isAlerting) {
      _startAlert();
    }
  }

  void _startAlert() {
    setState(() => _isAlerting = true);
    _alertManager.startAlert();
  }

  void _stopAlert() {
    setState(() => _isAlerting = false);
    _alertManager.stopAlert();
  }

  void _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (result == true) {
      _loadSettingsAndStartPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Guardian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_channelId.isEmpty)
                  const Text('Please configure Channel ID in Settings')
                else ...[
                  const Text(
                    'Current Gas Level:',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentGasLevel.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _currentGasLevel > _threshold
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Threshold: $_threshold',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading) const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          if (_isAlerting)
            Container(
              color: Colors.red.withOpacity(0.9),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, size: 100, color: Colors.white),
                  const SizedBox(height: 32),
                  const Text(
                    'GAS DETECTED!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 64),
                  ElevatedButton(
                    onPressed: _stopAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 24,
                      ),
                    ),
                    child: const Text(
                      'STOP ALERT',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
