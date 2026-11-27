import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/utils/driver_display_utils.dart';
import 'package:lesgo/data/data_source/dto/review/reviews_response_dto.dart';
import 'package:lesgo/data/data_source/review_remote_datasource.dart';
import 'package:lesgo/presentation/screens/main/reviews/reviews_list_screen.dart';
import 'package:lesgo/presentation/widgets/tracking/driver_info_card.dart';

class FakeReviews extends Fake implements ReviewRemoteDataSource {
  final calls = <(String?, int?)>[];

  @override
  Future<ReviewsResponseDto> getReviews({
    String? reviewableType,
    int? reviewableId,
    int page = 1,
    int perPage = 20,
  }) async {
    calls.add((reviewableType, reviewableId));
    return ReviewsResponseDto(success: true, data: const []);
  }
}

void main() {
  late FakeReviews reviews;

  setUp(() {
    reviews = FakeReviews();
    getIt.registerSingleton<ReviewRemoteDataSource>(reviews);
  });
  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpCard(WidgetTester tester, DriverInfo info) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DriverInfoCard(driverInfo: info)),
        ),
      ),
    );
  }

  testWidgets('tapping the rating opens the driver reviews screen', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const DriverInfo(name: 'Juan Dela Cruz', rating: 4.8, driverId: 77),
    );
    expect(find.byType(ReviewsListScreen), findsNothing);

    await tester.tap(find.text('4.8'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewsListScreen), findsOneWidget);
    final screen = tester.widget<ReviewsListScreen>(
      find.byType(ReviewsListScreen),
    );
    expect(screen.reviewableType, 'driver');
    expect(screen.reviewableId, 77);
    expect(screen.title, 'Juan Dela Cruz');
    expect(reviews.calls, [('driver', 77)]);
  });

  testWidgets('tapping the rating does nothing without a driver id', (
    tester,
  ) async {
    await pumpCard(tester, const DriverInfo(name: 'Juan', rating: 4.5));

    await tester.tap(find.text('4.5'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewsListScreen), findsNothing);
    expect(find.byType(DriverInfoCard), findsOneWidget);
    expect(reviews.calls, isEmpty);
  });

  testWidgets('no rating badge is shown when rating is null', (tester) async {
    await pumpCard(tester, const DriverInfo(name: 'Juan', driverId: 5));

    expect(find.byIcon(Icons.star), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });
}
