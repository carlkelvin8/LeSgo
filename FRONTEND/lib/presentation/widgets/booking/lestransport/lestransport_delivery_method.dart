import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/validators/lestransport_validator.dart';
import '../../../../domain/entities/booking/lestransport/lestransport_booking.dart';
import '../../../provider/main/booking/lestransport_provider.dart';
import '../../widgets.dart';

class LestransportDeliveryMethod extends ConsumerWidget {
  final TextEditingController branchAddressController;

  const LestransportDeliveryMethod({
    super.key,
    required this.branchAddressController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lestransportProvider);
    final notifier = ref.read(lestransportProvider.notifier);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup Door-to-door option
          GestureDetector(
            onTap: () => notifier.updateDeliveryMethod(DeliveryMethod.pickupDoorToDoor),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.deliveryMethod == DeliveryMethod.pickupDoorToDoor
                                ? const Color(0xFF5F2D82)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: state.deliveryMethod == DeliveryMethod.pickupDoorToDoor
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF5F2D82),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Pickup Door-to-door',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          
          // Padala by going to the branch option
          GestureDetector(
            onTap: () => notifier.updateDeliveryMethod(DeliveryMethod.padalaToBranch),
            child: Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.deliveryMethod == DeliveryMethod.padalaToBranch
                                ? const Color(0xFF5F2D82)
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: state.deliveryMethod == DeliveryMethod.padalaToBranch
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF5F2D82),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Padala by going to the branch',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Branch address field (only visible when padalaToBranch is selected)
          if (state.deliveryMethod == DeliveryMethod.padalaToBranch)
            Padding(
              padding: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 32),
                top: ResponsiveUtils.spacing(context, 8),
              ),
              child: CustomTextField(
                controller: branchAddressController,
                labelText: 'Branch Address',
                keyboardType: TextInputType.streetAddress,
                validator: (value) => LestransportValidator.branchAddress(
                  value,
                  isRequired: state.deliveryMethod == DeliveryMethod.padalaToBranch,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
