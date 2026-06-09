import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class WalletCard extends StatelessWidget {
  final double balance;
  final bool balanceVisible;
  final VoidCallback? onTap;
  final VoidCallback? onToggleVisibility;

  const WalletCard({
    super.key,
    required this.balance,
    this.balanceVisible = true,
    this.onTap,
    this.onToggleVisibility,
  });

  String get _balanceLabel =>
      balanceVisible ? 'Php ${balance.toStringAsFixed(2)}' : '••••••';

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
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/lespay/Background.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                if (onToggleVisibility != null)
                  Positioned(
                    top: ResponsiveUtils.spacing(context, 16),
                    right: ResponsiveUtils.spacing(context, 16),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        tooltip: balanceVisible
                            ? 'Hide balance'
                            : 'Show balance',
                        onPressed: onToggleVisibility,
                        icon: Icon(
                          balanceVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white,
                          size: ResponsiveUtils.fontSize(context, 22),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      _balanceLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: Colors.white,
                        fontSize: ResponsiveUtils.fontSize(
                          context,
                          balanceVisible ? 32 : 28,
                        ),
                        fontWeight: FontWeight.bold,
                        letterSpacing: balanceVisible ? 0 : 4,
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
