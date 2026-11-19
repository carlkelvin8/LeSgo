import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/leseat_cart_cache.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';
import 'package:lesgo/domain/entities/booking/leseat/menu_item.dart';
import 'package:lesgo/presentation/provider/main/booking/restaurant_detail_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory SharedPreferences whose writes land after a configurable latency,
/// so a slow write can finish after a later fast one (slow platform channel).
class _SlowPrefs implements SharedPreferences {
  final Map<String, Object> disk = {};
  Duration setLatency = Duration.zero;
  Duration removeLatency = Duration.zero;

  @override
  String? getString(String key) => disk[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    await Future<void>.delayed(setLatency);
    disk[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    await Future<void>.delayed(removeLatency);
    disk.remove(key);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePartnerDataSource implements PartnerRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MenuItem _menuItem() => MenuItem(
  id: '7',
  name: 'Burger',
  description: '',
  price: 100,
  imagePath: 'assets/x.svg',
  categoryId: 'c',
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

void main() {
  late _SlowPrefs prefs;
  late RestaurantDetailNotifier notifier;

  setUp(() async {
    await getIt.reset();
    prefs = _SlowPrefs();
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<PartnerRemoteDataSource>(_FakePartnerDataSource());
    notifier = RestaurantDetailNotifier();
    await _settle();
    // Normally set by loadRestaurantDetails.
    notifier.state = notifier.state.copyWith(activeRestaurantId: '1');
  });

  tearDown(() async => getIt.reset());

  test('baseline: cart persisted, then cleared', () async {
    notifier.addToCart(_menuItem());
    await _settle();
    expect((await LeseatCartCache.load())?.items.single.quantity, 1);
    await notifier.clearCart();
    await _settle();
    expect(await LeseatCartCache.load(), isNull);
  });

  test('a slow quantity persist cannot re-write the cart after clearCart',
      () async {
    notifier.addToCart(_menuItem());
    await _settle();

    // "+" on checkout starts a slow write; the order succeeds and the clear
    // (fast) completes first.
    prefs.setLatency = const Duration(milliseconds: 100);
    prefs.removeLatency = const Duration(milliseconds: 5);
    notifier.updateCartItemQuantity('1:7', 2);
    await notifier.clearCart();
    await _settle();

    expect(notifier.state.cartItems, isEmpty);
    expect(await LeseatCartCache.load(), isNull);
  });

  test('rapid quantity taps persist the latest quantity, not a stale one',
      () async {
    notifier.addToCart(_menuItem());
    await _settle();

    // First write is slow, second fast: without ordering the stale qty=2
    // lands last.
    prefs.setLatency = const Duration(milliseconds: 100);
    notifier.updateCartItemQuantity('1:7', 2);
    prefs.setLatency = const Duration(milliseconds: 5);
    notifier.updateCartItemQuantity('1:7', 3);
    await _settle();

    expect((await LeseatCartCache.load())?.items.single.quantity, 3);
  });
}
