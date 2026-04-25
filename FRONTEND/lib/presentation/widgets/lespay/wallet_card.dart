import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class WalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.balance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(48),
          child: SizedBox(
            height: ResponsiveUtils.imageHeight(context, 200),
            child: Stack(
              children: [
                // Background SVG
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/lespay/Background.svg',
                    fit: BoxFit.cover
                  ),
                ),
        
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Php ${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(context, 32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
      
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: ResponsiveUtils.spacing(context, 24),
                  child: Center(
                    child: Text(
                      'My LesPay wallet',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
