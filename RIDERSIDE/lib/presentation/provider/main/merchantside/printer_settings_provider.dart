import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/printer_service.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';

class PrinterSettingsState {
  final bool isAutoPrintEnabled;
  /// Saved paired printer (persisted).
  final String? connectedAddress;
  final String? connectedName;
  /// Live Bluetooth session to the saved printer.
  final bool isLiveConnected;
  final bool isConnecting;
  final String? lastError;
  final List<PrinterDevice> discoveredDevices;
  final bool isScanning;

  const PrinterSettingsState({
    this.isAutoPrintEnabled = false,
    this.connectedAddress,
    this.connectedName,
    this.isLiveConnected = false,
    this.isConnecting = false,
    this.lastError,
    this.discoveredDevices = const [],
    this.isScanning = false,
  });

  bool get hasSavedPrinter =>
      connectedAddress != null && connectedAddress!.isNotEmpty;

  PrinterSettingsState copyWith({
    bool? isAutoPrintEnabled,
    String? connectedAddress,
    String? connectedName,
    bool? isLiveConnected,
    bool? isConnecting,
    String? lastError,
    List<PrinterDevice>? discoveredDevices,
    bool? isScanning,
    bool clearError = false,
    bool clearSavedPrinter = false,
  }) {
    return PrinterSettingsState(
      isAutoPrintEnabled: isAutoPrintEnabled ?? this.isAutoPrintEnabled,
      connectedAddress:
          clearSavedPrinter ? null : (connectedAddress ?? this.connectedAddress),
      connectedName:
          clearSavedPrinter ? null : (connectedName ?? this.connectedName),
      isLiveConnected: isLiveConnected ?? this.isLiveConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      lastError: clearError ? null : (lastError ?? this.lastError),
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

class PrinterSettingsNotifier extends StateNotifier<PrinterSettingsState> {
  PrinterSettingsNotifier() : super(const PrinterSettingsState()) {
    _loadSaved();
  }

  final PrinterService _printer = PrinterService();

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('printer_address');
    final name = prefs.getString('printer_name');
    final autoPrint = prefs.getBool('printer_auto_print') ?? false;

    final savedAddress = (address != null && address.isNotEmpty) ? address : null;

    state = state.copyWith(
      connectedAddress: savedAddress,
      connectedName: (name != null && name.isNotEmpty) ? name : null,
      isAutoPrintEnabled: autoPrint,
      isLiveConnected: false,
    );

    if (savedAddress != null) {
      await reconnectSavedPrinter(silent: true);
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_address', state.connectedAddress ?? '');
    await prefs.setString('printer_name', state.connectedName ?? '');
    await prefs.setBool('printer_auto_print', state.isAutoPrintEnabled);
  }

  /// Reconnect to the saved printer (startup, resume, before print).
  Future<bool> reconnectSavedPrinter({bool silent = false}) async {
    final address = state.connectedAddress;
    if (address == null || address.isEmpty) return false;

    if (_printer.isConnected && _printer.connectedAddress == address) {
      state = state.copyWith(isLiveConnected: true, clearError: true);
      return true;
    }

    state = state.copyWith(isConnecting: true, clearError: silent);
    try {
      final ok = await _printer.connect(address);
      state = state.copyWith(
        isConnecting: false,
        isLiveConnected: ok,
        lastError: ok
            ? null
            : (silent
                ? null
                : 'Could not reconnect to printer. Check Bluetooth and try again.'),
      );
      return ok;
    } catch (e) {
      debugPrint('Printer reconnect error: $e');
      state = state.copyWith(
        isConnecting: false,
        isLiveConnected: false,
        lastError: silent ? null : 'Reconnection error: $e',
      );
      return false;
    }
  }

  Future<bool> ensureConnectedForPrinting() async {
    if (!state.hasSavedPrinter) return false;
    if (state.isLiveConnected && _printer.isConnected) return true;
    return reconnectSavedPrinter(silent: true);
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
          isLiveConnected: true,
          lastError: null,
        );
        await _savePrefs();
        return true;
      }

      state = state.copyWith(
        isConnecting: false,
        isLiveConnected: false,
        lastError: 'Failed to connect to printer',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        isLiveConnected: false,
        lastError: 'Connection error: $e',
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await _printer.disconnect();
    state = state.copyWith(
      clearSavedPrinter: true,
      isLiveConnected: false,
    );
    await _savePrefs();
  }

  Future<bool> testPrint() async {
    state = state.copyWith(clearError: true);
    if (!await ensureConnectedForPrinting()) {
      state = state.copyWith(
        lastError: 'Printer not connected. Tap Reconnect or connect again.',
      );
      return false;
    }

    try {
      final ok = await _printer.printTestReceipt();
      if (!ok) {
        state = state.copyWith(
          isLiveConnected: false,
          lastError: 'Print failed. Check printer connection.',
        );
      }
      return ok;
    } catch (e) {
      state = state.copyWith(
        isLiveConnected: false,
        lastError: 'Print error: $e',
      );
      return false;
    }
  }

  Future<bool> printOrder(OrderDto order, String storeName) async {
    if (!state.isAutoPrintEnabled || !state.hasSavedPrinter) return false;
    if (!await ensureConnectedForPrinting()) return false;

    try {
      final ok = await _printer.printOrder(order, storeName);
      if (!ok) {
        state = state.copyWith(isLiveConnected: false);
      }
      return ok;
    } catch (e) {
      debugPrint('Auto-print error: $e');
      state = state.copyWith(isLiveConnected: false);
      return false;
    }
  }

  void toggleAutoPrint(bool value) {
    state = state.copyWith(isAutoPrintEnabled: value);
    _savePrefs();
  }

  void markDisconnected() {
    if (!state.isLiveConnected) return;
    state = state.copyWith(isLiveConnected: false);
  }
}

final printerSettingsProvider =
    StateNotifierProvider<PrinterSettingsNotifier, PrinterSettingsState>(
  (ref) => PrinterSettingsNotifier(),
);
