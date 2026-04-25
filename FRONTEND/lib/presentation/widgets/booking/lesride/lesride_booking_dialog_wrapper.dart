import 'dart:ui';
import 'package:flutter/material.dart';
import 'lesride_booking_summary_dialog.dart';

class LesrideBookingDialogWrapper extends StatelessWidget {
  const LesrideBookingDialogWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background covering entire screen
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        // Dialog content
        const LesrideBookingSummaryDialog(),
      ],
    );
  }
}
