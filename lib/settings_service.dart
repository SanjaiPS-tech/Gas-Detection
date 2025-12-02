import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyChannelId = 'channel_id';
  static const String _keyApiKey = 'api_key';
  static const String _keyThreshold = 'threshold';

  Future<void> saveSettings({
    required String channelId,
    required String apiKey,
    required double threshold,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyChannelId, channelId);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setDouble(_keyThreshold, threshold);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'channelId': prefs.getString(_keyChannelId) ?? '',
      'apiKey': prefs.getString(_keyApiKey) ?? '',
      'threshold': prefs.getDouble(_keyThreshold) ?? 100.0,
    };
  }
}
