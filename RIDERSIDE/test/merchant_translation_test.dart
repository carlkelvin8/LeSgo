import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/app_localization.dart';
import 'package:lezgo_rider/core/utils/merchant_translations.dart';

void main() {
  test('English stays exactly as written', () {
    expect(AppLocalization.translateLiteral('Orders', AppLanguage.english),
        'Orders');
  });

  test('Filipino translates known merchant strings', () {
    expect(AppLocalization.translateLiteral('Orders', AppLanguage.filipino),
        'Mga order');
    expect(
        AppLocalization.translateLiteral('Mark Ready', AppLanguage.filipino),
        'Markahang handa na');
  });

  test('unknown strings fall back to English instead of breaking', () {
    expect(
        AppLocalization.translateLiteral('Totally new text', AppLanguage.filipino),
        'Totally new text');
  });

  test('no translation is empty or just a copy with stray whitespace', () {
    for (final e in merchantFilipinoLiterals.entries) {
      expect(e.value.trim(), isNotEmpty, reason: e.key);
      expect(e.value, e.value.trimLeft(), reason: 'leading space: ${e.key}');
    }
  });
}
