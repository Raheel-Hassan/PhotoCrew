// lib/utils/audio_player_manager.dart
import 'package:just_audio/just_audio.dart';

class AudioPlayerManager {
  static final AudioPlayerManager _instance = AudioPlayerManager._internal();
  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isInitialized = false;

  factory AudioPlayerManager() {
    return _instance;
  }

  AudioPlayerManager._internal();

  AudioPlayer get player => _player;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  Future<void> playAudio(String url) async {
    try {
      // If same audio is playing, pause it
      if (_currentlyPlayingUrl == url && _player.playing) {
        await _player.pause();
        return;
      }

      // Stop current audio if different URL
      if (_currentlyPlayingUrl != url) {
        await _player.stop();
        _isInitialized = false;
      }

      // Initialize new audio if needed
      if (!_isInitialized) {
        await _player.setUrl(url);
        _isInitialized = true;
        _currentlyPlayingUrl = url;
      }

      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      //debugPrint('Error in playAudio: $e');
      // Reset state on error
      _isInitialized = false;
      _currentlyPlayingUrl = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentlyPlayingUrl = null;
    _isInitialized = false;
  }

  void dispose() {
    _player.dispose();
    _currentlyPlayingUrl = null;
    _isInitialized = false;
  }
}