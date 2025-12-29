import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  final MqttService mqttService;

  const HomeScreen({super.key, required this.mqttService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _brokerController = TextEditingController(text: 'broker.hivemq.com');
  final TextEditingController _portController = TextEditingController(text: '1883');
  final TextEditingController _topicController = TextEditingController(text: 'myhome/test/status');
  final TextEditingController _messageController = TextEditingController();
  
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Listen to connection status to update UI state
    widget.mqttService.connectionStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isConnected = (status == 'Connected');
        });
      }
    });
  }

  void _handleConnect() {
    final broker = _brokerController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 1883;
    final topic = _topicController.text.trim();

    if (broker.isNotEmpty && topic.isNotEmpty) {
      widget.mqttService.connect(broker, port, topic);
    }
  }

  void _handleDisconnect() {
    widget.mqttService.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT Monitor'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Settings
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text("Connection Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _brokerController,
                      decoration: const InputDecoration(labelText: "Broker", border: OutlineInputBorder()),
                      enabled: !_isConnected,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _portController,
                            decoration: const InputDecoration(labelText: "Port", border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            enabled: !_isConnected,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _topicController,
                            decoration: const InputDecoration(labelText: "Topic", border: OutlineInputBorder()),
                            enabled: !_isConnected,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _isConnected 
                      ? ElevatedButton.icon(
                          onPressed: _handleDisconnect,
                          icon: const Icon(Icons.link_off),
                          label: const Text("Disconnect"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        )
                      : ElevatedButton.icon(
                          onPressed: _handleConnect,
                          icon: const Icon(Icons.link),
                          label: const Text("Connect"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Connection Status Display
            Center(
              child: StreamBuilder<String>(
                stream: widget.mqttService.connectionStatusStream,
                initialData: "Disconnected",
                builder: (context, snapshot) {
                  String status = snapshot.data ?? "Disconnected";
                  Color color = Colors.red;
                  if (status == 'Connected') color = Colors.green;
                  if (status.startsWith('Connecting')) color = Colors.orange;

                  return Text(
                    "Status: $status",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  );
                },
              ),
            ),
            
            const Divider(height: 40),

            // Received Data Display
            const Text(
              "Received Data:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: StreamBuilder<String>(
                stream: widget.mqttService.statusStream,
                initialData: "No data received yet",
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? "No data",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Publish (Change State)
            const Text(
              "Publish Data:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: "Enter message",
                      border: OutlineInputBorder(),
                    ),
                    enabled: _isConnected,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isConnected ? () {
                    if (_messageController.text.isNotEmpty) {
                      widget.mqttService.publishMessage(_messageController.text);
                    }
                  } : null,
                  child: const Text("Send"),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Last Update Timestamp
            StreamBuilder<DateTime>(
              stream: widget.mqttService.lastUpdateStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Center(
                  child: Text(
                    "Last Update: ${DateFormat('HH:mm:ss').format(snapshot.data!)}",
                    style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
