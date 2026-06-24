import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/utils/responsive_utils.dart';
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
            title: Text(AppLocalization.translate('go_off_duty_question', lang)),
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

      await ref.read(riderDutyProvider.notifier).setOnDuty(false);

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

    final error = await ref.read(riderDutyProvider.notifier).goOnDutyWithPhoto(photo);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else {
      await ref.read(riderShiftProvider).recordShiftStart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.translate('attendance_photo_uploaded', lang)),
          backgroundColor: const Color(0xFF5F2D82),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnDuty = ref.watch(riderDutyProvider);

    final lang = ref.watch(appLanguageProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isProcessing)
          SizedBox(
            width: ResponsiveUtils.spacing(context, 24),
            height: ResponsiveUtils.spacing(context, 24),
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Semantics(
            label: isOnDuty
                ? AppLocalization.translate('on_duty_semantics', lang)
                : AppLocalization.translate('off_duty_semantics', lang),
            toggled: isOnDuty,
            child: Switch(
              value: isOnDuty,
              onChanged: _handleToggle,
              activeTrackColor: const Color(0xFF5F2D82),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade400,
            ),
          ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Text(
          _isProcessing
              ? AppLocalization.translate('uploading', lang)
              : (isOnDuty
                  ? AppLocalization.translate('on_duty_label', lang)
                  : AppLocalization.translate('off_duty_label', lang)),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
