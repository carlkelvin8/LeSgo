import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_duty_provider.dart';

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

    final isOnDuty = ref.read(riderDutyProvider);
    if (wantOnDuty == isOnDuty) return;

    if (!wantOnDuty) {
      await ref.read(riderDutyProvider.notifier).setOnDuty(false);
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Photo'),
        content: const Text(
          'Kailangan ng attendance photo bago maging ON DUTY. '
          'Kunan ng selfie na nakasuot ng uniform para ma-verify.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Camera'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance photo na-upload. Naka ON DUTY ka na.'),
          backgroundColor: Color(0xFF5F2D82),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnDuty = ref.watch(riderDutyProvider);

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
          Switch(
            value: isOnDuty,
            onChanged: _handleToggle,
            activeTrackColor: const Color(0xFF5F2D82),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade400,
          ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Text(
          _isProcessing
              ? 'UPLOADING...'
              : (isOnDuty ? 'ON DUTY' : 'OFF DUTY'),
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
