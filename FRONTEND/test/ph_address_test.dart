import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lesgo/core/services/address_geocoder.dart';
import 'package:lesgo/core/utils/ph_address.dart';
import 'package:lesgo/domain/models/location/location_address.dart';

Map<String, dynamic> _comp(String name, List<String> types) => {
  'long_name': name,
  'short_name': name,
  'types': types,
};

/// What Google tends to return for a pin inside a subdivision in San Jose del
/// Monte: a plus-code result first, then a street result, then a neighbourhood.
List<dynamic> _sjdmResults() => [
  {
    'types': ['plus_code'],
    'formatted_address': '5XQ2+8H San Jose del Monte, Bulacan',
    'address_components': [
      _comp('5XQ2+8H', ['plus_code']),
      _comp('San Jose del Monte', ['locality', 'political']),
      _comp('Bulacan', ['administrative_area_level_1', 'political']),
    ],
  },
  {
    'types': ['route'],
    'formatted_address': 'Mahogany St, Muzon, City of San Jose del Monte, Bulacan',
    'address_components': [
      _comp('Mahogany Street', ['route']),
      _comp('Muzon', ['sublocality_level_1', 'sublocality', 'political']),
      _comp('City of San Jose del Monte', ['locality', 'political']),
      _comp('Bulacan', ['administrative_area_level_1', 'political']),
      _comp('3023', ['postal_code']),
      _comp('Philippines', ['country', 'political']),
    ],
  },
  {
    'types': ['neighborhood', 'political'],
    'formatted_address': 'Francisco Homes, City of San Jose del Monte, Bulacan',
    'address_components': [
      _comp('Francisco Homes', ['neighborhood', 'political']),
      _comp('City of San Jose del Monte', ['locality', 'political']),
    ],
  },
  {
    'types': ['locality', 'political'],
    'formatted_address': 'City of San Jose del Monte, Bulacan',
    'address_components': [
      _comp('City of San Jose del Monte', ['locality', 'political']),
      _comp('Bulacan', ['administrative_area_level_1', 'political']),
    ],
  },
];

void main() {
  group('PhAddressParser.fromGoogleResults', () {
    test('uses every result, not just the city one', () {
      final a = PhAddressParser.fromGoogleResults(_sjdmResults());
      expect(a.street, 'Mahogany Street');
      expect(a.barangay, 'Muzon');
      expect(a.subdivision, 'Francisco Homes');
      expect(a.city, 'City of San Jose del Monte');
      expect(a.province, 'Bulacan');
      expect(a.zip, '3023');
      expect(a.isCityLevelOnly, isFalse);
      expect(a.line1, 'Mahogany Street, Francisco Homes');
      expect(a.line2, 'Brgy. Muzon, City of San Jose del Monte, Bulacan 3023');
    });

    test('finds block and lot written in the premise or street', () {
      final a = PhAddressParser.fromGoogleResults([
        {
          'types': ['premise'],
          'formatted_address': 'Blk 14 Lot 9 Mahogany St, Muzon, San Jose del Monte, Bulacan',
          'address_components': [
            _comp('Blk 14 Lot 9', ['premise']),
            _comp('Mahogany St', ['route']),
            _comp('Muzon', ['sublocality_level_1']),
            _comp('San Jose del Monte', ['locality']),
            _comp('Bulacan', ['administrative_area_level_1']),
          ],
        },
      ]);
      expect(a.block, '14');
      expect(a.lot, '9');
      expect(a.street, 'Mahogany St');
      expect(a.blockLot, 'Blk 14 Lot 9');
      expect(a.line1, 'Blk 14 Lot 9, Mahogany St');
    });

    test('block and lot inside the street name are moved out of it', () {
      final a = PhAddressParser.fromGoogleResults([
        {
          'types': ['route'],
          'formatted_address': 'Block 3 Lot 12 Rose St, Quezon City',
          'address_components': [
            _comp('Block 3 Lot 12 Rose St', ['route']),
            _comp('Quezon City', ['locality']),
            _comp('Metro Manila', ['administrative_area_level_1']),
          ],
        },
      ]);
      expect(a.block, '3');
      expect(a.lot, '12');
      expect(a.street, 'Rose St');
    });

    test('a subdivision named only in the formatted address is picked up', () {
      final a = PhAddressParser.fromGoogleResults([
        {
          'types': ['street_address'],
          'formatted_address':
              '12 Acacia St, Citrus Heights Subdivision, Muzon, City of San Jose del Monte, Bulacan 3023',
          'address_components': [
            _comp('12', ['street_number']),
            _comp('Acacia St', ['route']),
            _comp('Muzon', ['sublocality_level_1']),
            _comp('City of San Jose del Monte', ['locality']),
            _comp('Bulacan', ['administrative_area_level_1']),
            _comp('3023', ['postal_code']),
          ],
        },
      ]);
      expect(a.houseNumber, '12');
      expect(a.subdivision, 'Citrus Heights Subdivision');
      expect(a.line1, '12 Acacia St, Citrus Heights Subdivision');
    });

    test('a city-only pin is flagged so the customer is asked to complete it', () {
      final a = PhAddressParser.fromGoogleResults([_sjdmResults().last]);
      expect(a.isCityLevelOnly, isTrue);
      expect(a.city, 'City of San Jose del Monte');
      expect(a.full, 'City of San Jose del Monte, Bulacan');
    });
  });

  group('extractBlockLot', () {
    for (final c in [
      ('Blk 14 Lot 9', '14', '9'),
      ('Block 14, Lot 9', '14', '9'),
      ('blk.14 lt.9', '14', '9'),
      ('B14 L9', '14', '9'),
      ('B-14, L-9', '14', '9'),
      ('Block 7A Lot 12B', '7A', '12B'),
    ]) {
      test('"${c.$1}"', () {
        final f = PhAddressParser.extractBlockLot(c.$1);
        expect(f.block, c.$2);
        expect(f.lot, c.$3);
      });
    }

    test('leaves ordinary text alone', () {
      final f = PhAddressParser.extractBlockLot('Mahogany Street');
      expect((f.block, f.lot, f.rest), ('', '', 'Mahogany Street'));
    });
  });

  group('formatting', () {
    test('Brgy. is not doubled', () {
      expect(const PhAddress(barangay: 'Barangay Muzon', city: 'SJDM').line2, 'Brgy. Muzon, SJDM');
      expect(const PhAddress(barangay: 'Brgy. Muzon').line2, 'Brgy. Muzon');
    });

    test('LocationAddress keeps the old fields and adds the zip once', () {
      final l = LocationAddress.fromPh(
        const PhAddress(
          block: '14',
          lot: '9',
          street: 'Mahogany St',
          subdivision: 'Francisco Homes',
          barangay: 'Muzon',
          city: 'San Jose del Monte',
          province: 'Bulacan',
          zip: '3023',
        ),
      );
      expect(l.houseNumberStreet, 'Blk 14 Lot 9, Mahogany St, Francisco Homes');
      expect(l.subdivisionBarangay, 'Brgy. Muzon');
      expect(l.cityProvince, 'San Jose del Monte, Bulacan');
      expect(l.toString(),
          'Blk 14 Lot 9, Mahogany St, Francisco Homes, Brgy. Muzon, San Jose del Monte, Bulacan 3023');
      expect(l.details?.block, '14');
    });
  });

  group('AddressGeocoder', () {
    const pin = LatLng(14.8136, 121.0451);

    http.Response okResponse() => http.Response(
      jsonEncode({'status': 'OK', 'results': _sjdmResults()}),
      200,
    );

    test('reads the detailed address from Google', () async {
      var calls = 0;
      final g = AddressGeocoder(
        hasApiKey: true,
        get: (uri) async {
          calls++;
          expect(uri.queryParameters['region'], 'ph');
          return okResponse();
        },
        placemarks: (_, _) async => throw Exception('should not be needed'),
      );
      final a = await g.reverse(pin);
      expect(a!.barangay, 'Muzon');
      expect(a.zip, '3023');
      // The same pin again is served from the cache.
      await g.reverse(pin);
      expect(calls, 1);
    });

    test('falls back to the device geocoder when Google has nothing', () async {
      final g = AddressGeocoder(
        hasApiKey: true,
        get: (uri) async => http.Response(jsonEncode({'status': 'ZERO_RESULTS', 'results': []}), 200),
        placemarks: (_, _) async => [
          Placemark(
            street: 'Mahogany Street',
            subLocality: 'Muzon',
            locality: 'San Jose del Monte',
            administrativeArea: 'Bulacan',
            postalCode: '3023',
          ),
        ],
      );
      final a = await g.reverse(const LatLng(14.9, 121.0));
      expect(a!.street, 'Mahogany Street');
      expect(a.barangay, 'Muzon');
      expect(a.province, 'Bulacan');
    });

    test('returns null instead of throwing when everything fails', () async {
      final g = AddressGeocoder(
        hasApiKey: true,
        get: (uri) async => throw Exception('offline'),
        placemarks: (_, _) async => throw Exception('offline'),
      );
      expect(await g.reverse(const LatLng(1, 1)), isNull);
    });
  });
}
