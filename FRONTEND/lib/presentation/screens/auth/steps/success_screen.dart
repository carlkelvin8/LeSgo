import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/register/register_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/routers/auth/auth_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class CongratulationsScreen extends ConsumerWidget {
  const CongratulationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider);
    final userData = registerState.data;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  
                  const SuccessHeader(
                    title: 'CONGRATULATIONS!',
                    subtitle: 'You have successfully created your account.',
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                  
            
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/register/9.svg',
                      height: ResponsiveUtils.imageHeight(context, 280),
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                  

                  UserInfoCard(
                    name: '${userData.firstName} ${userData.lastName}',
                    birthday: userData.birthday,
                    email: userData.email,
                    phoneNumber: userData.phoneNumber,
                    avatarWidget: const AvatarIconContainer(
                      svgAsset: 'assets/images/register/10.svg',
                    ),
                  ),
                  
                  const Spacer(),
                  
                  PrimaryButton(
                    text: 'Get Started',
                    onPressed: () {
                      ref.read(registerProvider.notifier).reset();
                      AppRouter.pushAndRemoveUntil(context, LoginRoutes.login);
                    },
                    backgroundColor: const Color(0xFF5F2D82),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
