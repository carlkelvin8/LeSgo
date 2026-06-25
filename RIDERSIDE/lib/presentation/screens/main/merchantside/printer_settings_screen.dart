import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/merchantside/printer_settings_provider.dart';

class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printerSettingsProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Printer Settings',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: hp,
          vertical: ResponsiveUtils.spacing(context, 16),
        ),
        children: [
          _buildConnectedSection(context, ref, state),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          _buildAutoPrintSection(context, ref, state),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          _buildScanSection(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildConnectedSection(
    BuildContext context,
    WidgetRef ref,
    PrinterSettingsState state,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connected Printer',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 15),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            if (state.hasSavedPrinter) ...[
              Row(
                children: [
                  Icon(
                    state.isLiveConnected ? Icons.print : Icons.print_outlined,
                    color: state.isLiveConnected
                        ? const Color(0xFF5F2D82)
                        : Colors.orange.shade700,
                    size: 32,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.connectedName ?? 'Printer',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          state.connectedAddress!,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (state.isConnecting)
                          Text(
                            'Reconnecting...',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: const Color(0xFF5F2D82),
                            ),
                          )
                        else if (!state.isLiveConnected)
                          Text(
                            'Saved — not connected',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.orange.shade800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    state.isLiveConnected
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    color: state.isLiveConnected
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              if (!state.isLiveConnected && !state.isConnecting)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bluetooth_connected, size: 18),
                    label: const Text('Reconnect'),
                    onPressed: () async {
                      final ok = await ref
                          .read(printerSettingsProvider.notifier)
                          .reconnectSavedPrinter();
                      if (context.mounted) {
                        if (ok) {
                          SnackBarUtils.showSuccess(context, 'Printer reconnected');
                        } else {
                          SnackBarUtils.showError(
                            context,
                            ref.read(printerSettingsProvider).lastError ??
                                'Reconnect failed',
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5F2D82),
                      side: const BorderSide(color: Color(0xFF5F2D82)),
                    ),
                  ),
                ),
              if (!state.isLiveConnected && !state.isConnecting)
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Test Print'),
                      onPressed: state.isConnecting
                          ? null
                          : () async {
                              final ok = await ref
                                  .read(printerSettingsProvider.notifier)
                                  .testPrint();
                              if (context.mounted) {
                                if (ok) {
                                  SnackBarUtils.showSuccess(
                                    context,
                                    'Test print sent!',
                                  );
                                } else {
                                  SnackBarUtils.showError(
                                    context,
                                    state.lastError ?? 'Print failed',
                                  );
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5F2D82),
                        side: const BorderSide(color: Color(0xFF5F2D82)),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect'),
                      onPressed: () {
                        ref.read(printerSettingsProvider.notifier).disconnect();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.print_disabled, color: Colors.grey.shade400, size: 32),
                  SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                  Text(
                    'No printer connected',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            if (state.lastError != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Text(
                state.lastError!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPrintSection(
    BuildContext context,
    WidgetRef ref,
    PrinterSettingsState state,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        title: Text(
          'Auto-print new orders',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Automatically print receipt when a new order arrives',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 11),
            color: Colors.grey.shade600,
          ),
        ),
        value: state.isAutoPrintEnabled,
        activeThumbColor: const Color(0xFF5F2D82),
        onChanged: state.hasSavedPrinter
            ? null
            : (v) {
                ref.read(printerSettingsProvider.notifier).toggleAutoPrint(v);
              },
      ),
    );
  }

  Widget _buildScanSection(
    BuildContext context,
    WidgetRef ref,
    PrinterSettingsState state,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Printers',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  icon: state.isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Scan'),
                  onPressed: state.isScanning
                      ? null
                      : () {
                          ref.read(printerSettingsProvider.notifier).scanDevices();
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5F2D82),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            if (state.discoveredDevices.isEmpty && !state.isScanning)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 24),
                ),
                child: Center(
                  child: Text(
                    'No Bluetooth printers found.\nMake sure the printer is paired with your device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              )
            else
              ...state.discoveredDevices.map(
                (device) => _printerTile(context, ref, device, state),
              ),
          ],
        ),
      ),
    );
  }

  Widget _printerTile(
    BuildContext context,
    WidgetRef ref,
    PrinterDevice device,
    PrinterSettingsState state,
  ) {
    final isConnected =
        device.address == state.connectedAddress && state.isLiveConnected;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isConnected ? Icons.print : Icons.print_outlined,
        color: isConnected
            ? const Color(0xFF5F2D82)
            : Colors.grey.shade600,
      ),
      title: Text(
        device.name,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        device.address,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 11),
          color: Colors.grey.shade600,
        ),
      ),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : ElevatedButton(
              onPressed: state.isConnecting
                  ? null
                  : () async {
                      final ok = await ref
                          .read(printerSettingsProvider.notifier)
                          .connect(device.address, device.name);
                      if (context.mounted) {
                        if (ok) {
                          SnackBarUtils.showSuccess(
                            context,
                            'Connected to ${device.name}',
                          );
                        } else {
                          SnackBarUtils.showError(
                            context,
                            state.lastError ?? 'Connection failed',
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 12),
                ),
                textStyle: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                ),
              ),
              child: state.isConnecting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Connect'),
            ),
    );
  }
}
