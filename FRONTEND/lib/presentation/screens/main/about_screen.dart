import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: ResponsiveUtils.fontSize(context, 20),
            color: Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About LeSgo',
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: ResponsiveUtils.fontSize(context, 80),
              color: const Color(0xFF5F2D82),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            Text(
              'About LeSgo Screen',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
