import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/utils.dart';
import '../../../widgets.dart';

class InfoFormFields extends ConsumerWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;

  const InfoFormFields({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthdayController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Name
        Text(
          'First Name',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: firstNameController,
          hintText: '',
          validator: RegisterValidator.firstName,
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Last Name
        Text(
          'Last Name',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: lastNameController,
          hintText: '',
          validator: RegisterValidator.lastName,
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Birthday
        Text(
          'Birthday',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: birthdayController,
          hintText: 'MM/DD/YYYY',
          validator: RegisterValidator.birthday,
          readOnly: true,
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            color: const Color(0xFF9B59F0),
            size: ResponsiveUtils.imageHeight(context, 20),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF5F2D82),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted =
                  "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
              birthdayController.text = formatted;
            }
          },
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Email
        Text(
          'Email',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        CustomTextField(
          controller: emailController,
          hintText: '',
          validator: RegisterValidator.email,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}
