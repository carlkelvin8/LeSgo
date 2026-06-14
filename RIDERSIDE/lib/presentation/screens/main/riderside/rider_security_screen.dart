import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/security_api.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/common/retry_widget.dart';

class RiderSecurityScreen extends StatefulWidget {
  const RiderSecurityScreen({super.key});

  @override
  State<RiderSecurityScreen> createState() => _RiderSecurityScreenState();
}

class _RiderSecurityScreenState extends State<RiderSecurityScreen> {
  Map<String, dynamic> _dashboard = {};
  List<SecurityBiometric> _biometrics = [];
  List<SecurityAuditLog> _auditLogs = [];
  bool _loading = true;
  bool _processing = false;
  bool _localBiometricEnabled = false;
  bool _deviceSupportsBiometrics = false;
  String? _error;

  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final biometricEnabled =
          await AppPreferencesService.getBiometricUnlockEnabled();

      final results = await Future.wait([
        ApiService.getSecurityDashboard(),
        ApiService.listSecurityBiometrics(),
        ApiService.getSecurityAuditLogs(perPage: 10),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as Map<String, dynamic>;
        _biometrics = results[1] as List<SecurityBiometric>;
        _auditLogs = results[2] as List<SecurityAuditLog>;
        _localBiometricEnabled = biometricEnabled;
        _deviceSupportsBiometrics = canCheck && supported;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  bool get _twoFaEnabled =>
      _dashboard['two_factor_enabled'] == true ||
      _dashboard['is_2fa_enabled'] == true;

  Future<void> _enable2fa() async {
    setState(() => _processing = true);
    try {
      final setup = await ApiService.setup2fa();
      if (!mounted) return;

      final secret = setup['secret']?.toString() ?? '';
      final qrData = setup['qr_code']?.toString() ??
          setup['qr_code_url']?.toString() ??
          setup['otpauth_url']?.toString() ??
          '';
      final backupCodes = (setup['backup_codes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      final codeController = TextEditingController();
      final verified = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Enable 2FA',
            style: TextStyle(fontFamily: 'TT Fors'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (qrData.isNotEmpty) ...[
                  Center(
                    child: QrImageView(
                      data: qrData,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (secret.isNotEmpty) ...[
                  const Text(
                    'Manual secret:',
                    style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                  ),
                  SelectableText(secret),
                  const SizedBox(height: 12),
                ],
                if (backupCodes.isNotEmpty) ...[
                  const Text(
                    'Backup codes (save these):',
                    style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w600),
                  ),
                  ...backupCodes.map((c) => Text(c)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit authenticator code',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      );

      if (verified == true && codeController.text.trim().length == 6) {
        await ApiService.verify2fa(codeController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA enabled successfully')),
          );
        }
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _disable2fa() async {
    setState(() => _processing = true);
    try {
      await ApiService.disable2fa();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA disabled')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _regenerateBackupCodes() async {
    if (!_twoFaEnabled) return;
    setState(() => _processing = true);
    try {
      final codes = await ApiService.regenerateBackupCodes();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('New backup codes'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: codes.map(Text.new).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: codes.join('\n')));
                Navigator.pop(ctx);
              },
              child: const Text('Copy & close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    setState(() => _processing = true);
    try {
      if (enabled) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric unlock for LeSGo Rider',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!authenticated) {
          setState(() => _processing = false);
          return;
        }

        final available = await _localAuth.getAvailableBiometrics();
        final type = available.contains(BiometricType.face)
            ? 'face_id'
            : 'fingerprint';

        await SecurityApi.enrollBiometric(
          biometricType: type,
          deviceId: 'lesgo_rider_${defaultTargetPlatform.name}',
          deviceName: defaultTargetPlatform.name,
        );
      } else {
        for (final bio in _biometrics) {
          try {
            await SecurityApi.deactivateBiometric(biometricId: bio.id);
          } catch (_) {}
        }
      }

      await AppPreferencesService.setBiometricUnlockEnabled(enabled);
      await _load();
      if (mounted) {
        setState(() => _localBiometricEnabled = enabled);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: const Text('Security', style: TextStyle(fontFamily: 'TT Fors')),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : _error != null && _dashboard.isEmpty
              ? RetryWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: const Color(0xFF5F2D82),
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Two-factor authentication',
                          style: TextStyle(fontFamily: 'TT Fors'),
                        ),
                        subtitle: Text(
                          _twoFaEnabled
                              ? 'Enabled on your account'
                              : 'Add an extra layer of protection',
                          style: const TextStyle(fontFamily: 'TT Fors'),
                        ),
                        value: _twoFaEnabled,
                        activeThumbColor: const Color(0xFF5F2D82),
                        onChanged: _processing
                            ? null
                            : (enabled) async {
                                if (enabled && !_twoFaEnabled) {
                                  await _enable2fa();
                                } else if (!enabled && _twoFaEnabled) {
                                  await _disable2fa();
                                }
                              },
                      ),
                      if (_twoFaEnabled)
                        ListTile(
                          leading: const Icon(Icons.vpn_key_outlined),
                          title: const Text(
                            'Regenerate backup codes',
                            style: TextStyle(fontFamily: 'TT Fors'),
                          ),
                          trailing: _processing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _processing ? null : _regenerateBackupCodes,
                        ),
                      if (_deviceSupportsBiometrics)
                        SwitchListTile(
                          title: const Text(
                            'Biometric unlock',
                            style: TextStyle(fontFamily: 'TT Fors'),
                          ),
                          subtitle: const Text(
                            'Use fingerprint or Face ID to open the app',
                            style: TextStyle(fontFamily: 'TT Fors'),
                          ),
                          value: _localBiometricEnabled,
                          activeThumbColor: const Color(0xFF5F2D82),
                          onChanged: _processing ? null : _toggleBiometric,
                        ),
                      if (_dashboard.isNotEmpty) ...[
                        ListTile(
                          title: const Text(
                            'Active sessions',
                            style: TextStyle(fontFamily: 'TT Fors'),
                          ),
                          trailing: Text(
                            '${_dashboard['active_sessions'] ?? _dashboard['activeSessions'] ?? 0}',
                            style: const TextStyle(fontFamily: 'TT Fors'),
                          ),
                        ),
                        if (_dashboard['last_login'] != null ||
                            _dashboard['lastLogin'] != null)
                          ListTile(
                            title: const Text(
                              'Last login',
                              style: TextStyle(fontFamily: 'TT Fors'),
                            ),
                            subtitle: Text(
                              (_dashboard['last_login'] ??
                                      _dashboard['lastLogin'])
                                  ?.toString() ??
                                  '',
                              style: const TextStyle(fontFamily: 'TT Fors'),
                            ),
                          ),
                      ],
                      if (_biometrics.isNotEmpty) ...[
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
                        ..._biometrics.map(
                          (bio) => ListTile(
                            leading: const Icon(Icons.fingerprint),
                            title: Text(
                              bio.deviceName ?? bio.deviceId,
                              style: const TextStyle(fontFamily: 'TT Fors'),
                            ),
                            subtitle: Text(
                              bio.biometricType,
                              style: const TextStyle(fontFamily: 'TT Fors'),
                            ),
                          ),
                        ),
                      ],
                      if (_auditLogs.isNotEmpty) ...[
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
                        ..._auditLogs.map(
                          (log) => ListTile(
                            title: Text(
                              log.action,
                              style: const TextStyle(fontFamily: 'TT Fors'),
                            ),
                            subtitle: Text(
                              '${log.ipAddress ?? 'Unknown IP'} • ${log.createdAt}',
                              style: const TextStyle(fontFamily: 'TT Fors'),
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
