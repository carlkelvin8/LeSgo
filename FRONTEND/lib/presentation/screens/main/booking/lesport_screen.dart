import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/booking/lestransport_provider.dart';
import '../../../provider/main/booking/controller/lestransport.controller.notifier.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LesportScreen extends ConsumerStatefulWidget {
  const LesportScreen({super.key});

  @override
  ConsumerState<LesportScreen> createState() => _LesportScreenState();
}

class _LesportScreenState extends ConsumerState<LesportScreen> {
  late final LestransportControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = LestransportControllers();

    _controllers.nameController.addListener(() {
      ref
          .read(lestransportProvider.notifier)
          .updateSenderName(_controllers.nameController.text);
    });
    _controllers.contactController.addListener(() {
      ref
          .read(lestransportProvider.notifier)
          .updateContactNumber(_controllers.contactController.text);
    });
    _controllers.addressController.addListener(() {
      ref
          .read(lestransportProvider.notifier)
          .updateAddress(_controllers.addressController.text);
    });
    _controllers.branchAddressController.addListener(() {
      ref
          .read(lestransportProvider.notifier)
          .updateBranchAddress(_controllers.branchAddressController.text);
    });
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _handleBooking() async {
    if (!_controllers.validate()) return;

    final success = await ref
        .read(lestransportProvider.notifier)
        .bookTransport(context);

    if (!success && mounted) {
      final error = ref.read(lestransportProvider).error;
      if (error != null) {
        SnackBarUtils.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lestransportProvider);
    final maxWidth = ResponsiveUtils.maxContentWidth(context);

    return Scaffold(
      backgroundColor: OrderDesign.canvas(context),
      appBar: const BookingServiceHeader(
        title: 'LesTransport',
        orderStyle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _controllers.formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const OrderReceiptHeader(
                      title: 'Plan your shipment',
                      detail: 'Sender and delivery details',
                      icon: Icons.local_shipping_outlined,
                    ),
                    LesportFormSection(controllers: _controllers),
                    BookingPaymentMethodSection(
                      selectedMethod: state.paymentMethod,
                      onMethodChanged: ref
                          .read(lestransportProvider.notifier)
                          .updatePaymentMethod,
                      minimumAmount: state.totalOrder,
                    ),
                    const LestransportSummary(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: OrderDesign.dock(context),
        child: SafeArea(
          child: OrderActionWithTotal(
            total: state.totalOrder,
            child: PrimaryButton(
              text: 'Book',
              onPressed: state.isLoading ? null : _handleBooking,
              isLoading: state.isLoading,
            ),
          ),
        ),
      ),
    );
  }
}
