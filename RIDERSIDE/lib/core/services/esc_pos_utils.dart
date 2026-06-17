import 'dart:convert';

class EscPosUtils {
  static const List<int> _init = [0x1B, 0x40];
  static const List<int> _lf = [0x0A];
  static const List<int> _cut = [0x1D, 0x56, 0x00];
  static const List<int> _alignCenter = [0x1B, 0x61, 0x01];
  static const List<int> _alignLeft = [0x1B, 0x61, 0x00];
  static const List<int> _alignRight = [0x1B, 0x61, 0x02];
  static const List<int> _boldOn = [0x1B, 0x45, 0x01];
  static const List<int> _boldOff = [0x1B, 0x45, 0x00];
  static const List<int> _doubleHeight = [0x1B, 0x21, 0x10];
  static const List<int> _normalSize = [0x1B, 0x21, 0x00];

  static List<int> init() => [..._init];

  static List<int> feed(int lines) {
    if (lines <= 0) return [];
    return [0x1B, 0x64, lines.clamp(0, 255)];
  }

  static List<int> lineFeed() => [..._lf];

  static List<int> cut() => [..._cut];

  static List<int> center() => [..._alignCenter];

  static List<int> left() => [..._alignLeft];

  static List<int> right() => [..._alignRight];

  static List<int> bold() => [..._boldOn];

  static List<int> normalWeight() => [..._boldOff];

  static List<int> doubleHeight() => [..._doubleHeight];

  static List<int> normalSize() => [..._normalSize];

  static List<int> text(String text) => utf8.encode(text);

  static List<int> boldText(String text) => [..._boldOn, ...utf8.encode(text), ..._boldOff];

  static List<int> centeredText(String text) => [..._alignCenter, ...utf8.encode(text), ..._lf, ..._alignLeft];

  static List<int> doubleHeightCentered(String text) =>
      [..._alignCenter, ..._doubleHeight, ...utf8.encode(text), ..._lf, ..._normalSize, ..._alignLeft];

  static List<int> divider() => [...text('─' * 32), ..._lf];

  static List<int> singleRow(String left, String right) {
    final line = '$left${' ' * (32 - left.length - right.length)}$right';
    return [...text(line), ..._lf];
  }

  static List<int> header(String storeName) => [
        ..._init,
        ...doubleHeightCentered(storeName),
        ..._lf,
      ];

  static List<int> orderInfo({
    required String orderRef,
    required DateTime date,
    String? customer,
  }) {
    final buf = <int>[
      ...center(),
      ...bold(),
      ...text('ORDER #$orderRef'),
      ...normalWeight(),
      ..._lf,
      ...left(),
      ...text(date.toLocal().toString().substring(0, 19)),
      ..._lf,
      if (customer != null) ...[...text('Customer: $customer'), ..._lf],
      ..._lf,
      ...divider(),
    ];
    return buf;
  }

  static List<int> textLine(String line) => [...text(line), ..._lf];

  static List<int> items(List<String> itemLines) {
    final buf = <int>[..._lf];
    for (final line in itemLines) {
      buf.addAll(text(line));
      buf.addAll(_lf);
    }
    buf.addAll(divider());
    return buf;
  }

  static List<int> total(String label, String amount) => [
        ..._lf,
        ...bold(),
        ...singleRow(label, amount),
        ...normalWeight(),
        ..._lf,
      ];

  static List<int> footer(List<String> lines) {
    final buf = <int>[..._lf, ..._lf];
    for (final line in lines) {
      buf.addAll(centeredText(line));
    }
    return buf;
  }

  static List<int> buildReceipt({
    required String storeName,
    required String orderRef,
    required DateTime date,
    String? customer,
    List<String> itemLines = const [],
    String? totalLabel,
    String? totalAmount,
    List<String>? footerLines,
  }) {
    final buf = <int>[
      ...header(storeName),
      ...orderInfo(orderRef: orderRef, date: date, customer: customer),
      ...items(itemLines),
      if (totalLabel != null && totalAmount != null)
        ...total(totalLabel, totalAmount),
      ...footer(footerLines ?? []),
      ...cut(),
    ];
    return buf;
  }
}
