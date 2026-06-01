import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/missions/missions_provider.dart';
import '../../widgets/widgets.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsState = ref.watch(missionsProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/mission/Background.svg',
              fit: BoxFit.cover,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                      child: const AuthHeader(
                        title: 'Mission',
                        textColor: Colors.white,
                        iconColor: Colors.white,
                      ),
                    ),

                    Positioned(
                      top: ResponsiveUtils.spacing(context, 35),
                      left: ResponsiveUtils.spacing(context, 6),
                      right: ResponsiveUtils.spacing(context, 6),
                      child: SvgPicture.asset(
                        'assets/images/mission/Banner.svg',
                        height: ResponsiveUtils.imageHeight(context, 300),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 260)),


                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EARN VOUCHERS!',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 20),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        'Complete missions and get vouchers that you can apply to your orders.',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                if (missionsState.error != null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 24),
                      vertical: ResponsiveUtils.spacing(context, 8),
                    ),
                    child: Text(
                      missionsState.error!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.orange[200],
                      ),
                    ),
                  ),

                Expanded(
                  child: missionsState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : missionsState.missions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'No missions available',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: ResponsiveUtils.fontSize(context, 16),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.read(missionsProvider.notifier).refreshMissions();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                await ref.read(missionsProvider.notifier).refreshMissions();
                              },
                              child: ListView.builder(
                                itemCount: missionsState.missions.length,
                                itemBuilder: (context, index) {
                                  final mission = missionsState.missions[index];
                                  return MissionCard(
                                    mission: mission,
                                    onTap: () {
                                      // Handle mission tap if needed
                                    },
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
