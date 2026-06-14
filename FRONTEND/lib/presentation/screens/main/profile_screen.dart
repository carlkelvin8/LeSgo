import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/profile/profile_provider.dart';
import '../../provider/main/profile/controller/profile.controller.notifier.dart';
import '../../widgets/widgets.dart';
import '../../widgets/common/retry_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late ProfileControllers _controllers;

  @override
  void initState() {
    super.initState();
    final profileState = ref.read(profileProvider);
    _controllers = ProfileControllers(
      name: profileState.name,
      address1: profileState.address1,
      address2: profileState.address2,
    );
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5F2D82),
              ),
            )
          : profileState.error != null && profileState.user == null
              ? RetryWidget(
                  message: profileState.error!,
                  isLoading: profileState.isLoading,
                  onRetry: () =>
                      ref.read(profileProvider.notifier).refreshProfile(),
                )
              : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                      child: const AuthHeader(
                        title: 'Profile',
                      ),
                    ),
                    
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: ProfileHeader(
                        name: profileState.name,
                        birthdate: profileState.birthdate,
                        email: profileState.email,
                        phone: profileState.phone,
                        profileImageUrl: profileState.profileImageUrl,
                        onImageTap: () => _controllers.showImagePicker(context, ref),
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
      
                    ProfileEditSection(
                      controllers: _controllers,
                    ),
                    
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    
                    ProfileRewardsSection(
                      referralCode: profileState.referralCode,
                      points: profileState.points,
                      userName: profileState.name,
                    ),

                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),

                    const ProfileAccountSection(),
                    
                    SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                  ],
                ),
              ),
            ),
    );
  }
}


