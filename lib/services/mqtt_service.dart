import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum GasStatus { safe, danger }

class MqttService {
  MqttServerClient? client;

  // Stream controllers
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  Stream<String> get connectionStatusStream =>
      _connectionStatusController.stream;

  final StreamController<DateTime> _lastUpdateController =
      StreamController<DateTime>.broadcast();
  Stream<DateTime> get lastUpdateStream => _lastUpdateController.stream;
  DateTime? lastUpdate;

  final StreamController<double> _gasValueController =
      StreamController<double>.broadcast();
  Stream<double> get gasValueStream => _gasValueController.stream;

  String? currentTopic;

  Future<void> connect(String broker, int port, String topic) async {
    // Disconnect if already connected
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      disconnect();
    }

    currentTopic = topic;

    // Create new client instance
    client = MqttServerClient(broker, '');
    client!.logging(on: true);
    client!.keepAlivePeriod = 20;
    client!.port = port;
    client!.onDisconnected = onDisconnected;
    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;
    client!.autoReconnect = true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(
          'flutter_client_${DateTime.now().millisecondsSinceEpoch}',
        )
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      _connectionStatusController.add('Connecting to $broker...');
      await client!.connect();
    } on Exception catch (e) {
      _connectionStatusController.add('Connection Failed');
      print('MQTT client exception - $e');
      client!.disconnect();
    }
  }

  void disconnect() {
    if (client != null) {
      client!.disconnect();
      _connectionStatusController.add('Disconnected');
    }
  }

  void onConnected() {
    _connectionStatusController.add('Connected');
    print('MQTT Connected');

    if (currentTopic != null) {
      print('Subscribing to $currentTopic');
      client!.subscribe(currentTopic!, MqttQos.atLeastOnce);
    }

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final receivedTopic = c[0].topic;

      print('Received message: topic=$receivedTopic, payload=$pt');

      if (receivedTopic == currentTopic) {
        lastUpdate = DateTime.now();
        _lastUpdateController.add(lastUpdate!);
        _statusController.add(pt);

        // Parse JSON if possible
        try {
          final Map<String, dynamic> data = jsonDecode(pt);
          if (data.containsKey('gas_raw')) {
            final gasValue = double.tryParse(data['gas_raw'].toString());
            if (gasValue != null) {
              _gasValueController.add(gasValue);
            }
          }
        } catch (e) {
          // Fallback parsing if not valid JSON
          final gasValue = double.tryParse(pt);
          if (gasValue != null) {
            _gasValueController.add(gasValue);
          }
        }
      }
    });
  }

  void publishMessage(String message) {
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected &&
        currentTopic != null) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(
        currentTopic!,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } else {
      print('Cannot publish: Client not connected or topic not set');
    }
  }

  void onDisconnected() {
    _connectionStatusController.add('Disconnected');
    print('MQTT Disconnected');
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }
}
