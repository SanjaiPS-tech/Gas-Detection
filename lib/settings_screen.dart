import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _channelIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _channelIdController.text = settings['channelId'];
      _apiKeyController.text = settings['apiKey'];
      _thresholdController.text = settings['threshold'].toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final threshold = double.tryParse(_thresholdController.text) ?? 100.0;
    await _settingsService.saveSettings(
      channelId: _channelIdController.text,
      apiKey: _apiKeyController.text,
      threshold: threshold,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings Saved')));
      Navigator.pop(context, true); // Return true to indicate settings changed
    }
  }

  Future<void> _testConnection() async {
    final channelId = _channelIdController.text;
    final apiKey = _apiKeyController.text;

    if (channelId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Channel ID')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Testing connection...')));

    try {
      String url =
          'https://api.thingspeak.com/channels/$channelId/feeds/last.json';
      if (apiKey.isNotEmpty) {
        url += '?api_key=$apiKey';
      }

      final response = await http.get(Uri.parse(url));
      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          // Simple check to see if it looks like ThingSpeak data
          if (data is Map && data.containsKey('created_at')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Success! Connection working.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connected, but unexpected data format.'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _channelIdController,
              decoration: const InputDecoration(
                labelText: 'ThingSpeak Channel ID',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Read API Key (Optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _thresholdController,
              decoration: const InputDecoration(
                labelText: 'Gas Detection Threshold',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
