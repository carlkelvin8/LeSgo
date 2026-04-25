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

    // Add listeners to update state
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
    if (_controllers.validate()) {
      final notifier = ref.read(lestransportProvider.notifier);
      await notifier.bookTransport();

      final state = ref.read(lestransportProvider);
      if (state.error != null) {
        if (mounted) {
          SnackBarUtils.showError(context, state.error!);
        }
      } else if (!state.isLoading) {
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Booking successful!');
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lestransportProvider);
    final maxWidth = ResponsiveUtils.maxContentWidth(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const BookingServiceHeader(title: 'LesTransport'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _controllers.formKey,
              child: Column(
                children: [
                  LesportFormSection(controllers: _controllers),
                  const LestransportSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: 'Book',
            onPressed: state.isLoading ? null : _handleBooking,
            isLoading: state.isLoading,
          ),
        ),
      ),
    );
  }
}
