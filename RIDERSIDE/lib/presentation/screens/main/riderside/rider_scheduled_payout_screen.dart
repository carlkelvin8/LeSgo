import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _savePayout() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rider_payout_frequency', _frequency);
      await prefs.setInt('rider_payout_weekly_day', _weeklyDay);
      await prefs.setInt('rider_payout_monthly_day', _monthlyDay);
      await prefs.setString(
        'rider_payout_threshold',
        _thresholdController.text,
      );
      if (_selectedAccount != null) {
        await prefs.setString('rider_payout_account', _selectedAccount!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scheduled payout saved')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Scheduled Payout',
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
                groupValue: _frequency,
                activeColor: const Color(0xFF5F2D82),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
            );
          }),
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
                  groupValue: _selectedAccount,
                  activeColor: const Color(0xFF5F2D82),
                  onChanged: (v) =>
                      setState(() => _selectedAccount = v!),
                ),
              );
            }),
          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.buttonHeight(context),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              onPressed: _selectedAccount == null || _isLoading
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
