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
      backgroundColor: AppColors.surface(context, Color(0xFFFAF9FC)),
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
        backgroundColor: AppColors.surface(context, Color(0xFFFEFDFE)),
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
        backgroundColor: AppColors.surface(context, Color(0xFFFEFDFE)),
        appBar: AppBar(title: const Text('Profile')),
        body: RetryWidget(
          message: state.error!,
          onRetry: () => ref.read(profileProvider.notifier).refreshProfile(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface(context, Color(0xFFFEFDFE)),
      body: RefreshIndicator(
        color: AppColors.accent(context, Color(0xFF5F2D82)),
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
              backgroundColor: AppColors.surface(context, Color(0xFFFEFDFE)),
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => _go(MainRoutes.settings),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 21,
                    color: AppColors.foreground(context, Color(0xFF292235)),
                  ),
                ),
              ],
              leading: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.foreground(context, Color(0xFF292235)),
                ),
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground(context, Color(0xFF292235)),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                24,
                0,
                24,
                MediaQuery.of(context).padding.bottom + 36,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.headset_mic_outlined,
                        title: 'Let’s stay connected',
                        subtitle: 'We’re here whenever you need us',
                        onTap: () => _go(MainRoutes.customerServiceChat),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.local_offer_outlined,
                            title: 'Just for you',
                            subtitle: 'Discover your offers',
                            onTap: () => _go(MainRoutes.offers),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Shortcut(
                            icon: Icons.auto_awesome_outlined,
                            title: '${state.points} points',
                            subtitle: 'Your little rewards',
                            onTap: () => _go(MainRoutes.loyaltyRedeem),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _SectionTitle('Personal information'),
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal details',
                        subtitle: 'Your name and delivery addresses',
                        onTap: () => _openSheet(
                          'Personal details',
                          ProfileEditSection(controllers: _controllers),
                        ),
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
                          subtitle: state.birthdate,
                        ),
                      _ProfileRow(
                        icon: Icons.location_on_outlined,
                        title: 'Saved addresses',
                        subtitle: 'Your everyday destinations',
                        onTap: () => _go(MainRoutes.addressManagement),
                      ),
                    ],
                  ),
                  const _SectionTitle('A little extra'),
                  _MenuGroup(
                    children: [
                      _ProfileRow(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Invite your friends',
                        subtitle: 'Share LeSgo. Earn together.',
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
                        subtitle: 'Payments, made simple',
                        onTap: () => _go(MainRoutes.lespay),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'A little easier. Every day.',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: AppColors.foreground(context, Color(0xFFA5A0AB)),
                      ),
                    ),
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
    padding: const EdgeInsets.fromLTRB(2, 24, 0, 10),
    child: Text(
      title,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.foreground(context, Color(0xFF25232B)),
      ),
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface(context, Color(0xFFF5F4F7)),
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 46,
              endIndent: 16,
              color: Theme.of(context).colorScheme.outlineVariant,
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
          Icon(
            icon,
            size: 19,
            color: AppColors.foreground(context, Color(0xFF69626F)),
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
                    color: AppColors.foreground(context, Color(0xFF302B36)),
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
                      color: AppColors.foreground(context, Color(0xFF918A98)),
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
              color: AppColors.foreground(context, Color(0xFF8F8798)),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface(context, Color(0xFFF5F4F7)),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context, Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
                ),
                const Spacer(),
                Icon(
                  Icons.north_east_rounded,
                  size: 14,
                  color: AppColors.foreground(context, Color(0xFFA49BAE)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.foreground(context, Color(0xFF302B36)),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                height: 1.4,
                color: AppColors.foreground(context, Color(0xFF918A98)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
