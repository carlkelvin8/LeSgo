import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/widgets/home/hero_banner.dart';
import 'package:lesgo/presentation/widgets/home/quick_access_card.dart';
import 'package:lesgo/presentation/widgets/home/promo_card.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('home cards fit $width at enlarged text size', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var books = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1000),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    HeroBanner(
                      userName: 'Alexandrianna',
                      title: 'Your everyday delivery partner',
                      subtitle: 'Book a ride or delivery today.',
                      backgroundImagePath: 'assets/images/homepage/Rider.svg',
                      onBookNowPressed: () => books++,
                    ),
                    const Row(
                      children: [
                        Expanded(child: QuickAccessCard(
                          iconPath: 'assets/images/homepage/Inbox.svg',
                          title: 'Inbox',
                          subtitle: 'Receive messages about your orders.',
                        )),
                        SizedBox(width: 12),
                        Expanded(child: QuickAccessCard(
                          iconPath: 'assets/images/homepage/Wallet.svg',
                          title: 'LesPay Wallet',
                          subtitle: 'Pay your orders with your LesPay wallet.',
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 315,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          PromoCard(
                            title: 'LesPay cashback offer',
                            subtitle: 'All services',
                            badge: 'P10 BACK',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Book now'));
      expect(books, 1);
    });
  }
}
