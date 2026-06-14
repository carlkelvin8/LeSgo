import 'package:flutter/material.dart';

import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class RiderNotificationSettingsScreen extends StatefulWidget {
  const RiderNotificationSettingsScreen({super.key});

  @override
  State<RiderNotificationSettingsScreen> createState() =>
      _RiderNotificationSettingsScreenState();
}

class _RiderNotificationSettingsScreenState
    extends State<RiderNotificationSettingsScreen> {
  bool _promotions = true;
  bool _orderUpdates = true;
  bool _missionReminders = true;
  bool _chatMessages = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await AppPreferencesService.getNotificationSettings();
    if (!mounted) return;
    setState(() {
      _promotions = settings[AppPreferencesService.prefPushPromotions] ?? true;
      _orderUpdates = settings[AppPreferencesService.prefPushOrderUpdates] ?? true;
      _missionReminders =
          settings[AppPreferencesService.prefPushMissionReminders] ?? true;
      _chatMessages = settings[AppPreferencesService.prefPushChatMessages] ?? true;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AppPreferencesService.setBool(
      AppPreferencesService.prefPushPromotions,
      _promotions,
    );
    await AppPreferencesService.setBool(
      AppPreferencesService.prefPushOrderUpdates,
      _orderUpdates,
    );
    await AppPreferencesService.setBool(
      AppPreferencesService.prefPushMissionReminders,
      _missionReminders,
    );
    await AppPreferencesService.setBool(
      AppPreferencesService.prefPushChatMessages,
      _chatMessages,
    );
    if (mounted) {
      setState(() => _saving = false);
      SnackBarUtils.showSuccess(context, 'Notification preferences saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontFamily: 'TT Fors'),
        ),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : ListView(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              children: [
                SwitchListTile(
                  title: const Text(
                    'Promotions & offers',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: const Text(
                    'Daily promos and voucher alerts',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _promotions,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _promotions = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Order updates',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: const Text(
                    'New bookings, status changes, cancellations',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _orderUpdates,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _orderUpdates = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Mission reminders',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: const Text(
                    'Mission progress and reward alerts',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _missionReminders,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _missionReminders = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Chat messages',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: const Text(
                    'Customer chat notifications',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _chatMessages,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _chatMessages = v),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save preferences',
                          style: TextStyle(fontFamily: 'TT Fors'),
                        ),
                ),
              ],
            ),
    );
  }
}
