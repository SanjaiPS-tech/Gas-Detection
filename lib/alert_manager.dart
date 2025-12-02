import 'package:audioplayers/audioplayers.dart';

class AlertManager {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> startAlert() async {
    if (_isPlaying) return;
    _isPlaying = true;
    // Set source to a built-in sound or asset.
    // For simplicity, we'll assume a local asset 'alert.mp3' is added or use a URL if assets are tricky without setup.
    // Since adding assets requires pubspec changes and file addition, let's try to use a source that doesn't require extra setup if possible,
    // or just assume the user will provide 'assets/alert.mp3'.
    // Actually, let's use a URL for a beep sound to avoid asset complexity for now, or better, just loop a short beep.
    // A reliable way without assets is hard. Let's assume we need to add an asset.
    // Wait, I can't easily add a binary asset file.
    // I will try to play a sound from a URL which is easier for this environment.
    // Using a generic sound URL.

    try {
      await _audioPlayer.setSourceUrl(
        'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> stopAlert() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    await _audioPlayer.stop();
  }

  bool get isPlaying => _isPlaying;
}
