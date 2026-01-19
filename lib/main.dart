import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/mqtt_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'gas_monitor_service',
    'Gas Monitor Service',
    description: 'This channel is used for gas monitoring service.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'gas_monitor_service',
      initialNotificationTitle: 'Gas Monitor Active',
      initialNotificationContent: 'Monitoring gas levels...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final MqttService mqttService = MqttService();

  // Load settings and connect
  final prefs = await SharedPreferences.getInstance();
  final broker = prefs.getString('mqtt_broker') ?? 'test.mosquitto.org';
  final port = prefs.getInt('mqtt_port') ?? 1883;
  final topic = prefs.getString('mqtt_topic') ?? 'esp32/gas/live';
  final gasLimit = prefs.getDouble('gas_limit') ?? 300.0;

  mqttService.connect(broker, port, topic);

  mqttService.gasValueStream.listen((gasValue) async {
    if (gasValue > gasLimit) {
      // Check for snooze
      final prefs = await SharedPreferences.getInstance();
      final snoozeUntil = prefs.getInt('snooze_until') ?? 0;

      if (DateTime.now().millisecondsSinceEpoch < snoozeUntil) {
        return; // Snoozed
      }

      flutterLocalNotificationsPlugin.show(
        999,
        'DANGER: Gas Leak Detected!',
        'Current Level: ${gasValue.toStringAsFixed(0)} PPM. Evacuate immediately!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gas_monitor_alerts',
            'Gas Alerts',
            channelDescription: 'High gas level alerts',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
        ),
      );
    }

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Gas Monitor: ${gasValue.toStringAsFixed(0)} PPM",
        content: gasValue > gasLimit
            ? "DANGER! HIGH GAS LEVEL"
            : "Gas levels are safe",
      );
    }
  });

  service.on('stopService').listen((event) {
    mqttService.disconnect();
    service.stopSelf();
  });
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
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gas Monitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: HomeScreen(mqttService: _mqttService),
    );
  }
}
