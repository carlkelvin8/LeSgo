import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_shift_provider.dart';
import '../rider_shift_summary_sheet.dart';

class RiderDutyToggle extends ConsumerStatefulWidget {
  const RiderDutyToggle({super.key});

  @override
  ConsumerState<RiderDutyToggle> createState() => _RiderDutyToggleState();
}

class _RiderDutyToggleState extends ConsumerState<RiderDutyToggle> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _handleToggle(bool wantOnDuty) async {
    if (_isProcessing) return;

    final lang = ref.read(appLanguageProvider);
    final isOnDuty = ref.read(riderDutyProvider);
    if (wantOnDuty == isOnDuty) return;

    if (!wantOnDuty) {
      final activeOrder = ref.read(riderOrdersProvider).activeOrder;
      if (activeOrder != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              AppLocalization.translate('go_off_duty_question', lang),
            ),
            content: Text(
              '${AppLocalization.translate('may_active_order', lang)} (Order #${activeOrder.id}). '
              '${AppLocalization.translate('confirm_go_off_duty', lang)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalization.translate('cancel', lang)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: Text(AppLocalization.translate('go_off_duty', lang)),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }

      setState(() => _isProcessing = true);
      final error = await ref.read(riderDutyProvider.notifier).setOnDuty(false);
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
        );
        return;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const RiderShiftSummarySheet(),
        );
      }
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalization.translate('attendance_photo', lang)),
        content: Text(AppLocalization.translate('need_attendance_photo', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalization.translate('cancel', lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalization.translate('open_camera', lang)),
          ),
        ],
      ),
    );

    if (proceed != true || !mounted) return;

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo == null || !mounted) return;

    setState(() => _isProcessing = true);

    final error = await ref
        .read(riderDutyProvider.notifier)
        .goOnDutyWithPhoto(photo);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    } else {
      await ref.read(riderShiftProvider).recordShiftStart();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.translate('attendance_photo_uploaded', lang),
          ),
          backgroundColor: const Color(0xFF5F2D82),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onDuty = ref.watch(riderDutyProvider);
    final lang = ref.watch(appLanguageProvider);
    final tl = lang == AppLanguage.filipino;
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onDuty ? const Color(0xFF24956A) : colors.outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalization.translate(
                  _isProcessing
                      ? 'uploading'
                      : onDuty
                      ? 'on_duty_label'
                      : 'off_duty_label',
                  lang,
                ),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                onDuty
                    ? (tl
                          ? 'Bukas para sa mga booking'
                          : 'Available for bookings')
                    : (tl
                          ? 'Naka-pause ang mga bagong booking'
                          : 'New bookings are paused'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (_isProcessing)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Semantics(
            label: AppLocalization.translate(
              onDuty ? 'on_duty_semantics' : 'off_duty_semantics',
              lang,
            ),
            toggled: onDuty,
            child: Switch(
              value: onDuty,
              onChanged: _handleToggle,
              activeTrackColor: const Color(0xFF5F2D82),
              activeThumbColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
