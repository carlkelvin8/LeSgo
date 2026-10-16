import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class VerificationContent extends StatelessWidget {
  const VerificationContent({
    super.key,
    required this.selfiePath,
    required this.idType,
    required this.idNumber,
    required this.validIdFrontPath,
    required this.validIdBackPath,
    required this.isLoading,
    required this.onCaptureSelfie,
    required this.onCaptureIdFront,
    required this.onCaptureIdBack,
    required this.onIdTypeChanged,
    required this.onIdNumberChanged,
    required this.onNext,
  });

  static const Map<String, String> idTypes = {
    'philippine_national_id': 'Philippine National ID',
    'drivers_license': "Driver's License",
    'passport': 'Passport',
    'umid': 'UMID',
    'sss_id': 'SSS ID',
    'postal_id': 'Postal ID',
    'voters_id': "Voter's ID",
    'prc_id': 'PRC ID',
  };

  final String selfiePath;
  final String idType;
  final String idNumber;
  final String validIdFrontPath;
  final String validIdBackPath;
  final bool isLoading;
  final Future<void> Function() onCaptureSelfie;
  final Future<void> Function() onCaptureIdFront;
  final Future<void> Function() onCaptureIdBack;
  final ValueChanged<String> onIdTypeChanged;
  final ValueChanged<String> onIdNumberChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.spacing(context, 16);

    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'SIGN UP'),
          SizedBox(height: spacing),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Identity Verification',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 22),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Required: take a live selfie and clear photos of your government ID using the camera.',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: AppColors.foreground(context, Colors.grey.shade700),
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: spacing),
                  _CaptureCard(
                    title: '1. Live selfie',
                    subtitle:
                        'Face the camera in a bright area. No masks, filters, or screenshots.',
                    imagePath: selfiePath,
                    icon: Icons.face_retouching_natural,
                    buttonText: selfiePath.isEmpty
                        ? 'Capture Selfie'
                        : 'Retake Selfie',
                    onPressed: isLoading ? null : onCaptureSelfie,
                    circularPreview: true,
                  ),
                  SizedBox(height: spacing),
                  DropdownButtonFormField<String>(
                    initialValue: idType.isEmpty ? null : idType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Government ID type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: idTypes.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) onIdTypeChanged(value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: idNumber,
                    enabled: !isLoading,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: onIdNumberChanged,
                    decoration: const InputDecoration(
                      labelText: 'ID number *',
                      hintText: 'Enter the number shown on your ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  SizedBox(height: spacing),
                  _CaptureCard(
                    title: '2. Front of ID',
                    subtitle:
                        'Keep all four corners visible and make sure the details are readable.',
                    imagePath: validIdFrontPath,
                    icon: Icons.credit_card,
                    buttonText: validIdFrontPath.isEmpty
                        ? 'Capture ID Front'
                        : 'Retake ID Front',
                    onPressed: isLoading ? null : onCaptureIdFront,
                  ),
                  SizedBox(height: spacing),
                  _CaptureCard(
                    title: '3. Back of ID',
                    subtitle:
                        'Capture the back side or supporting page of the same ID.',
                    imagePath: validIdBackPath,
                    icon: Icons.credit_card,
                    buttonText: validIdBackPath.isEmpty
                        ? 'Capture ID Back'
                        : 'Retake ID Back',
                    onPressed: isLoading ? null : onCaptureIdBack,
                  ),
                  SizedBox(height: spacing),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context, Color(0xFFF4E8FA)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFF5F2D82)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your photos are securely submitted for identity review and are not taken from the gallery.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing),
                ],
              ),
            ),
          ),
          PrimaryButton(
            text: 'Continue',
            onPressed: isLoading ? null : onNext,
            backgroundColor: const Color(0xFF5F2D82),
            isLoading: isLoading,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.buttonText,
    required this.onPressed,
    this.circularPreview = false,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final String buttonText;
  final Future<void> Function()? onPressed;
  final bool circularPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.grey.shade50),
        border: Border.all(
          color: imagePath.isEmpty
              ? AppColors.foreground(context, Colors.grey.shade300)
              : AppColors.accent(context, Color(0xFF5F2D82)),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: AppColors.foreground(context, Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 12),
          if (imagePath.isNotEmpty)
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(circularPreview ? 80 : 10),
                child: SizedBox(
                  width: circularPreview ? 150 : double.infinity,
                  height: circularPreview ? 150 : 180,
                  child: kIsWeb
                      ? Image.network(imagePath, fit: BoxFit.cover)
                      : Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              ),
            )
          else
            Container(
              height: 110,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 48, color: AppColors.foreground(context, Colors.grey.shade500)),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
