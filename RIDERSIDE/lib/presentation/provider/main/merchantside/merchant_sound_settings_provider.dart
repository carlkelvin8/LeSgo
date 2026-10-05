import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/order_sound_alert_service.dart';

// Providers for sound alert settings
final soundEnabledProvider = StateNotifierProvider<SoundEnabledNotifier, bool>(
  (ref) => SoundEnabledNotifier(),
);

final soundVolumeProvider = StateNotifierProvider<SoundVolumeNotifier, double>(
  (ref) => SoundVolumeNotifier(),
);

final selectedSoundProvider = StateNotifierProvider<SelectedSoundNotifier, String>(
  (ref) => SelectedSoundNotifier(),
);

final vibrationEnabledProvider = StateNotifierProvider<VibrationEnabledNotifier, bool>(
  (ref) => VibrationEnabledNotifier(),
);

final availableSoundsProvider = Provider<Map<String, String>>((ref) {
  return OrderSoundAlertService.availableSounds;
});

// Notifiers
class SoundEnabledNotifier extends StateNotifier<bool> {
  late final OrderSoundAlertService _service;

  SoundEnabledNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    _service = OrderSoundAlertService();
    await _service.initialize();
    state = _service.getSoundEnabled();
  }

  Future<void> toggle() async {
    state = !state;
    await _service.setSoundEnabled(state);
  }

  Future<void> set(bool value) async {
    state = value;
    await _service.setSoundEnabled(value);
  }
}

class SoundVolumeNotifier extends StateNotifier<double> {
  late final OrderSoundAlertService _service;

  SoundVolumeNotifier() : super(0.7) {
    _init();
  }

  Future<void> _init() async {
    _service = OrderSoundAlertService();
    await _service.initialize();
    state = _service.getVolume();
  }

  Future<void> setVolume(double volume) async {
    state = volume;
    await _service.setVolume(volume);
  }
}

class SelectedSoundNotifier extends StateNotifier<String> {
  late final OrderSoundAlertService _service;

  SelectedSoundNotifier() : super('bell') {
    _init();
  }

  Future<void> _init() async {
    _service = OrderSoundAlertService();
    await _service.initialize();
    state = _service.getSelectedSound();
  }

  Future<void> setSound(String soundKey) async {
    state = soundKey;
    await _service.setSelectedSound(soundKey);
  }
}

class VibrationEnabledNotifier extends StateNotifier<bool> {
  late final OrderSoundAlertService _service;

  VibrationEnabledNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    _service = OrderSoundAlertService();
    await _service.initialize();
    state = _service.getVibrationEnabled();
  }

  Future<void> toggle() async {
    state = !state;
    await _service.setVibrationEnabled(state);
  }

  Future<void> set(bool value) async {
    state = value;
    await _service.setVibrationEnabled(value);
  }
}
