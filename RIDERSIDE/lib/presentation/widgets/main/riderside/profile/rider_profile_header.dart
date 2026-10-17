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

class _RiderProfileHeaderState extends ConsumerState<RiderProfileHeader> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _picking = false;

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
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('profile'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: .72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.isEmpty ? t('rp_rider') : name,
          style: const TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(icon: Icons.two_wheeler_outlined, label: t('rp_rider')),
            _Badge(
              icon: Icons.workspace_premium_outlined,
              label: RiderCommissionUtils.labelForPackage(user?.packageTier),
            ),
          ],
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1545), Color(0xFF693795)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -85,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .06),
                  width: 28,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final avatar = _Avatar(
                      photo: photo,
                      name: name,
                      busy: busy,
                      onTap: busy ? null : _pickAndUploadImage,
                      tooltip: t('edit_profile'),
                    );
                    if (constraints.maxWidth < 270 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatar,
                          const SizedBox(height: 18),
                          identity,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        avatar,
                        const SizedBox(width: 18),
                        Expanded(child: identity),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RiderEditProfileScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF54277B),
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(t('edit_profile')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photo;
  final String name;
  final bool busy;
  final VoidCallback? onTap;
  final String tooltip;
  const _Avatar({
    this.photo,
    required this.name,
    required this.busy,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.isEmpty ? 'L' : name.characters.first.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F2D82),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 82,
          height: 86,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                  ),
                ),
                child: ClipOval(
                  child: ColoredBox(
                    color: const Color(0xFFF3EBF9),
                    child: photo == null || photo!.isEmpty
                        ? fallback
                        : Image.network(
                            photo!,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) =>
                                fallback,
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : fallback,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF563078),
                      width: 2,
                    ),
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: Color(0xFF5F2D82),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: .16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFE8D7F5)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}
