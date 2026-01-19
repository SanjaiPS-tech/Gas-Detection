import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _brokerController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _snoozeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _brokerController.text =
          prefs.getString('mqtt_broker') ?? 'test.mosquitto.org';
      _portController.text = prefs.getInt('mqtt_port')?.toString() ?? '1883';
      _topicController.text = prefs.getString('mqtt_topic') ?? 'esp32/gas/live';
      _limitController.text =
          prefs.getDouble('gas_limit')?.toString() ?? '300.0';
      _snoozeController.text =
          prefs.getInt('snooze_duration')?.toString() ?? '5';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final broker = _brokerController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 1883;
    final topic = _topicController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 300.0;
    final snooze = int.tryParse(_snoozeController.text.trim()) ?? 5;

    await prefs.setString('mqtt_broker', broker);
    await prefs.setInt('mqtt_port', port);
    await prefs.setString('mqtt_topic', topic);
    await prefs.setDouble('gas_limit', limit);
    await prefs.setInt('snooze_duration', snooze);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
      Navigator.pop(
        context,
        true,
      ); // Return true to indicate settings were saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MQTT Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _brokerController,
              decoration: const InputDecoration(
                labelText: 'Broker URL',
                hintText: 'e.g. test.mosquitto.org',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '1883',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      hintText: 'esp32/gas/live',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Alert Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _limitController,
              decoration: const InputDecoration(
                labelText: 'Gas Alert Limit',
                hintText: 'e.g. 500.0',
                border: OutlineInputBorder(),
                suffixText: 'ppm',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _snoozeController,
              decoration: const InputDecoration(
                labelText: 'Snooze Duration',
                hintText: 'e.g. 5',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _topicController.dispose();
    _limitController.dispose();
    _snoozeController.dispose();
    super.dispose();
  }
}
