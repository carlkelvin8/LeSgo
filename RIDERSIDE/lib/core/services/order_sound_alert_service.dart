import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Service for handling order sound alerts with customization options
class OrderSoundAlertService {
  static final OrderSoundAlertService _instance = OrderSoundAlertService._();

  factory OrderSoundAlertService() => _instance;

  OrderSoundAlertService._();

  late AudioPlayer _audioPlayer;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Sound preference keys
  static const String _soundEnabledKey = 'order_sound_enabled';
  static const String _soundVolumeKey = 'order_sound_volume';
  static const String _selectedSoundKey = 'order_sound_selected';
  static const String _vibrationEnabledKey = 'order_vibration_enabled';

  // Available sounds
  static const Map<String, String> availableSounds = {
    'bell': 'assets/sounds/order_bell.mp3',
    'chime': 'assets/sounds/order_chime.mp3',
    'ping': 'assets/sounds/order_ping.mp3',
    'notification': 'assets/sounds/order_notification.mp3',
  };

  // Getters
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      AppLogger.debug('OrderSoundAlertService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize OrderSoundAlertService', e);
    }
  }

  /// Enable or disable order sound alerts
  Future<void> setSoundEnabled(bool enabled) async {
    if (!_isInitialized) return;
    try {
      await _prefs.setBool(_soundEnabledKey, enabled);
      AppLogger.debug('Order sound alerts ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      AppLogger.error('Failed to set sound enabled', e);
    }
  }

  /// Check if sound alerts are enabled
  bool getSoundEnabled() {
    if (!_isInitialized) return false;
    return _prefs.getBool(_soundEnabledKey) ?? true; // Default: enabled
  }

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _prefs.setDouble(_soundVolumeKey, clampedVolume);
      await _audioPlayer.setVolume(clampedVolume);
      AppLogger.debug('Order sound volume set to $clampedVolume');
    } catch (e) {
      AppLogger.error('Failed to set volume', e);
    }
  }

  /// Get current volume level
  double getVolume() {
    if (!_isInitialized) return 0.7; // Default: 70%
    return _prefs.getDouble(_soundVolumeKey) ?? 0.7;
  }

  /// Select sound type for alerts
  Future<void> setSelectedSound(String soundKey) async {
    if (!_isInitialized) return;
    if (!availableSounds.containsKey(soundKey)) {
      AppLogger.error('Invalid sound key: $soundKey');
      return;
    }

    try {
      await _prefs.setString(_selectedSoundKey, soundKey);
      AppLogger.debug('Order sound changed to: $soundKey');
    } catch (e) {
      AppLogger.error('Failed to set selected sound', e);
    }
  }

  /// Get currently selected sound
  String getSelectedSound() {
    if (!_isInitialized) return 'bell'; // Default: bell
    return _prefs.getString(_selectedSoundKey) ?? 'bell';
  }

  /// Enable or disable vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    if (!_isInitialized) return;
    try {
      await _prefs.setBool(_vibrationEnabledKey, enabled);
      AppLogger.debug('Order vibration ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      AppLogger.error('Failed to set vibration enabled', e);
    }
  }

  /// Check if vibration is enabled
  bool getVibrationEnabled() {
    if (!_isInitialized) return true; // Default: enabled
    return _prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  /// Play order alert sound
  Future<void> playOrderAlert({bool useVibration = true}) async {
    if (!_isInitialized) return;

    if (!getSoundEnabled()) {
      AppLogger.debug('Order sound alerts are disabled');
      return;
    }

    try {
      // Apply volume setting
      await _audioPlayer.setVolume(getVolume());

      // Get selected sound
      final selectedSound = getSelectedSound();
      final soundPath = availableSounds[selectedSound] ?? availableSounds['bell']!;

      // Play sound
      await _audioPlayer.setAsset(soundPath);
      await _audioPlayer.play();

      AppLogger.debug('Playing order alert: $selectedSound');
    } catch (e) {
      AppLogger.error('Failed to play order alert sound', e);
    }
  }

  /// Stop current sound
  Future<void> stopSound() async {
    if (!_isInitialized) return;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      AppLogger.error('Failed to stop sound', e);
    }
  }

  /// Test current sound settings
  Future<void> testSound() async {
    await playOrderAlert();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (!_isInitialized) return;
    try {
      await _prefs.remove(_soundEnabledKey);
      await _prefs.remove(_soundVolumeKey);
      await _prefs.remove(_selectedSoundKey);
      await _prefs.remove(_vibrationEnabledKey);
      AppLogger.debug('Order sound alert settings reset to defaults');
    } catch (e) {
      AppLogger.error('Failed to reset settings', e);
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      AppLogger.debug('OrderSoundAlertService disposed');
    } catch (e) {
      AppLogger.error('Failed to dispose OrderSoundAlertService', e);
    }
  }
}
