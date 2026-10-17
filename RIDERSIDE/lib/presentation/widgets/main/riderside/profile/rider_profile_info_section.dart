import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';
import 'profile_panel.dart';

/// Referral stays available while personal information is managed in Edit Profile.
class RiderProfileInfoSection extends ConsumerWidget {
  const RiderProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(riderProfileProvider);
    final lang = ref.watch(appLanguageProvider);
    return _ReferralCard(
      code: profile.referralCode.trim(),
      t: (key) => AppLocalization.translate(key, lang),
    );
  }
}

class _ReferralCard extends StatefulWidget {
  final String code;
  final String Function(String) t;
  const _ReferralCard({required this.code, required this.t});

  @override
  State<_ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<_ReferralCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _burstScale = Tween<double>(
    begin: 1.0,
    end: 1.06,
  ).animate(CurvedAnimation(parent: _burst, curve: Curves.elasticOut));

  bool _copied = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (widget.code.isEmpty) return;
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    _burst.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = profileDark(context);
    final accent = isDark ? const Color(0xFFD3B1F1) : const Color(0xFF6D3EA0);

    return ScaleTransition(
      scale: _burstScale,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF281D38) : const Color(0xFFF4EFFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF403050) : const Color(0xFFE8DEF2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF5F2D82,
              ).withValues(alpha: isDark ? .08 : .04),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 20,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.t('referral_code'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
                      color: profileMuted(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.code.isEmpty
                        ? widget.t('rp_not_added')
                        : widget.code,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: widget.code.isEmpty ? 0 : 1.2,
                      color: profileText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.code.isNotEmpty)
              Tooltip(
                message: 'Copy referral code',
                child: TextButton.icon(
                  onPressed: _copy,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _copied
                        ? const Color(0xFF187C69)
                        : const Color(0xFF5F2D82),
                    minimumSize: const Size(76, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_outlined,
                    size: 17,
                  ),
                  label: Text(
                    _copied ? 'Copied!' : 'Copy',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
