import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/rider_commission_utils.dart';
import '../../../../provider/auth/rider_auth_provider.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';
import '../../../../screens/main/riderside/rider_edit_profile_screen.dart';

class RiderProfileHeader extends ConsumerStatefulWidget {
  const RiderProfileHeader({super.key});
  @override
  ConsumerState<RiderProfileHeader> createState() => _RiderProfileHeaderState();
}

class _RiderProfileHeaderState extends ConsumerState<RiderProfileHeader>
    with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  bool _picking = false;

  // Continuous bg animation
  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  // Shimmer sweep
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  // Avatar entrance bounce
  late final AnimationController _avatarBounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _avatarScale = CurvedAnimation(
    parent: _avatarBounce,
    curve: Curves.elasticOut,
  );

  // Edit button press
  late final AnimationController _btnPress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _avatarBounce.forward();
    });
  }

  @override
  void dispose() {
    _bg.dispose();
    _shimmer.dispose();
    _avatarBounce.dispose();
    _btnPress.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_picking) return;
    HapticFeedback.mediumImpact();
    setState(() => _picking = true);
    final lang = ref.read(appLanguageProvider);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      final success = await ref
          .read(riderProfileProvider.notifier)
          .uploadProfilePicture(image);
      if (!mounted) return;
      // Re-trigger bounce on success
      if (success) _avatarBounce.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.translate(
              success ? 'profile_picture_updated' : 'rp_photo_failed',
              lang,
            ),
          ),
          backgroundColor: success
              ? const Color(0xFF22A060)
              : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (error) {
      AppLogger.error('Error picking image', error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(riderProfileProvider);
    final user = ref.watch(riderAuthProvider).user;
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);
    final name = profile.name.trim().isNotEmpty
        ? profile.name.trim()
        : (user?.name.trim() ?? '');
    final photo = profile.profilePictureUrl ?? user?.profilePhotoUrl;
    final busy = _picking || profile.isUploading;

    return AnimatedBuilder(
      animation: Listenable.merge([_bg, _shimmer]),
      builder: (_, __) => Container(
        constraints: const BoxConstraints(minHeight: 260),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29113F), Color(0xFF63368C), Color(0xFF78479E)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF5F2D82,
              ).withValues(alpha: .28 + .08 * _bg.value),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRect(
          child: CustomPaint(
            painter: _HeaderBgPainter(t: _bg.value, sweep: _shimmer.value),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Bouncy avatar
                        ScaleTransition(
                          scale: _avatarScale,
                          child: _Avatar(
                            photo: photo,
                            name: name,
                            busy: busy,
                            onTap: busy ? null : _pickAndUploadImage,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('rp_hello'),
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: .65),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name.isEmpty ? t('rp_rider') : name,
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 22,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.4,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Badge(
                                    icon: Icons.two_wheeler_rounded,
                                    label: t('rp_rider'),
                                    pulse: _bg.value,
                                  ),
                                  _Badge(
                                    icon: Icons.workspace_premium_outlined,
                                    label: RiderCommissionUtils.labelForPackage(
                                      user?.packageTier,
                                    ),
                                    pulse: _bg.value,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Edit button with press animation
                    GestureDetector(
                      onTapDown: (_) {
                        HapticFeedback.selectionClick();
                        _btnPress.forward();
                      },
                      onTapUp: (_) => _btnPress.reverse(),
                      onTapCancel: () => _btnPress.reverse(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RiderEditProfileScreen(),
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _btnPress,
                        builder: (_, child) => Transform.scale(
                          scale: 1.0 - .03 * _btnPress.value,
                          child: child,
                        ),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: Color(0xFF5F2D82),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  t('edit_profile'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Color(0xFF532779),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatefulWidget {
  final String? photo;
  final String name;
  final bool busy;
  final VoidCallback? onTap;

  const _Avatar({
    required this.photo,
    required this.name,
    required this.busy,
    this.onTap,
  });

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        widget.name.isEmpty ? 'L' : widget.name.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F2D82),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _ring,
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Pulsing glow ring
            Positioned(
              top: -4,
              left: -4,
              right: -4,
              bottom: -4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: .25 + .20 * _ring.value,
                    ),
                    width: 2,
                  ),
                ),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: ColoredBox(
                  color: const Color(0xFFF0E7F8),
                  child: widget.photo == null || widget.photo!.isEmpty
                      ? fallback
                      : Image.network(
                          widget.photo!,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -.65),
                          errorBuilder: (_, __, ___) => fallback,
                          loadingBuilder: (_, child, p) =>
                              p == null ? child : fallback,
                        ),
                ),
              ),
            ),
            // Camera badge
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F0B8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF44205F),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: widget.busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF44205F),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        size: 14,
                        color: Color(0xFF44205F),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final double pulse;

  const _Badge({required this.icon, required this.label, required this.pulse});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .10 + .04 * pulse),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withValues(alpha: .18 + .08 * pulse),
        width: .8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFE6D8F2), size: 13),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              color: Color(0xFFE6D8F2),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Background painter ───────────────────────────────────────────────────────
class _HeaderBgPainter extends CustomPainter {
  final double t; // 0→1 bg aurora
  final double sweep; // 0→1 shimmer

  const _HeaderBgPainter({required this.t, required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF29113F),
            Color(0xFF63368C),
            Color(0xFF78479E),
          ],
        ).createShader(rect),
    );

    // Drifting aurora
    final orbX = size.width * (.60 + .25 * t);
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFFAA55EE).withValues(alpha: .30),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(orbX, -size.height * .15),
                radius: size.width * .70,
              ),
            ),
    );

    // Bottom glow
    canvas.drawRect(
      rect,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(0xFF3A0D60).withValues(alpha: .50),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * .5, size.height * 1.1),
                radius: size.width * .65,
              ),
            ),
    );

    // Concentric rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final rc = Offset(size.width * 1.1, size.height * .05);
    for (var i = 0; i < 5; i++) {
      ringPaint.color = Colors.white.withValues(alpha: .035 + i * .010);
      canvas.drawCircle(rc, size.width * (.20 + i * .11), ringPaint);
    }

    // Shimmer sweep
    final bx = -size.width * .35 + size.width * 1.7 * sweep;
    canvas.save();
    canvas.transform(
      Matrix4(
        math.cos(math.pi / 10),
        math.sin(math.pi / 10),
        0,
        0,
        -math.sin(math.pi / 10),
        math.cos(math.pi / 10),
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        -size.height * .18,
        0,
        1,
      ).storage,
    );
    canvas.drawRect(
      Rect.fromLTWH(bx, -20, size.width * .18, size.height * 1.6),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .07),
            Colors.white.withValues(alpha: .11),
            Colors.white.withValues(alpha: .07),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(bx, 0, size.width * .18, size.height)),
    );
    canvas.restore();

    // Top shimmer line
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.5),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .28 + .10 * t),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5)),
    );
  }

  @override
  bool shouldRepaint(covariant _HeaderBgPainter old) =>
      old.t != t || old.sweep != sweep;
}
