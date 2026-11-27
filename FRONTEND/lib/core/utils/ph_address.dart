/// A Philippine address in the pieces people actually use: block and lot, house
/// number, street, subdivision or village, barangay, city, province and ZIP.
class PhAddress {
  const PhAddress({
    this.block = '',
    this.lot = '',
    this.houseNumber = '',
    this.street = '',
    this.subdivision = '',
    this.barangay = '',
    this.city = '',
    this.province = '',
    this.zip = '',
    this.landmark = '',
  });

  final String block;
  final String lot;
  final String houseNumber;
  final String street;
  final String subdivision;
  final String barangay;
  final String city;
  final String province;
  final String zip;
  final String landmark;

  PhAddress copyWith({
    String? block,
    String? lot,
    String? houseNumber,
    String? street,
    String? subdivision,
    String? barangay,
    String? city,
    String? province,
    String? zip,
    String? landmark,
  }) => PhAddress(
    block: block ?? this.block,
    lot: lot ?? this.lot,
    houseNumber: houseNumber ?? this.houseNumber,
    street: street ?? this.street,
    subdivision: subdivision ?? this.subdivision,
    barangay: barangay ?? this.barangay,
    city: city ?? this.city,
    province: province ?? this.province,
    zip: zip ?? this.zip,
    landmark: landmark ?? this.landmark,
  );

  bool get isEmpty =>
      [block, lot, houseNumber, street, subdivision, barangay, city, province, zip]
          .every((p) => p.trim().isEmpty);

  /// Only city-level (or less): no street, subdivision, barangay or block/lot.
  /// This is the case the customer should be asked to complete.
  bool get isCityLevelOnly =>
      block.isEmpty &&
      lot.isEmpty &&
      houseNumber.isEmpty &&
      street.isEmpty &&
      subdivision.isEmpty &&
      barangay.isEmpty;

  /// "Blk 14 Lot 9"
  String get blockLot => [
    if (block.trim().isNotEmpty) 'Blk ${block.trim()}',
    if (lot.trim().isNotEmpty) 'Lot ${lot.trim()}',
  ].join(' ');

  String get _streetPart =>
      [houseNumber.trim(), street.trim()].where((p) => p.isNotEmpty).join(' ');

  /// Where exactly: "Blk 14 Lot 9, Mahogany St, Francisco Homes".
  String get line1 => [
    blockLot,
    _streetPart,
    subdivision.trim(),
  ].where((p) => p.isNotEmpty).join(', ');

  /// The area: "Brgy. Muzon, San Jose del Monte, Bulacan 3023".
  String get line2 {
    final area = [
      if (barangay.trim().isNotEmpty) _brgy(barangay),
      city.trim(),
      province.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    if (zip.trim().isEmpty) return area;
    return area.isEmpty ? zip.trim() : '$area ${zip.trim()}';
  }

  /// The whole address on one line.
  String get full => [line1, line2].where((p) => p.isNotEmpty).join(', ');

  static String _brgy(String name) {
    final n = name
        .trim()
        .replaceFirst(
          RegExp(r'^(barangay|brgy\.?)\s*', caseSensitive: false),
          '',
        );
    return n.isEmpty ? name.trim() : 'Brgy. $n';
  }

  @override
  String toString() => full;

  @override
  bool operator ==(Object other) =>
      other is PhAddress &&
      other.block == block &&
      other.lot == lot &&
      other.houseNumber == houseNumber &&
      other.street == street &&
      other.subdivision == subdivision &&
      other.barangay == barangay &&
      other.city == city &&
      other.province == province &&
      other.zip == zip &&
      other.landmark == landmark;

  @override
  int get hashCode => Object.hash(
    block,
    lot,
    houseNumber,
    street,
    subdivision,
    barangay,
    city,
    province,
    zip,
    landmark,
  );
}

/// Turns what Google returns into a [PhAddress], using every result (not just
/// the first, which for most pins is only the city) and understanding how
/// Philippine addresses are written.
class PhAddressParser {
  PhAddressParser._();

  static final _blockRe = RegExp(
    r'(?:\bblk\.?|\bblock)\s*-?\s*#?\s*(\d+[a-z]?)',
    caseSensitive: false,
  );
  static final _lotRe = RegExp(
    r'(?:\blot|\blt\.?)\s*-?\s*#?\s*(\d+[a-z]?)',
    caseSensitive: false,
  );
  // "B14 L9", "B-14, L-9"
  static final _compactRe = RegExp(
    r'\bb\s*-?\s*(\d+[a-z]?)\s*[,/ ]\s*l\s*-?\s*(\d+[a-z]?)\b',
    caseSensitive: false,
  );
  static final _subdivisionRe = RegExp(
    r'(subdivision|village|homes|estates|heights|residences|townhomes|townhouses|hills|gardens|phase\s*\d+)',
    caseSensitive: false,
  );

  /// Finds block and lot in free text like "Block 14 Lot 9 Mahogany St".
  static ({String block, String lot, String rest}) extractBlockLot(String text) {
    var rest = text;
    var block = '';
    var lot = '';
    final compact = _compactRe.firstMatch(rest);
    if (compact != null) {
      block = compact.group(1)!;
      lot = compact.group(2)!;
      rest = rest.replaceRange(compact.start, compact.end, '');
    } else {
      final b = _blockRe.firstMatch(rest);
      if (b != null) {
        block = b.group(1)!;
        rest = rest.replaceRange(b.start, b.end, '');
      }
      final l = _lotRe.firstMatch(rest);
      if (l != null) {
        lot = l.group(1)!;
        rest = rest.replaceRange(l.start, l.end, '');
      }
    }
    rest = rest.replaceAll(RegExp(r'\s{2,}'), ' ').replaceAll(RegExp(r'^[\s,.-]+|[\s,.-]+$'), '');
    return (block: block.toUpperCase(), lot: lot.toUpperCase(), rest: rest);
  }

  static bool _isPlusCodeOnly(List<dynamic> types) =>
      types.isNotEmpty && types.every((t) => t == 'plus_code');

  /// [results] is the `results` array of a Google Geocoding response.
  static PhAddress fromGoogleResults(List<dynamic> results) {
    final c = _Collector();
    String? formatted;
    for (final r in results) {
      if (r is! Map) continue;
      final types = (r['types'] as List<dynamic>?) ?? const [];
      if (_isPlusCodeOnly(types)) continue;
      formatted ??= _stripPlusCode(r['formatted_address']?.toString());
      final comps = r['address_components'];
      if (comps is List) {
        for (final comp in comps) {
          if (comp is Map) {
            c.add(
              (comp['types'] as List<dynamic>?) ?? const [],
              comp['long_name']?.toString(),
            );
          }
        }
      }
    }
    return c.build(formatted: formatted);
  }

  /// For the flat component map the place-search widget builds.
  static PhAddress fromComponentMap(
    Map<String, String> m, {
    String? formattedAddress,
  }) {
    final c = _Collector()
      ..streetNumber = m['houseNumber'] ?? m['street_number']
      ..route = m['streetName'] ?? m['route']
      ..premise = m['premise']
      ..subpremise = m['subpremise']
      ..neighborhood = m['neighborhood']
      ..sublocality1 = m['barangay']
      ..sublocality2 = m['sublocality2']
      ..locality = m['city']
      ..admin1 = m['province']
      ..admin2 = m['admin2']
      ..postal = m['zipCode'] ?? m['postal_code'];
    return c.build(formatted: _stripPlusCode(formattedAddress));
  }

  static String? _stripPlusCode(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceFirst(
      RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}[\s,]*'),
      '',
    );
    return cleaned.trim().isEmpty ? null : cleaned.trim();
  }
}

class _Collector {
  String? streetNumber,
      route,
      premise,
      subpremise,
      neighborhood,
      sublocality1,
      sublocality2,
      sublocality3,
      locality,
      admin1,
      admin2,
      admin3,
      admin4,
      admin5,
      postal;

  void _set(String? current, String? v, void Function(String) assign) {
    if ((current == null || current.isEmpty) && v != null && v.isNotEmpty) {
      assign(v);
    }
  }

  void add(List<dynamic> types, String? name) {
    if (name == null || name.isEmpty) return;
    bool t(String x) => types.contains(x);
    if (t('street_number')) {
      _set(streetNumber, name, (v) => streetNumber = v);
    } else if (t('route')) {
      _set(route, name, (v) => route = v);
    } else if (t('subpremise')) {
      _set(subpremise, name, (v) => subpremise = v);
    } else if (t('premise')) {
      _set(premise, name, (v) => premise = v);
    } else if (t('neighborhood')) {
      _set(neighborhood, name, (v) => neighborhood = v);
    } else if (t('sublocality_level_1') || t('sublocality')) {
      _set(sublocality1, name, (v) => sublocality1 = v);
    } else if (t('sublocality_level_2')) {
      _set(sublocality2, name, (v) => sublocality2 = v);
    } else if (t('sublocality_level_3') ||
        t('sublocality_level_4') ||
        t('sublocality_level_5')) {
      _set(sublocality3, name, (v) => sublocality3 = v);
    } else if (t('locality')) {
      _set(locality, name, (v) => locality = v);
    } else if (t('administrative_area_level_1')) {
      _set(admin1, name, (v) => admin1 = v);
    } else if (t('administrative_area_level_2')) {
      _set(admin2, name, (v) => admin2 = v);
    } else if (t('administrative_area_level_3')) {
      _set(admin3, name, (v) => admin3 = v);
    } else if (t('administrative_area_level_4')) {
      _set(admin4, name, (v) => admin4 = v);
    } else if (t('administrative_area_level_5')) {
      _set(admin5, name, (v) => admin5 = v);
    } else if (t('postal_code')) {
      _set(postal, name, (v) => postal = v);
    }
  }

  String _clean(String? s) => (s ?? '').trim();

  PhAddress build({String? formatted}) {
    final city = _clean(locality).isNotEmpty
        ? _clean(locality)
        : (_clean(admin2).isNotEmpty ? _clean(admin2) : _clean(admin3));
    var province = _clean(admin1);
    if (province == city && _clean(admin2).isNotEmpty) province = _clean(admin2);

    // Block and lot can hide in the premise, route or the formatted address.
    var block = '';
    var lot = '';
    var street = _clean(route);
    var houseNumber = _clean(streetNumber);
    final sources = [
      _clean(subpremise),
      _clean(premise),
      street,
      if (formatted != null) formatted.split(',').first,
    ];
    for (final src in sources) {
      if (src.isEmpty) continue;
      final f = PhAddressParser.extractBlockLot(src);
      if (f.block.isNotEmpty && block.isEmpty) block = f.block;
      if (f.lot.isNotEmpty && lot.isEmpty) lot = f.lot;
    }
    if (street.isNotEmpty) {
      street = PhAddressParser.extractBlockLot(street).rest;
    }
    // A numeric premise is the house number.
    final prem = _clean(premise);
    if (houseNumber.isEmpty &&
        prem.isNotEmpty &&
        RegExp(r'^\d+[a-z]?$', caseSensitive: false).hasMatch(prem)) {
      houseNumber = prem;
    }

    var barangay = [
      sublocality1,
      admin5,
      admin4,
      admin3,
    ].map(_clean).firstWhere((s) => s.isNotEmpty && s != city, orElse: () => '');

    // Subdivision / village: a neighbourhood or sub-locality, otherwise a
    // segment of the formatted address that reads like one.
    var subdivision = [
      neighborhood,
      sublocality2,
      sublocality3,
    ].map(_clean).firstWhere(
      (s) => s.isNotEmpty && s != city && s != barangay,
      orElse: () => '',
    );
    if (subdivision.isEmpty && formatted != null) {
      for (final seg in formatted.split(',').map((e) => e.trim())) {
        if (seg.isEmpty || seg == city || seg == barangay || seg == street) continue;
        if (PhAddressParser._subdivisionRe.hasMatch(seg) &&
            !RegExp(r'^(brgy|barangay)', caseSensitive: false).hasMatch(seg)) {
          subdivision = PhAddressParser.extractBlockLot(seg).rest;
          break;
        }
      }
    }
    if (barangay.toLowerCase() == subdivision.toLowerCase()) barangay = '';

    return PhAddress(
      block: block,
      lot: lot,
      houseNumber: houseNumber,
      street: street,
      subdivision: subdivision,
      barangay: barangay,
      city: city,
      province: province,
      zip: _clean(postal),
    );
  }
}
