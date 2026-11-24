import 'dart:async';

import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/referral_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/data_source/social_remote_datasource.dart';
import '../../provider/main/referral/referral_provider.dart';

const _brand = Color(0xFF5F2D82);

/// Bottom sheet for sharing the customer's referral code: what they earn, how
/// it works, their code on a ticket, and one-tap share / copy.
class InviteFriendsSheet extends ConsumerStatefulWidget {
  const InviteFriendsSheet({
    super.key,
    required this.referralCode,
    this.userName,
  });

  final String referralCode;
  final String? userName;

  static Future<void> show(
    BuildContext context, {
    required String referralCode,
    String? userName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          InviteFriendsSheet(referralCode: referralCode, userName: userName),
    );
  }

  @override
  ConsumerState<InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<InviteFriendsSheet> {
  Timer? _copiedTimer;
  _Copied _copied = _Copied.none;

  bool get _hasCode => widget.referralCode.trim().isNotEmpty;

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  String get _message => ReferralUtils.inviteMessage(
    referralCode: widget.referralCode,
    userName: widget.userName,
  );

  void _flash(_Copied what) {
    HapticFeedback.lightImpact();
    _copiedTimer?.cancel();
    setState(() => _copied = what);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = _Copied.none);
    });
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.referralCode));
    _flash(_Copied.code);
  }

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: _message));
    _flash(_Copied.message);
    if (mounted) SnackBarUtils.showSuccess(context, 'Invite message copied!');
  }

  Future<void> _share() async {
    final message =
        '${ReferralUtils.referralShareMessage(referralCode: widget.referralCode)}\n'
        '${ReferralUtils.appStoreUrl}';
    final box = context.findRenderObject() as RenderBox?;
    try {
      final generated = await getIt<SocialRemoteDataSource>()
          .generateReferralShare();
      if (generated.shareId > 0) {
        await getIt<SocialRemoteDataSource>().trackShareEngagement(
          generated.shareId,
          action: 'share',
        );
      }
    } catch (_) {
      // Tracking is best-effort; the share text is built locally.
    }
    await Share.share(
      message,
      subject: 'Join me on ${ReferralUtils.appName}',
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    final stats = ref.watch(referralDashboardProvider);
    final showStats =
        !stats.isLoading && (stats.friendsJoined > 0 || stats.pointsEarned > 0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spacing(context, 20),
          ResponsiveUtils.spacing(context, 12),
          ResponsiveUtils.spacing(context, 20),
          ResponsiveUtils.spacing(context, 20) +
              MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context, Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _Hero(),
            if (showStats) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatPill(
                    icon: Icons.group_rounded,
                    value: '${stats.friendsJoined}',
                    label: 'Friends joined',
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    icon: Icons.stars_rounded,
                    value: '${stats.pointsEarned}',
                    label: 'Points earned',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            const _Steps(),
            const SizedBox(height: 18),
            _CodeTicket(
              code: widget.referralCode,
              hasCode: _hasCode,
              copied: _copied == _Copied.code,
              onCopy: _hasCode ? _copyCode : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _hasCode ? _share : null,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share invite link'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.buttonFill(context),
                foregroundColor: AppColors.onButton(context),
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _hasCode ? _copyMessage : null,
              icon: Icon(
                _copied == _Copied.message
                    ? Icons.check_rounded
                    : Icons.copy_rounded,
                size: 18,
              ),
              label: Text(
                _copied == _Copied.message ? 'Copied' : 'Copy invite message',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                AppRouter.push(context, MainRoutes.referralDashboard);
              },
              child: const Text('See my referral rewards'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Copied { none, code, message }

/// Premium header: brand gradient with soft shapes and a gift.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B1A56), Color(0xFF7B2DA8), Color(0xFFB72AC8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -34,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -44,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite friends,\nearn together',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 24,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When a friend joins with your code and places an order, you both earn points.',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      color: AppColors.foreground(
                        context,
                        const Color(0xFF6E6277),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  static const _items = [
    (Icons.ios_share_rounded, 'Share your code'),
    (Icons.person_add_alt_1_rounded, 'Friend signs up'),
    (Icons.stars_rounded, 'You both earn'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.1),
                  ),
                  child: Icon(_items[i].$1, color: accent, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  _items[i].$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: AppColors.foreground(
                      context,
                      const Color(0xFF2A2032),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i < _items.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.foreground(context, const Color(0xFFC3B6CD)),
                size: 20,
              ),
            ),
        ],
      ],
    );
  }
}

/// The referral code on a dashed "ticket" with a copy pill.
class _CodeTicket extends StatelessWidget {
  const _CodeTicket({
    required this.code,
    required this.hasCode,
    required this.copied,
    required this.onCopy,
  });

  final String code;
  final bool hasCode;
  final bool copied;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    return CustomPaint(
      painter: _DashedRRect(accent.withValues(alpha: 0.5)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR CODE',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.foreground(
                        context,
                        const Color(0xFF8B729C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      hasCode ? code : 'Getting your code…',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: hasCode ? 26 : 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: hasCode ? 3 : 0,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: copied ? 'Code copied' : 'Copy code',
              child: GestureDetector(
                onTap: onCopy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: copied ? const Color(0xFF2E9E5B) : accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        copied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        copied ? 'Copied' : 'Copy',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRect old) => old.color != color;
}
