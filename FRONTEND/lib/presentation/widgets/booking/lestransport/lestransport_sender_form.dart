import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/validators/lestransport_validator.dart';
import '../../widgets.dart';

class LestransportSenderForm extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController contactController;
  final TextEditingController addressController;

  const LestransportSenderForm({
    super.key,
    required this.nameController,
    required this.contactController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sender',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          CustomTextField(
            controller: nameController,
            labelText: 'Name',
            keyboardType: TextInputType.name,
            validator: LestransportValidator.senderName,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          CustomTextField(
            controller: contactController,
            labelText: 'Contact Number',
            keyboardType: TextInputType.phone,
            validator: LestransportValidator.contactNumber,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          CustomTextField(
            controller: addressController,
            labelText: 'Address',
            keyboardType: TextInputType.streetAddress,
            validator: LestransportValidator.senderAddress,
          ),
        ],
      ),
    );
  }
}
