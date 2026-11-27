import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Who or what a map pin stands for.
enum MapPinKind {
  /// The customer (pickup point, "you", a delivery address).
  customer,

  /// The rider's live position.
  rider,

  /// A restaurant, store or merchant location.
  store,

  /// A ride destination.
  destination,
}

/// The LeSgo branded map pins: the customer and rider mascots, plus a matching
/// store and destination pin drawn in the same style.
///
/// Call [preload] once at start-up. [icon] is synchronous and falls back to a
/// plain coloured marker until the pins are ready, so a map never waits.
class MapPins {
  MapPins._();

  /// The tip of the pin sits at the bottom centre of the image.
  static const Offset anchor = Offset(0.5, 0.97);

  static const double _logicalWidth = 46;
  static const double _logicalHeight = 52;
  static const _brand = Color(0xFF5F2D82);

  static final Map<MapPinKind, BitmapDescriptor> _cache = {};
  static Future<void>? _loading;

  static bool get isReady => _cache.length == MapPinKind.values.length;

  /// Loads and caches every pin. Safe to call many times.
  static Future<void> preload({double? devicePixelRatio}) {
    return _loading ??= () async {
      try {
        await _load(devicePixelRatio ?? _defaultDpr());
      } catch (e) {
        debugPrint('MapPins: could not load pins ($e)');
        _loading = null;
      }
    }();
  }

  static double _defaultDpr() {
    final views = ui.PlatformDispatcher.instance.views;
    final dpr = views.isEmpty ? 3.0 : views.first.devicePixelRatio;
    return dpr.clamp(1.0, 3.0);
  }

  static Future<void> _load(double dpr) async {
    _cache[MapPinKind.customer] = await _fromAsset(
      'assets/images/markers/customer_pin.png',
      dpr,
    );
    _cache[MapPinKind.rider] = await _fromAsset(
      'assets/images/markers/rider_pin.png',
      dpr,
    );
    _cache[MapPinKind.store] = await _drawn(
      dpr,
      fill: _brand,
      glyph: Icons.storefront_rounded,
    );
    _cache[MapPinKind.destination] = await _drawn(
      dpr,
      fill: const Color(0xFFE5484D),
      glyph: Icons.flag_rounded,
    );
  }

  /// The pin for [kind], or a coloured default marker while loading.
  static BitmapDescriptor icon(MapPinKind kind) =>
      _cache[kind] ?? BitmapDescriptor.defaultMarkerWithHue(_hue(kind));

  static double _hue(MapPinKind kind) => switch (kind) {
    MapPinKind.customer => BitmapDescriptor.hueViolet,
    MapPinKind.rider => BitmapDescriptor.hueAzure,
    MapPinKind.store => BitmapDescriptor.hueOrange,
    MapPinKind.destination => BitmapDescriptor.hueRed,
  };

  static Future<BitmapDescriptor> _fromAsset(String path, double dpr) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: (_logicalWidth * dpr).round(),
    );
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      png!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  static Future<BitmapDescriptor> _drawn(
    double dpr, {
    required Color fill,
    required IconData glyph,
  }) async {
    final w = _logicalWidth;
    final h = _logicalHeight;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);

    const r = 20.0;
    final cx = w / 2;
    final cy = r + 3;
    final tip = Offset(cx, h - 1);
    final circle = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final spread = r * math.cos(math.pi / 6);
    final cone = Path()
      ..moveTo(cx - spread, cy + r * 0.5)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(cx + spread, cy + r * 0.5)
      ..close();
    final body = Path.combine(PathOperation.union, circle, cone);

    canvas.drawShadow(body, Colors.black.withValues(alpha: 0.35), 3, true);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(body, Paint()..color = fill);
    canvas.drawCircle(
      Offset(cx, cy),
      r - 4,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final image = await recorder.endRecording().toImage(
      (w * dpr).ceil(),
      (h * dpr).ceil(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      png!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }
}
