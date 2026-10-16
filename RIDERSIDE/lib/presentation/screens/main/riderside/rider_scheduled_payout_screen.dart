import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/scheduled_payout_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderScheduledPayoutScreen extends ConsumerStatefulWidget {
  const RiderScheduledPayoutScreen({super.key});

  @override
  ConsumerState<RiderScheduledPayoutScreen> createState() =>
      _RiderScheduledPayoutScreenState();
}

class _RiderScheduledPayoutScreenState
    extends ConsumerState<RiderScheduledPayoutScreen> {
  String _frequency = 'weekly';
  int _weeklyDay = 1;
  int _monthlyDay = 1;
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 9, minute: 0);
  final _thresholdController = TextEditingController(text: '500');
  String? _selectedAccount;
  bool _isLoading = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    _restorePreferences();
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _restorePreferences() async {
    final prefs = await ScheduledPayoutService.load();
    if (!mounted) return;
    setState(() {
      _frequency = prefs.frequency;
      _weeklyDay = prefs.weeklyDay;
      _monthlyDay = prefs.monthlyDay;
      _scheduledTime = _fromHm(prefs.time);
      _thresholdController.text = prefs.threshold.toStringAsFixed(0);
      _selectedAccount = prefs.accountProvider;
      _restored = true;
    });
  }

  TimeOfDay _fromHm(String hm) {
    final parts = hm.split(':');
    final hour = int.tryParse(parts.first);
    final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  Future<void> _savePayout() async {
    setState(() => _isLoading = true);
    try {
      final prefs = ScheduledPayoutPreferences(
        frequency: _frequency,
        weeklyDay: _weeklyDay,
        monthlyDay: _monthlyDay,
        time: _timeCode(),
        threshold:
            double.tryParse(_thresholdController.text.trim()) ?? 0,
        accountProvider: _selectedAccount,
      );
      final synced = await ScheduledPayoutService.save(prefs);

      if (!mounted) return;
      final lang = ref.read(appLanguageProvider);
      final saved = AppLocalization.translate(
        'scheduled_payout_saved',
        lang,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(synced ? saved : '$saved (${AppLocalization.translate('pending_sync', lang)})'),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _timeCode() {
    return '${_scheduledTime.hour.toString().padLeft(2, '0')}:'
        '${_scheduledTime.minute.toString().padLeft(2, '0')}';
  }

  String _timeLabel() {
    final now = DateTime.now();
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);
    final lang = ref.watch(appLanguageProvider);
    final wallet = ref.watch(riderWalletProvider);
    final linkedAccounts = wallet.linkedAccounts
        .where((a) =>
            a['provider']?.toString() == 'gcash' ||
            a['provider']?.toString() == 'maya')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          AppLocalization.translate('scheduled_payout', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(hp),
        children: [
          Text(
            'Auto-Payout Frequency',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          RadioGroup<String>(
            groupValue: _frequency,
            onChanged: (v) => setState(() => _frequency = v!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          ...['daily', 'weekly', 'monthly'].map((f) {
            final selected = _frequency == f;
            return Card(
              margin: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF5F2D82)
                      : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
              ),
              child: RadioListTile<String>(
                title: Text(
                  f == 'daily'
                      ? 'Daily'
                      : f == 'weekly'
                          ? 'Weekly'
                          : 'Monthly',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
                subtitle: Text(
                  f == 'daily'
                      ? 'Every day at ${_timeLabel()}'
                      : f == 'weekly'
                          ? 'Every ${_dayName(_weeklyDay)} at ${_timeLabel()}'
                          : 'Day $_monthlyDay of every month at ${_timeLabel()}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                  ),
                ),
                value: f,
                activeColor: const Color(0xFF5F2D82),
              ),
            );
          }),
              ],
            ),
          ),
          if (_frequency == 'weekly')
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                children: [
                  Text(
                    'Payout day:',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _weeklyDay,
                    items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_dayName(i + 1)),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _weeklyDay = v!),
                  ),
                ],
              ),
            ),
          if (_frequency == 'monthly')
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                children: [
                  Text(
                    'Day of month:',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _monthlyDay,
                    items: List.generate(
                      28,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _monthlyDay = v!),
                  ),
                ],
              ),
            ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Payout Time',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey.shade700,
              ),
            ),
            subtitle: Text(
              _timeLabel(),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _scheduledTime,
              );
              if (picked != null) {
                setState(() => _scheduledTime = picked);
              }
            },
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          TextField(
            controller: _thresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Minimum Balance Threshold (PHP)',
              hintText: 'e.g. 500',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: const TextStyle(fontFamily: 'TT Fors'),
            ),
            style: const TextStyle(fontFamily: 'TT Fors'),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Auto-payout will only trigger when your balance reaches this amount.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          Text(
            'Linked Account',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          if (linkedAccounts.isEmpty)
            Text(
              'No linked accounts. Link GCash or Maya in wallet first.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey.shade600,
              ),
            )
          else
            RadioGroup<String>(
              groupValue: _selectedAccount,
              onChanged: (v) => setState(() => _selectedAccount = v!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            ...linkedAccounts.map((account) {
              final provider = account['provider']?.toString() ?? '';
              final last4 = account['account_last4']?.toString() ?? '';
              final isSelected = _selectedAccount == provider;
              return Card(
                margin: EdgeInsets.only(
                  bottom: ResponsiveUtils.spacing(context, 8),
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF5F2D82)
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    provider.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                    ),
                  ),
                  subtitle: last4.isNotEmpty
                      ? Text(
                          '•••• $last4',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                          ),
                        )
                      : null,
                  value: provider,
                  activeColor: const Color(0xFF5F2D82),
                ),
              );
            }),
                ],
              ),
            ),
          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.buttonHeight(context),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              onPressed: _selectedAccount == null || _isLoading || !_restored
                  ? null
                  : _savePayout,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Scheduled Payout',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[day - 1];
  }
}
