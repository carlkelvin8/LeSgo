import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/dark_aware_colors.dart';

Future<BuildContext> _ctx(WidgetTester t, Brightness b) async {
  late BuildContext captured;
  await t.pumpWidget(MaterialApp(
    theme: ThemeData(brightness: b),
    home: Builder(builder: (c) {
      captured = c;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  testWidgets('light mode returns the original colour untouched', (t) async {
    final c = await _ctx(t, Brightness.light);
    expect(c.surf(Colors.white), Colors.white);
    expect(c.bg(const Color(0xFFF8F9FA)), const Color(0xFFF8F9FA));
    expect(c.txt(Colors.black87), Colors.black87);
    expect(c.sub(Colors.grey), Colors.grey);
    expect(c.acc(const Color(0xFF5F2D82)), const Color(0xFF5F2D82));
    expect(c.brd(Colors.grey.shade200), Colors.grey.shade200);
  });

  testWidgets('dark mode flips light surfaces and dark text to readable ones',
      (t) async {
    final c = await _ctx(t, Brightness.dark);
    expect(c.surf(Colors.white), DarkAwareColors.darkSurface);
    expect(c.bg(Colors.white), DarkAwareColors.darkBg);
    expect(c.txt(Colors.black87), Colors.white);
    expect(c.sub(Colors.grey.shade600), DarkAwareColors.darkMuted);
    expect(c.acc(const Color(0xFF5F2D82)), DarkAwareColors.darkAccent);
    expect(c.brd(Colors.grey.shade200), DarkAwareColors.darkBorder);
  });

  testWidgets('pastel tints stay tinted but get dark, with readable contrast',
      (t) async {
    final c = await _ctx(t, Brightness.dark);
    final tinted = c.surf(const Color(0xFFE8F5E9)); // light green
    expect(tinted.computeLuminance(), lessThan(0.15));
    expect(tinted, isNot(DarkAwareColors.darkSurface));
  });
}
