import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      decoration: OrderDesign.receipt(context),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrderSectionHeading(
            'Sender',
            icon: Icons.person_outline_rounded,
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
