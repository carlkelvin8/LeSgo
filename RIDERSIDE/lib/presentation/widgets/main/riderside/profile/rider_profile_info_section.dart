import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';
import '../more/rider_more_components.dart';
import 'profile_panel.dart';

class RiderProfileInfoSection extends ConsumerWidget {
  const RiderProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(riderProfileProvider);
    final user = ref.watch(riderAuthProvider).user;
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);
    String value(String text) => text.trim().isEmpty ? t('rp_not_added') : text;
    final code = profile.referralCode.trim();

    final details = [
      _DetailItem(
        icon: Icons.phone_outlined,
        label: t('contact_number'),
        value: value(
          profile.contact.isNotEmpty ? profile.contact : user?.phone ?? '',
        ),
        accent: const Color(0xFF187C69),
      ),
      _DetailItem(
        icon: Icons.two_wheeler_outlined,
        label: t('rp_vehicle'),
        value: value(profile.vehicle),
        accent: const Color(0xFF317B9C),
      ),
      _DetailItem(
        icon: Icons.pin_outlined,
        label: t('plate_number'),
        value: value(profile.plateNumber),
        accent: const Color(0xFF6D3EA0),
      ),
      _DetailItem(
        icon: Icons.location_on_outlined,
        label: t('address'),
        value: value(profile.address),
        accent: const Color(0xFFB3546C),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoreSectionHeading(title: t('rp_details')),

        // ── 2×2 detail grid ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: profileDark(context)
                ? const Color(0xFF1E1730)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: profileDark(context)
                  ? const Color(0xFF2E2540)
                  : const Color(0xFFEDE9F2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF5F2D82,
                ).withValues(alpha: profileDark(context) ? .08 : .04),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, size) {
              final single =
                  size.maxWidth < 270 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              if (single) {
                return Column(
                  children: [
                    for (var i = 0; i < details.length; i++) ...[
                      if (i > 0)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 58),
                          color: profileDark(context)
                              ? const Color(0xFF2E2540)
                              : const Color(0xFFF0EBF6),
                        ),
                      _AnimatedTile(item: details[i], index: i),
                    ],
                  ],
                );
              }
              // 2-column grid
              return Column(
                children: [
                  for (var row = 0; row < 2; row++) ...[
                    if (row > 0)
                      Container(
                        height: 1,
                        color: profileDark(context)
                            ? const Color(0xFF2E2540)
                            : const Color(0xFFF0EBF6),
                      ),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _AnimatedTile(
                              item: details[row * 2],
                              index: row * 2,
                            ),
                          ),
                          Container(
                            width: 1,
                            color: profileDark(context)
                                ? const Color(0xFF2E2540)
                                : const Color(0xFFF0EBF6),
                          ),
                          Expanded(
                            child: _AnimatedTile(
                              item: details[row * 2 + 1],
                              index: row * 2 + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ── Referral code card ───────────────────────────────────────────
        _ReferralCard(code: code, t: t),
      ],
    );
  }
}

// ─── Animated tile ────────────────────────────────────────────────────────────
class _AnimatedTile extends StatefulWidget {
  final _DetailItem item;
  final int index;
  const _AnimatedTile({required this.item, required this.index});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - .02 * _press.value, child: child),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.item.accent.withValues(
                    alpha: profileDark(context) ? .18 : .09,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 16,
                  color: widget.item.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .3,
                        color: profileMuted(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.value,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: profileText(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Referral card ────────────────────────────────────────────────────────────
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
          color: isDark ? const Color(0xFF1E1730) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2),
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
                      color: profileMuted(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.code.isEmpty
                        ? widget.t('rp_not_added')
                        : widget.code,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: widget.code.isEmpty ? 0 : 2,
                      color: profileText(context),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.code.isNotEmpty)
              Tooltip(
                message: 'Copy referral code',
                child: GestureDetector(
                  onTap: _copy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _copied
                          ? const Color(0xFF22A060)
                          : accent.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: _copied ? Colors.white : accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _copied ? Colors.white : accent,
                          ),
                        ),
                      ],
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

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
}
