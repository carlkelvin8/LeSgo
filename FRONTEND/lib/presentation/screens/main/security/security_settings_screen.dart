import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/security/security_provider.dart';
import '../../../widgets/common/retry_widget.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securitySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : state.error != null && state.dashboard == null
              ? RetryWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(securitySettingsProvider.notifier).loadSecurity(),
                )
              : RefreshIndicator(
                  color: const Color(0xFF5F2D82),
                  onRefresh: () =>
                      ref.read(securitySettingsProvider.notifier).loadSecurity(),
                  child: ListView(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    children: [
                      SwitchListTile(
                        title: const Text('Two-factor authentication'),
                        subtitle: Text(
                          state.twoFactorEnabled
                              ? 'Enabled on your account'
                              : 'Add an extra layer of protection',
                        ),
                        value: state.twoFactorEnabled,
                        activeThumbColor: const Color(0xFF5F2D82),
                        onChanged: state.isProcessing
                            ? null
                            : (enabled) async {
                                if (enabled) {
                                  if (state.twoFactorEnabled) return;
                                  final setup = await ref
                                      .read(securitySettingsProvider.notifier)
                                      .startTwoFactorSetup();
                                  if (!context.mounted || setup == null) return;
                                  final codeController =
                                      TextEditingController();
                                  await showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('2FA setup'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Add this secret to your authenticator app:',
                                            ),
                                            const SizedBox(height: 8),
                                            SelectableText(setup.secret),
                                            const SizedBox(height: 12),
                                            const Text('Backup codes:'),
                                            ...setup.backupCodes.map(Text.new),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: codeController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: '6-digit code',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            final ok = await ref
                                                .read(
                                                  securitySettingsProvider
                                                      .notifier,
                                                )
                                                .verifyTwoFactor(
                                                  codeController.text.trim(),
                                                );
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
                                              if (ok && context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '2FA enabled successfully',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text('Verify'),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (state.twoFactorEnabled) {
                                  final ok = await ref
                                      .read(securitySettingsProvider.notifier)
                                      .disableTwoFactor();
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('2FA disabled'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      if (state.deviceSupportsBiometrics)
                        SwitchListTile(
                          title: const Text('Biometric unlock'),
                          subtitle: const Text(
                            'Use fingerprint or Face ID to open the app',
                          ),
                          value: state.localBiometricEnabled,
                          activeThumbColor: const Color(0xFF5F2D82),
                          onChanged: state.isProcessing
                              ? null
                              : (enabled) async {
                                  await ref
                                      .read(securitySettingsProvider.notifier)
                                      .toggleBiometricUnlock(enabled);
                                },
                        ),
                      if (state.dashboard != null) ...[
                        ListTile(
                          title: const Text('Active sessions'),
                          trailing: Text('${state.dashboard!.activeSessions}'),
                        ),
                        if (state.dashboard!.lastLogin != null)
                          ListTile(
                            title: const Text('Last login'),
                            subtitle: Text(state.dashboard!.lastLogin!),
                          ),
                      ],
                      if (state.registeredBiometrics.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            'Registered devices',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                            ),
                          ),
                        ),
                        ...state.registeredBiometrics.map(
                          (bio) => ListTile(
                            leading: const Icon(Icons.fingerprint),
                            title: Text(bio.deviceName),
                            subtitle: Text(bio.type),
                          ),
                        ),
                      ],
                      if (state.auditLogs.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            'Recent activity',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                            ),
                          ),
                        ),
                        ...state.auditLogs.map(
                          (log) => ListTile(
                            title: Text(log.action),
                            subtitle: Text(
                              '${log.ipAddress ?? 'Unknown IP'} • ${log.createdAt}',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
