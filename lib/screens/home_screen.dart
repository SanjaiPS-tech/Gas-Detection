import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/mqtt_service.dart';
import 'settings_screen.dart';
import 'warning_screen.dart';

class HomeScreen extends StatefulWidget {
  final MqttService mqttService;

  const HomeScreen({super.key, required this.mqttService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _gasLimit = 300.0;
  bool _isWarningDialogShown = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndConnect();

    // Listen to connection status
    widget.mqttService.connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          // No-op for now as we use StreamBuilder in the UI
        });
      }
    });

    // Listen to gas data for alert logic
    widget.mqttService.gasValueStream.listen((data) {
      _checkGasLimit(data);
    });
  }

  Future<void> _loadSettingsAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final broker = prefs.getString('mqtt_broker') ?? 'test.mosquitto.org';
    final port = prefs.getInt('mqtt_port') ?? 1883;
    final topic = prefs.getString('mqtt_topic') ?? 'esp32/gas/live';

    setState(() {
      _gasLimit = prefs.getDouble('gas_limit') ?? 300.0;
    });

    // Auto-connect if not already connecting/connected
    widget.mqttService.connect(broker, port, topic);
  }

  void _checkGasLimit(double gasValue) async {
    if (!mounted) return;

    if (gasValue > _gasLimit) {
      if (!_isWarningDialogShown) {
        // Check for snooze
        final prefs = await SharedPreferences.getInstance();
        final snoozeUntil = prefs.getInt('snooze_until') ?? 0;

        if (DateTime.now().millisecondsSinceEpoch < snoozeUntil) {
          return; // Snoozed
        }

        _isWarningDialogShown = true;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WarningScreen()),
        ).then((_) {
          _isWarningDialogShown = false;
          _loadSettingsAndConnect(); // Refresh settings/snooze state
        });
      }
    }
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    if (result == true) {
      // Settings were saved, reload and reconnect
      _loadSettingsAndConnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gas Monitor'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettingsAndConnect,
            tooltip: 'Manual Reload',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSettingsAndConnect,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Status Indicator
              StreamBuilder<String>(
                stream: widget.mqttService.connectionStatusStream,
                initialData: "Disconnected",
                builder: (context, snapshot) {
                  String status = snapshot.data ?? "Disconnected";
                  Color color = Colors.red;
                  IconData icon = Icons.cloud_off;

                  if (status == 'Connected') {
                    color = Colors.green;
                    icon = Icons.cloud_done;
                  } else if (status.startsWith('Connecting')) {
                    color = Colors.orange;
                    icon = Icons.cloud_sync;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Gas Level Display
              const Text(
                "Current Gas Level",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              StreamBuilder<double>(
                stream: widget.mqttService.gasValueStream,
                initialData: 0.0,
                builder: (context, snapshot) {
                  final gasValue = snapshot.data ?? 0.0;

                  Color textColor = Colors.black;
                  if (gasValue > _gasLimit) {
                    textColor = Colors.red;
                  } else if (gasValue > _gasLimit * 0.7) {
                    textColor = Colors.orange;
                  } else {
                    textColor = Colors.green;
                  }

                  return Column(
                    children: [
                      Text(
                        gasValue.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Text(
                        "PPM",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // Gas Limit Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Alert Limit:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${_gasLimit.toStringAsFixed(1)} PPM",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Last Update Timestamp
              StreamBuilder<DateTime>(
                stream: widget.mqttService.lastUpdateStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  return Text(
                    "Last updated: ${DateFormat('HH:mm:ss').format(snapshot.data!)}",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
