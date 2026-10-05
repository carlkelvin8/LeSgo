import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/missions_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/missions/mission_dto.dart';
import 'package:lesgo/presentation/screens/main/missions_screen.dart';
import 'package:lesgo/presentation/screens/main/profile_screen.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/data/data_source/dto/user/user_profile_dto.dart';
import 'package:lesgo/core/theme/app_theme.dart';
class FakeSource implements MissionsRemoteDataSource {
  Future<MissionsResponseDto> getMissions() async => MissionsResponseDto(success:true,message:'OK',data:[]);
  dynamic noSuchMethod(Invocation i)=>super.noSuchMethod(i);
}
class FakeProfile extends ProfileNotifier {
  Future<void> loadProfile() async {}
  void ready(){state=ProfileState(name:'Audit User',email:'audit@example.test',user:UserProfileDto(id:1,name:'Audit User',email:'audit@example.test',role:'customer'));}
}
void main(){
 testWidgets('mission back button receives taps and restores previous route',(tester) async {
  tester.view.physicalSize=const Size(390,844);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  getIt.registerSingleton<MissionsRemoteDataSource>(FakeSource());addTearDown(getIt.reset);
  await tester.pumpWidget(ProviderScope(child:MaterialApp(home:Builder(builder:(c)=>Scaffold(body:TextButton(onPressed:()=>Navigator.push(c,MaterialPageRoute<void>(builder:(_)=>const MissionsScreen())),child:const Text('Open missions')))))));
  await tester.tap(find.text('Open missions'));await tester.pumpAndSettle();
  final back=find.byIcon(Icons.arrow_back_ios);
  expect(back,findsOneWidget);
  await tester.tap(back);await tester.pumpAndSettle();
  expect(find.text('Open missions'),findsOneWidget);
 });
 testWidgets('dark profile settings button is visible and navigates',(tester) async {
  final profile=FakeProfile()..ready();
  await tester.pumpWidget(ProviderScope(overrides:[profileProvider.overrideWith((_)=>profile)],child:MaterialApp(theme:AppTheme.dark,home:const ProfileScreen(),routes:{'/main/settings':(_)=>const Scaffold(body:Text('Settings destination')),'/settings':(_)=>const Scaffold(body:Text('Settings destination'))})));
  await tester.pumpAndSettle();
  expect(find.text('Preferences and Support'),findsNothing);
  expect(find.text('Preferences & Support'),findsNothing);
  expect(find.byIcon(Icons.settings_outlined),findsOneWidget);
  final button=find.byTooltip('Settings');expect(button,findsOneWidget);
  final context=tester.element(button);final appBar=AppBarTheme.of(context);
  expect(appBar.foregroundColor,AppTheme.dark.colorScheme.onSurface);
  await tester.tap(button);await tester.pumpAndSettle();
  expect(find.text('Settings destination'),findsOneWidget);
 });
}
