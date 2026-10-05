import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';
import '../../../provider/main/booking/controller/lestransport.controller.notifier.dart';

class LesportFormSection extends StatelessWidget {
  const LesportFormSection({super.key, required this.controllers});

  final LestransportControllers controllers;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LestransportUserInfo(
            userName: 'Juan Dela Cruz',
            userLocation: 'Brgy 6, Claveria, Cagayan',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          const LestransportCoverageMap(),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          LestransportSenderForm(
            nameController: controllers.nameController,
            contactController: controllers.contactController,
            addressController: controllers.addressController,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          LestransportDeliveryMethod(
            branchAddressController: controllers.branchAddressController,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
      ),
    );
  }
}
