import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/network/dio_client.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';

class _Client implements DioClient {
  @override
  final dio = Dio();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'LesEat lists each open branch once from mixed catalog responses',
    () async {
      final client = _Client();
      final primary = {
        'id': 34,
        'name': 'Jollibee',
        'city': 'Abulug',
        'is_open': true,
      };
      final secondary = {
        'id': 51,
        'name': 'Aparri',
        'city': 'Aparri',
        'is_open': true,
      };
      final closed = {'id': 52, 'name': 'Closed', 'is_open': false};

      client.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.queryParameters['expand_branches'], '1');
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': [
                    {
                      'id': 38,
                      'name': 'Jollibee',
                      'branch_id': 34,
                      'branches': [primary, secondary, closed],
                    },
                    {
                      'id': 38,
                      'name': 'Jollibee – Aparri',
                      'branch_id': 51,
                      'branches': [secondary],
                    },
                    {
                      'id': 39,
                      'name': 'McDonald’s',
                      'branches': [
                        {'id': 35, 'name': 'Abulug', 'city': 'Abulug'},
                        {
                          'id': 54,
                          'name': 'Sanchez Mira',
                          'city': 'Sanchez Mira',
                        },
                      ],
                    },
                    {'id': 40, 'name': 'Independent restaurant'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final result = await PartnerRemoteDataSource(
        client,
      ).getPartners(category: 'restaurant', expandBranches: true);
      expect(result.data.map((p) => p.id), [38, 38, 39, 39, 40]);
      expect(result.data.map((p) => p.branchId), [34, 51, 35, 54, null]);
      expect(result.data.map((p) => p.name), [
        'Jollibee',
        'Jollibee – Aparri',
        'McDonald’s – Abulug',
        'McDonald’s – Sanchez Mira',
        'Independent restaurant',
      ]);
      expect(result.data.first.address, 'Abulug');
    },
  );
}
