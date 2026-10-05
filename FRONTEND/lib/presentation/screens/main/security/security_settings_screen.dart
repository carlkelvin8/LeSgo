import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/security/security_provider.dart';
import '../../../widgets/auth/two_factor_code_dialog.dart';

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
          : RefreshIndicator(
              color: AppColors.accent(context, Color(0xFF5F2D82)),
              onRefresh: () =>
                  ref.read(securitySettingsProvider.notifier).loadSecurity(),
              child: ListView(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                children: [
                  if (state.error != null)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(state.error!),
                      trailing: IconButton(
                        tooltip: 'Reload security settings',
                        icon: const Icon(Icons.refresh),
                        onPressed: state.isProcessing
                            ? null
                            : () => ref
                                  .read(securitySettingsProvider.notifier)
                                  .loadSecurity(),
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Two-factor authentication'),
                    subtitle: Text(
                      state.twoFactorEnabled
                          ? 'Enabled on your account'
                          : 'Add an extra layer of protection',
                    ),
                    value: state.twoFactorEnabled,
                    activeThumbColor: const Color(0xFF5F2D82),
                    onChanged: state.isProcessing || state.dashboard == null
                        ? null
                        : (enabled) async {
                            if (enabled) {
                              if (state.twoFactorEnabled) return;
                              final setup = await ref
                                  .read(securitySettingsProvider.notifier)
                                  .startTwoFactorSetup();
                              if (!context.mounted || setup == null) return;
                              final codeController = TextEditingController();
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
                                          'Connect Google Authenticator',
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Open Google Authenticator automatically, or add the setup key manually.',
                                        ),
                                        const SizedBox(height: 12),
                                        FilledButton.icon(
                                          onPressed: () async {
                                            var opened = false;
                                            try {
                                              opened = await launchUrl(
                                                Uri.parse(setup.qrCode),
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            } catch (_) {
                                              opened = false;
                                            }
                                            if (!opened && context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Google Authenticator could not be opened. Use the setup key below.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text(
                                            'Open Google Authenticator',
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF5F2D82,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('Setup key:'),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SelectableText(
                                                setup.secret,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Copy setup key',
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                  ClipboardData(
                                                    text: setup.secret,
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.copy),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Save these one-time backup codes:',
                                        ),
                                        ...setup.backupCodes.map(Text.new),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                  text: setup.backupCodes.join(
                                                    '\n',
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.copy),
                                            label: const Text(
                                              'Copy backup codes',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: codeController,
                                          keyboardType: TextInputType.number,
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
                                              securitySettingsProvider.notifier,
                                            )
                                            .verifyTwoFactor(
                                              codeController.text.trim(),
                                            );
                                        if (ctx.mounted && ok) {
                                          Navigator.pop(ctx);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '2FA enabled successfully',
                                                ),
                                              ),
                                            );
                                          }
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ref
                                                        .read(
                                                          securitySettingsProvider,
                                                        )
                                                        .error ??
                                                    'Invalid authenticator code.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Verify'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (state.twoFactorEnabled) {
                              final code = await showTwoFactorCodeDialog(
                                context,
                                title: 'Disable two-step verification?',
                                message:
                                    'Confirm with Google Authenticator or a backup code before turning this protection off.',
                              );
                              if (code == null || !context.mounted) return;

                              final ok = await ref
                                  .read(securitySettingsProvider.notifier)
                                  .disableTwoFactor(code);
                              if (context.mounted && ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('2FA disabled')),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ref
                                              .read(securitySettingsProvider)
                                              .error ??
                                          'Could not disable two-step verification.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                  ),
                  if (state.deviceSupportsBiometrics ||
                      state.localBiometricEnabled)
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
