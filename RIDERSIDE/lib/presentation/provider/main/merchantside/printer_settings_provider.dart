import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/printer_service.dart';

class PrinterSettingsState {
  final bool isAutoPrintEnabled;
  final String? connectedAddress;
  final String? connectedName;
  final bool isConnecting;
  final String? lastError;
  final List<PrinterDevice> discoveredDevices;
  final bool isScanning;

  const PrinterSettingsState({
    this.isAutoPrintEnabled = false,
    this.connectedAddress,
    this.connectedName,
    this.isConnecting = false,
    this.lastError,
    this.discoveredDevices = const [],
    this.isScanning = false,
  });

  PrinterSettingsState copyWith({
    bool? isAutoPrintEnabled,
    String? connectedAddress,
    String? connectedName,
    bool? isConnecting,
    String? lastError,
    List<PrinterDevice>? discoveredDevices,
    bool? isScanning,
    bool clearError = false,
  }) {
    return PrinterSettingsState(
      isAutoPrintEnabled: isAutoPrintEnabled ?? this.isAutoPrintEnabled,
      connectedAddress: connectedAddress ?? this.connectedAddress,
      connectedName: connectedName ?? this.connectedName,
      isConnecting: isConnecting ?? this.isConnecting,
      lastError: clearError ? null : (lastError ?? this.lastError),
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class PrinterSettingsNotifier extends StateNotifier<PrinterSettingsState> {
  final PrinterService _printer = PrinterService();

  PrinterSettingsNotifier() : super(const PrinterSettingsState()) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('printer_address');
    final name = prefs.getString('printer_name');
    final autoPrint = prefs.getBool('printer_auto_print') ?? false;

    state = state.copyWith(
      connectedAddress: address,
      connectedName: name,
      isAutoPrintEnabled: autoPrint,
    );
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_address', state.connectedAddress ?? '');
    await prefs.setString('printer_name', state.connectedName ?? '');
    await prefs.setBool('printer_auto_print', state.isAutoPrintEnabled);
  }

  Future<void> scanDevices() async {
    state = state.copyWith(isScanning: true, clearError: true);
    try {
      final devices = await _printer.getAllBondedDevices();
      state = state.copyWith(
        isScanning: false,
        discoveredDevices: devices,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        lastError: 'Failed to scan: $e',
      );
    }
  }

  Future<bool> connect(String address, String name) async {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      final ok = await _printer.connect(address);
      if (ok) {
        state = state.copyWith(
          isConnecting: false,
          connectedAddress: address,
          connectedName: name,
          lastError: null,
        );
        await _savePrefs();
        return true;
      } else {
        state = state.copyWith(
          isConnecting: false,
          lastError: 'Failed to connect to printer',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        lastError: 'Connection error: $e',
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await _printer.disconnect();
    state = state.copyWith(
      connectedAddress: null,
      connectedName: null,
    );
    await _savePrefs();
  }

  Future<bool> testPrint() async {
    state = state.copyWith(clearError: true);
    try {
      final ok = await _printer.printTestReceipt();
      if (!ok) {
        state = state.copyWith(lastError: 'Print failed. Check printer connection.');
      }
      return ok;
    } catch (e) {
      state = state.copyWith(lastError: 'Print error: $e');
      return false;
    }
  }

  void toggleAutoPrint(bool value) {
    state = state.copyWith(isAutoPrintEnabled: value);
    _savePrefs();
  }
}

final printerSettingsProvider =
    StateNotifierProvider<PrinterSettingsNotifier, PrinterSettingsState>(
  (ref) => PrinterSettingsNotifier(),
);
