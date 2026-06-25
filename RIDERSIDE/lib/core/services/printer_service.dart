import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../../data/data_source/dto/merchant/order_dto.dart';
import 'esc_pos_utils.dart';

class PrinterDevice {
  final String name;
  final String address;

  PrinterDevice({required this.name, required this.address});
}

class PrinterService {
  static final PrinterService _instance = PrinterService._();
  factory PrinterService() => _instance;
  PrinterService._();

  BluetoothConnection? _activeConnection;
  String? _connectedAddress;

  bool get isConnected => _activeConnection != null;

  String? get connectedAddress => _connectedAddress;

  Future<List<PrinterDevice>> discoverPrinters() async {
    final bluetooth = FlutterBluetoothSerial.instance;

    if (await bluetooth.isEnabled != true) {
      await bluetooth.requestEnable();
    }

    final bonded = await bluetooth.getBondedDevices();
    return bonded
        .where((d) =>
            (d.name ?? '').toLowerCase().contains('printer') ||
            (d.name ?? '').toLowerCase().contains('thermal') ||
            (d.name ?? '').toLowerCase().contains('pos') ||
            (d.name ?? '').toLowerCase().contains('receipt') ||
            (d.name ?? '').toLowerCase().contains('58mm') ||
            (d.name ?? '').toLowerCase().contains('80mm'))
        .map((d) => PrinterDevice(
              name: d.name ?? 'Unknown',
              address: d.address,
            ))
        .toList();
  }

  Future<List<PrinterDevice>> getAllBondedDevices() async {
    final bluetooth = FlutterBluetoothSerial.instance;

    if (await bluetooth.isEnabled != true) {
      await bluetooth.requestEnable();
    }

    final bonded = await bluetooth.getBondedDevices();
    return bonded
        .map((d) => PrinterDevice(
              name: d.name ?? 'Unknown',
              address: d.address,
            ))
        .toList();
  }

  Future<bool> connect(String address) async {
    try {
      await disconnect();
      final connection = await BluetoothConnection.toAddress(address);
      _activeConnection = connection;
      _connectedAddress = address;
      connection.input?.listen(
        null,
        onDone: () {
          debugPrint('Printer Bluetooth connection closed');
          _activeConnection = null;
          _connectedAddress = null;
        },
      );
      return true;
    } catch (e) {
      debugPrint('Printer connect error: $e');
      _activeConnection = null;
      _connectedAddress = null;
      return false;
    }
  }

  Future<bool> ensureConnected(String address) async {
    if (isConnected && _connectedAddress == address) return true;
    return connect(address);
  }

  Future<void> disconnect() async {
    try {
      await _activeConnection?.close();
    } catch (_) {}
    _activeConnection = null;
    _connectedAddress = null;
  }

  Future<bool> printBytes(List<int> bytes) async {
    if (_activeConnection == null) return false;
    try {
      _activeConnection!.output.add(Uint8List.fromList(bytes));
      await _activeConnection!.output.allSent;
      return true;
    } catch (e) {
      debugPrint('Printer write error: $e');
      _activeConnection = null;
      _connectedAddress = null;
      return false;
    }
  }

  Future<bool> printTestReceipt() async {
    final now = DateTime.now();
    final bytes = EscPosUtils.buildReceipt(
      storeName: 'LEZGO TEST',
      orderRef: 'TEST-001',
      date: now,
      itemLines: [
        'Item 1                     ₱10',
        'Item 2                     ₱20',
        'Item 3                     ₱30',
      ],
      totalLabel: 'TOTAL',
      totalAmount: '₱60.00',
      footerLines: [
        'Thank you!',
        'This is a test print',
      ],
    );
    return printBytes(bytes);
  }

  Future<bool> printOrder(OrderDto order, String storeName) async {
    final items = order.orderItems ?? [];
    final itemLines = <String>[];
    for (final item in items) {
      final qty = item.quantity;
      final name = item.itemName.length > 20
          ? '${item.itemName.substring(0, 20)}..'
          : item.itemName;
      final price = item.totalPrice ?? 0.0;
      final line = '$name x$qty       ₱${price.toStringAsFixed(2)}';
      itemLines.add(line);
    }

    final now = DateTime.tryParse(order.createdAt) ?? DateTime.now();

    final bytes = EscPosUtils.buildReceipt(
      storeName: storeName,
      orderRef: order.referenceNumber ?? '#${order.id}',
      date: now,
      customer: order.user?.name,
      itemLines: itemLines,
      totalLabel: 'TOTAL',
      totalAmount: '₱${order.totalFare?.toStringAsFixed(2) ?? '0.00'}',
      footerLines: [
        'Thank you for your order!',
        'Please wait for rider assignment',
      ],
    );
    return printBytes(bytes);
  }

  void dispose() {
    disconnect();
  }
}
