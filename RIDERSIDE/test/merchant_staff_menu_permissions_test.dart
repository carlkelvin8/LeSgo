import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/merchant_staff_permissions.dart';
import 'package:lezgo_rider/presentation/widgets/main/merchantside/menu/merchant_menu_setup_card.dart';

bool canEdit({bool owner = false, String? role, List<String>? permissions}) =>
    MerchantStaffPermissions.userCan(
      isMerchantOwner: owner,
      staffRole: role,
      explicitPermissions: permissions,
      permission: MerchantStaffPermissions.manageMenu,
    );

void main() {
  test('only owners, staff admins and granted staff edit the menu', () {
    expect(canEdit(owner: true), isTrue);
    expect(canEdit(role: 'admin'), isTrue);
    expect(canEdit(role: 'cook', permissions: ['manage_menu']), isTrue);
    expect(canEdit(role: 'cook'), isFalse);
    expect(canEdit(role: 'cashier'), isFalse);
  });

  testWidgets('staff who cannot edit see no setup button', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: MerchantMenuSetupCard(isDark: false)),
      ),
    ));

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('No menu yet'), findsOneWidget);
  });
}
