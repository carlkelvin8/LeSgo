import '../../../core/utils/date_display_utils.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../../provider/main/profile/controller/profile.controller.notifier.dart';
import '../../widgets/profile/change_phone_sheet.dart';
import '../../widgets/widgets.dart';
import '../../widgets/common/retry_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ProfileControllers _controllers;

  @override
  void initState() {
    super.initState();
    final state = ref.read(profileProvider);
    _controllers = ProfileControllers(
      name: state.name,
      address1: state.address1,
      address2: state.address2,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(profileProvider.notifier).refreshPoints();
    });
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  void _openSheet(String title, Widget child) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface(context, const Color(0xFFFAF9FC)),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(String route) => AppRouter.push(context, route);
  void _sync(TextEditingController c, String before, String after) {
    if (before != after && c.text == before) c.text = after;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev == null) return;
      _sync(_controllers.nameController, prev.name, next.name);
      _sync(_controllers.address1Controller, prev.address1, next.address1);
      _sync(_controllers.address2Controller, prev.address2, next.address2);
    });

    if (state.isLoading && state.user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface(context, const Color(0xFFFAF8FC)),
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (state.error != null && state.user == null) {
      return Scaffold(
        backgroundColor: AppColors.surface(context, const Color(0xFFFAF8FC)),
        appBar: AppBar(title: const Text('Profile')),
        body: RetryWidget(
          message: state.error!,
          onRetry: () => ref.read(profileProvider.notifier).refreshProfile(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface(context, const Color(0xFFFAF8FC)),
      body: RefreshIndicator(
        color: AppColors.accent(context, const Color(0xFF5F2D82)),
        displacement: 80,
        onRefresh: () async {
          if (!state.isUpdating) {
            await ref.read(profileProvider.notifier).refreshProfile();
          }
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surface(
                context,
                const Color(0xFFFAF8FC),
              ),
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              titleSpacing: 4,
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => _go(MainRoutes.settings),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 21,
                    color: AppColors.foreground(
                      context,
                      const Color(0xFF292235),
                    ),
                  ),
                ),
              ],
              leading: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.foreground(context, const Color(0xFF292235)),
                ),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 22),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground(context, const Color(0xFF292235)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ProfileHeroSection(
                name: state.name,
                profileImageUrl: state.profileImageUrl,
                email: state.email,
                phone: state.phone,
                birthdate: state.birthdate,
                onImageTap: state.isUpdating
                    ? null
                    : () => _controllers.showImagePicker(context, ref),
                onChangePhoneTap: state.isUpdating
                    ? null
                    : () => ChangePhoneSheet.show(context, state.phone),
              ),
            ),
            // ── Loading / error banners ────────────────────────────────
            if (state.isLoading)
              SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Colors.transparent,
                ),
              ),
            if (state.error != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ApiErrorMapper.message(state.error!),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Content ───────────────────────────────────────────────
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).padding.bottom + 36,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ShortcutGrid(
                    offers: _Shortcut(
                      icon: Icons.local_offer_outlined,
                      title: 'Offers',
                      subtitle: 'Discover your offers',
                      onTap: () => _go(MainRoutes.offers),
                    ),
                    rewards: _Shortcut(
                      icon: Icons.auto_awesome_outlined,
                      title: '${state.points} points',
                      subtitle: 'Rewards',
                      isRewards: true,
                      onTap: () => _go(MainRoutes.loyaltyRedeem),
                    ),
                  ),
                  const _SectionTitle('Personal information'),
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal details',
                        subtitle: 'Edit your name and address details',
                        onTap: () => ProfileEditSection.show(context, _controllers),
                      ),
                      _ProfileRow(
                        icon: Icons.phone_outlined,
                        title: 'Mobile number',
                        subtitle: state.phone.isEmpty
                            ? 'Add your mobile number'
                            : state.phone,
                        onTap: state.isUpdating
                            ? null
                            : () => ChangePhoneSheet.show(context, state.phone),
                      ),
                      if (state.birthdate.isNotEmpty)
                        _ProfileRow(
                          icon: Icons.cake_outlined,
                          title: 'Birthday',
                          subtitle: formatDateOnly(state.birthdate),
                        ),
                      _ProfileRow(
                        icon: Icons.location_on_outlined,
                        title: 'Saved addresses',
                        subtitle: 'Manage your delivery addresses',
                        onTap: () => _go(MainRoutes.addressManagement),
                      ),
                    ],
                  ),
                  const _SectionTitle('Wallet & referrals'),
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Invite your friends',
                        subtitle: 'Share your referral code',
                        onTap: () => _openSheet(
                          'Friends & rewards',
                          ProfileRewardsSection(
                            referralCode: state.referralCode,
                            points: state.points,
                            userName: state.name,
                          ),
                        ),
                      ),
                      _ProfileRow(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'LesPay wallet',
                        subtitle: 'Manage your wallet',
                        onTap: () => _go(MainRoutes.lespay),
                      ),
                    ],
                  ),
                  const _SectionTitle('Support'),
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.headset_mic_outlined,
                        title: 'Chat with support',
                        subtitle: 'Get help from LeSgo',
                        onTap: () => _go(MainRoutes.customerServiceChat),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 26, 0, 10),
    child: Text(
      title,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 18),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.foreground(context, const Color(0xFF25232B)),
      ),
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(
        color: AppColors.border(context, const Color(0xFFECE5F1)),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 69,
              endIndent: 16,
              color: AppColors.border(context, const Color(0xFFECE5F1)),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _ProfileRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface(context, const Color(0xFFF3EBFA)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 21,
              color: AppColors.accent(context, const Color(0xFF634185)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground(
                      context,
                      const Color(0xFF302B36),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      height: 1.35,
                      color: AppColors.foreground(
                        context,
                        const Color(0xFF6C6077),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.foreground(context, const Color(0xFF6C6077)),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.offers, required this.rewards});

  final Widget offers, rewards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      if (constraints.maxWidth < 300 || textScale > 1.3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [offers, const SizedBox(height: 12), rewards],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: offers),
            const SizedBox(width: 12),
            Expanded(child: rewards),
          ],
        ),
      );
    },
  );
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isRewards;

  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isRewards = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final fill = isRewards
        ? (dark ? const Color(0xFF173832) : const Color(0xFFDCF5EB))
        : (dark ? const Color(0xFF352447) : const Color(0xFFF0E4FA));
    final ink = isRewards
        ? (dark ? const Color(0xFFDBFFF2) : const Color(0xFF154638))
        : (dark ? const Color(0xFFF6E8FF) : const Color(0xFF482362));

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(icon, size: 20, color: ink),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.north_east_rounded, size: 16, color: ink),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  height: 1.3,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
