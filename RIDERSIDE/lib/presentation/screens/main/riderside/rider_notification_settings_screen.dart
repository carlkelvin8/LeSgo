import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class RiderNotificationSettingsScreen extends ConsumerStatefulWidget {
  const RiderNotificationSettingsScreen({super.key});

  @override
  ConsumerState<RiderNotificationSettingsScreen> createState() =>
      _RiderNotificationSettingsScreenState();
}

class _RiderNotificationSettingsScreenState
    extends ConsumerState<RiderNotificationSettingsScreen> {
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
      SnackBarUtils.showSuccess(
        context,
        AppLocalization.translate('notif_preferences_saved', ref.read(appLanguageProvider)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalization.translate('notif_settings_title', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : ListView(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              children: [
                SwitchListTile(
                  title: Text(
                    AppLocalization.translate('promotions_offers', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: Text(
                    AppLocalization.translate('daily_promo_alerts', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _promotions,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _promotions = v),
                ),
                SwitchListTile(
                  title: Text(
                    AppLocalization.translate('order_updates', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: Text(
                    AppLocalization.translate('new_bookings_status_changes', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _orderUpdates,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _orderUpdates = v),
                ),
                SwitchListTile(
                  title: Text(
                    AppLocalization.translate('mission_reminders', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: Text(
                    AppLocalization.translate('mission_progress_alerts', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  value: _missionReminders,
                  activeThumbColor: const Color(0xFF5F2D82),
                  onChanged: (v) => setState(() => _missionReminders = v),
                ),
                SwitchListTile(
                  title: Text(
                    AppLocalization.translate('chat_messages', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
                  ),
                  subtitle: Text(
                    AppLocalization.translate('customer_chat_notifications', lang),
                    style: const TextStyle(fontFamily: 'TT Fors'),
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
                      : Text(
                          AppLocalization.translate('save_preferences', lang),
                          style: const TextStyle(fontFamily: 'TT Fors'),
                        ),
                ),
              ],
            ),
    );
  }
}
