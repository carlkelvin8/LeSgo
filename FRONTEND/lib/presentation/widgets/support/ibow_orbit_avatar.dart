import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/entities/support/ibow_expression.dart';

/// IBOW, the LeSgo AI assistant, drawn entirely in code so every part can move.
///
/// What it does:
/// * **Idle** – floats and breathes, the halo bobs a beat behind the body, the
///   arms sway, it blinks at random and glances around on its own.
/// * **Follows your finger** – the eyes look toward wherever you touch the
///   screen (like the assistants in popular AI apps).
/// * **Tap** – jumps with squash and stretch, waves both arms, eyes turn into
///   happy arcs and sparkles burst out. Press and hold keeps it giggling.
/// * **Thinking** ([isThinking]) – the halo spins and glows, eyes dart up and
///   around, mouth shrinks to a small "o".
/// * **Speaking** ([isSpeaking]) – the mouth talks and the arms gesture.
///
/// Set [animated] to false for a still pose (used for the small avatars next
/// to every chat bubble so a long chat doesn't run dozens of tickers). The
/// animation is also skipped when the system asks to reduce motion.
class IbowOrbitAvatar extends StatefulWidget {
  const IbowOrbitAvatar({
    super.key,
    required this.size,
    this.isThinking = false,
    this.isSpeaking = false,
    this.animated = true,
    this.trackPointer = true,
    this.lookDirection,
    this.expression = IbowExpression.neutral,
    this.onTap,
  });

  final double size;
  final bool isThinking;
  final bool isSpeaking;

  /// false = draw a single still frame, no ticker.
  final bool animated;

  /// Eyes follow the last place the user touched the screen.
  final bool trackPointer;

  /// Pins the gaze (-1..1 on each axis), e.g. down toward the text field while
  /// the user types. A touch elsewhere on screen still wins for a moment.
  final Offset? lookDirection;

  /// How IBOW feels right now. Changing it plays a short reaction so the
  /// face change is noticed (a hop and sparkles, or a sad shake).
  final IbowExpression expression;
  final VoidCallback? onTap;

  @override
  State<IbowOrbitAvatar> createState() => _IbowOrbitAvatarState();
}

class _IbowOrbitAvatarState extends State<IbowOrbitAvatar>
    with SingleTickerProviderStateMixin {
  final _rng = math.Random();
  final _repaint = ValueNotifier<int>(0);
  Ticker? _ticker;

  double _t = 0;
  // Blinking.
  double _blink = 0;
  double? _blinkStart;
  double _nextBlink = 1.6;
  // Where the eyes look, -1..1 on both axes.
  Offset _look = Offset.zero;
  Offset _lookTarget = Offset.zero;
  double _nextWander = 1.0;
  double _pointerUntil = 0;
  // Tap reaction (start time) and press-and-hold.
  double? _reactStart;
  double _exprChangedAt = -10;
  bool _holding = false;

  bool _reduceMotion = false;
  bool _routeAdded = false;

  void _addRoute() {
    if (_routeAdded) return;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    _routeAdded = true;
  }

  void _removeRoute() {
    if (!_routeAdded) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    _routeAdded = false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.animated && widget.trackPointer) _addRoute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant IbowOrbitAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expression != widget.expression) {
      _exprChangedAt = _t;
      final e = widget.expression;
      // Happy-ish faces hop with sparkles; sad shakes (handled in paint);
      // neutral and sleepy change quietly.
      if (e == IbowExpression.happy ||
          e == IbowExpression.love ||
          e == IbowExpression.wink ||
          e == IbowExpression.surprised) {
        if (widget.animated && !_reduceMotion) _reactStart = _t;
      }
    }
    final wasTracking = oldWidget.animated && oldWidget.trackPointer;
    final isTracking = widget.animated && widget.trackPointer;
    if (wasTracking && !isTracking) {
      _removeRoute();
    } else if (!wasTracking && isTracking) {
      _addRoute();
    }
    _syncTicker();
  }

  void _syncTicker() {
    final shouldRun = widget.animated && !_reduceMotion;
    if (shouldRun && _ticker == null) {
      _ticker = createTicker(_onTick)..start();
    } else if (!shouldRun && _ticker != null) {
      _ticker!.dispose();
      _ticker = null;
      _repaint.value++;
    }
  }

  @override
  void dispose() {
    _removeRoute();
    _ticker?.dispose();
    _repaint.dispose();
    super.dispose();
  }

  // Eyes follow touches anywhere on screen.
  void _onPointer(PointerEvent event) {
    if (!mounted) return;
    if (event is! PointerDownEvent &&
        event is! PointerMoveEvent &&
        event is! PointerHoverEvent) {
      return;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final delta = event.position - center;
    final dist = delta.distance;
    if (dist < 1) {
      _lookTarget = Offset.zero;
    } else {
      final strength = 0.55 + 0.45 * math.min(1.0, dist / 160);
      _lookTarget = delta / dist * strength;
    }
    _pointerUntil = _t + 2.4;
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _t).clamp(0.0, 0.1);
    _t = now;

    // Blink: quick close/open, sometimes a double blink.
    if (_blinkStart == null && _t >= _nextBlink) _blinkStart = _t;
    if (_blinkStart != null) {
      final p = (_t - _blinkStart!) / 0.17;
      if (p >= 1) {
        _blink = 0;
        _blinkStart = null;
        _nextBlink =
            _t +
            (_rng.nextDouble() < 0.3 ? 0.22 : 2.4 + _rng.nextDouble() * 3.2);
      } else {
        _blink = p < 0.5 ? p * 2 : (1 - p) * 2;
      }
    }

    // Eye target: the user's finger wins, otherwise wander (or dart if thinking).
    if (_t > _pointerUntil) {
      if (widget.lookDirection != null) {
        _lookTarget = widget.lookDirection!;
      } else if (_t >= _nextWander) {
        if (widget.isThinking) {
          _lookTarget = Offset(
            0.35 + _rng.nextDouble() * 0.6,
            -0.9 + _rng.nextDouble() * 0.4,
          );
          _nextWander = _t + 0.5 + _rng.nextDouble() * 0.5;
        } else {
          _lookTarget = Offset(
            (_rng.nextDouble() - 0.5) * 1.3,
            (_rng.nextDouble() - 0.5) * 0.8,
          );
          _nextWander = _t + 1.6 + _rng.nextDouble() * 2.6;
        }
      }
    }
    final k = 1 - math.exp(-dt * 11);
    _look = Offset.lerp(_look, _lookTarget, k)!;

    if (_reactStart != null && _t - _reactStart! > _kReactSeconds) {
      _reactStart = null;
    }
    _repaint.value++;
  }

  void _react() {
    if (!widget.animated || _reduceMotion) {
      widget.onTap?.call();
      return;
    }
    _reactStart = _t;
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final painter = _IbowPainter(
      repaint: _repaint,
      pose: () => _Pose(
        t: widget.animated && !_reduceMotion ? _t : 0,
        look: widget.animated && !_reduceMotion ? _look : Offset.zero,
        blink: widget.animated && !_reduceMotion ? _blink : 0,
        react: _reactStart == null
            ? null
            : (_t - _reactStart!) / _kReactSeconds,
        holding: _holding,
        expression: widget.expression,
        exprAge: _t - _exprChangedAt,
        thinking: widget.isThinking && widget.animated,
        speaking: widget.isSpeaking && widget.animated,
      ),
    );

    final art = RepaintBoundary(
      child: CustomPaint(size: Size.square(widget.size), painter: painter),
    );

    if (!widget.animated && widget.onTap == null) {
      return SizedBox.square(dimension: widget.size, child: art);
    }

    return Semantics(
      button: widget.onTap != null || widget.animated,
      label: 'IBOW, the LeSgo assistant. Tap to say hello.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _react,
        onLongPressStart: (_) => _holding = true,
        onLongPressEnd: (_) => _holding = false,
        onLongPressCancel: () => _holding = false,
        child: SizedBox.square(dimension: widget.size, child: art),
      ),
    );
  }
}

const _kReactSeconds = 1.15;

class _Pose {
  const _Pose({
    required this.t,
    required this.look,
    required this.blink,
    required this.react,
    required this.holding,
    required this.thinking,
    required this.speaking,
    required this.expression,
    required this.exprAge,
  });

  final double t;
  final Offset look;
  final double blink;

  /// 0..1 progress of a tap reaction, null when not reacting.
  final double? react;
  final bool holding;
  final bool thinking;
  final bool speaking;
  final IbowExpression expression;

  /// Seconds since the expression last changed.
  final double exprAge;
}

class _IbowPainter extends CustomPainter {
  _IbowPainter({required Listenable repaint, required this.pose})
    : super(repaint: repaint);

  final _Pose Function() pose;

  // Palette sampled from the IBOW artwork.
  static const _bodyLight = Color(0xFFD9C4F9);
  static const _bodyMid = Color(0xFFBF9FF0);
  static const _bodyDark = Color(0xFFA784E2);
  static const _visorTop = Color(0xFF4B2A6E);
  static const _visorBottom = Color(0xFF2E1650);
  static const _eye = Color(0xFF1E0E29);
  static const _pink = Color(0xFFFF7FAE);
  static const _haloBase = Color(0xFF86E8B2);
  static const _haloLight = Color(0xFFE2FFEE);

  @override
  void paint(Canvas canvas, Size size) {
    final p = pose();
    final t = p.t;
    final r = p.react;
    final thinking = p.thinking;
    final speaking = p.speaking;
    final ex = p.expression;
    final happy =
        p.holding ||
        ex == IbowExpression.happy ||
        (r != null && r > 0.06 && r < 0.88);

    // Work in a 100x100 box, art is centred (it spans y 7..91).
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s, s);
    canvas.translate(0, 1);

    // ---- body motion -----------------------------------------------------
    final sleepy = ex == IbowExpression.sleepy;
    final floatSpeed = thinking
        ? 2 * math.pi / 1.2
        : (sleepy ? 2 * math.pi / 4.2 : 2 * math.pi / 2.6);
    final floatAmp = thinking ? 2.2 : (sleepy ? 1.0 : 1.6);
    var floatY = math.sin(t * floatSpeed) * floatAmp;
    // Sad sinks a little; a fresh sad face also gives a small head shake.
    if (ex == IbowExpression.sad) floatY += 1.6;
    var shakeX = 0.0;
    if (ex == IbowExpression.sad && p.exprAge < 1.2) {
      shakeX = math.sin(p.exprAge * 20) * 1.1 * (1 - p.exprAge / 1.2);
    }
    final breathe = 1 + math.sin(t * 2 * math.pi / 3.2) * 0.012;

    double jump = 0, sy = 1;
    if (r != null) {
      jump = -math.sin(r * math.pi) * 11 * (1 - r * 0.25);
      final anticipation = 1 - _smooth(0, 0.16, r);
      final landing = _smooth(0.86, 0.94, r) * (1 - _smooth(0.94, 1.0, r));
      sy =
          1 +
          0.07 * math.sin(r * math.pi) -
          0.11 * anticipation -
          0.07 * landing;
    }
    if (p.holding) {
      floatY += math.sin(t * 22) * 0.35; // giggle
    }
    final sx = 1 / sy;

    // Ground shadow stays on the floor and shrinks as IBOW rises.
    final lift = (-(floatY + jump)).clamp(0.0, 14.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 93.2),
        width: 42 - lift * 1.2,
        height: 4.6 - lift * 0.15,
      ),
      Paint()
        ..color = const Color(
          0xFF5F2D82,
        ).withValues(alpha: 0.14 - lift * 0.005),
    );

    canvas.save();
    canvas.translate(shakeX, floatY + jump);
    // Squash and stretch from the feet.
    canvas.translate(50, 90);
    canvas.scale(sx * breathe, sy * breathe);
    canvas.translate(-50, -90);

    _paintHalo(canvas, t, thinking, r, ex);
    _paintArms(canvas, t, thinking, speaking, r, p.holding, ex);
    _paintBody(canvas);
    _paintVisor(canvas, p, happy, thinking, speaking);
    _paintExpressionFx(canvas, p);
    _paintSparkles(canvas, r);

    canvas.restore();
    canvas.restore();
  }

  // ---------------------------------------------------------------- halo --
  void _paintHalo(
    Canvas canvas,
    double t,
    bool thinking,
    double? r,
    IbowExpression ex,
  ) {
    final bob =
        math.sin(t * (thinking ? 2 * math.pi / 1.2 : 2 * math.pi / 2.6) + 1.1) *
        (thinking ? 1.8 : 1.2);
    final lift = r == null ? 0.0 : -math.sin(r * math.pi) * 2.5;
    final tilt =
        math.sin(t * 2 * math.pi / 3.7) * 0.05 +
        (r == null ? 0 : math.sin(r * math.pi * 4) * 0.08);
    final center = Offset(50, 16 + bob + lift);
    final pulse = 0.5 + 0.5 * math.sin(t * (thinking ? 6 : 2));
    var glow =
        (thinking ? 0.5 : 0.28) +
        pulse * (thinking ? 0.3 : 0.12) +
        (r == null ? 0 : math.sin(r * math.pi) * 0.3);
    // The halo mirrors the mood: dim when sad or sleepy, bright when delighted.
    switch (ex) {
      case IbowExpression.sad:
        glow *= 0.45;
      case IbowExpression.sleepy:
        glow *= 0.4;
      case IbowExpression.happy:
      case IbowExpression.love:
      case IbowExpression.surprised:
        glow += 0.18;
      case IbowExpression.neutral:
      case IbowExpression.wink:
        break;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    final rect = Rect.fromCenter(center: Offset.zero, width: 47, height: 14.5);

    // Soft glow.
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.4
        ..color = _haloBase.withValues(alpha: glow.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6),
    );

    // Tube with a light that travels around the ring (fast while thinking).
    final spin = t * (thinking ? 5.5 : 0.9);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [
            _haloBase,
            _haloLight,
            _haloBase,
            Color(0xFF6FD9A0),
            _haloBase,
          ],
          stops: const [0, 0.1, 0.26, 0.66, 1],
          transform: GradientRotation(spin),
        ).createShader(rect),
    );
    canvas.restore();
  }

  // ---------------------------------------------------------------- arms --
  void _paintArms(
    Canvas canvas,
    double t,
    bool thinking,
    bool speaking,
    double? r,
    bool holding,
    IbowExpression ex,
  ) {
    var sway = math.sin(t * 2 * math.pi / 2.6 + 0.6) * 0.08;
    if (speaking) sway += math.sin(t * 5.2) * 0.1;
    if (thinking) sway += math.sin(t * 7) * 0.05;
    var lift = 0.0;
    if (r != null) {
      // Raise both arms and flap a few times at the top.
      lift =
          math.sin(r * math.pi) * 1.0 +
          math.sin(r * math.pi * 6) * 0.28 * math.sin(r * math.pi);
    }
    if (holding) lift = math.max(lift, 0.55 + math.sin(t * 20) * 0.08);
    switch (ex) {
      case IbowExpression.sad:
        lift = math.min(lift, -0.2); // arms droop
      case IbowExpression.surprised:
        lift = math.max(lift, 0.5);
      case IbowExpression.happy:
        lift = math.max(lift, 0.18 + math.sin(t * 6) * 0.08);
      case IbowExpression.love:
        lift = math.max(lift, 0.28 + math.sin(t * 3) * 0.06);
      case IbowExpression.sleepy:
        lift = math.min(lift, -0.1);
      case IbowExpression.neutral:
      case IbowExpression.wink:
        break;
    }

    _arm(
      canvas,
      const Offset(22, 60),
      const Offset(11, 61),
      -0.5,
      sway + lift,
      true,
    );
    _arm(
      canvas,
      const Offset(78, 60),
      const Offset(89, 61),
      0.5,
      -(sway + lift),
      false,
    );
  }

  void _arm(
    Canvas canvas,
    Offset shoulder,
    Offset c,
    double baseAngle,
    double rot,
    bool left,
  ) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(rot);
    canvas.translate(-shoulder.dx, -shoulder.dy);
    canvas.translate(c.dx, c.dy);
    canvas.rotate(baseAngle);
    final rect = Rect.fromCenter(center: Offset.zero, width: 17.5, height: 22);
    canvas.drawOval(
      rect.shift(const Offset(0, 1.1)),
      Paint()..color = const Color(0xFF7A55B8).withValues(alpha: 0.22),
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD7BEF8), Color(0xFFB794EC)],
        ).createShader(rect),
    );
    // Little highlight.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2.6, -4.6), width: 5, height: 7),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.restore();
  }

  // ---------------------------------------------------------------- body --
  void _paintBody(Canvas canvas) {
    const center = Offset(50, 56);
    const radius = 35.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.5),
          radius: 1.05,
          colors: [_bodyLight, _bodyMid, _bodyDark],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Panel seams.
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF8E6BD0).withValues(alpha: 0.35);
    canvas.drawPath(
      Path()
        ..moveTo(39, 24.5)
        ..quadraticBezierTo(36.5, 32, 37.5, 39),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(61, 24.5)
        ..quadraticBezierTo(63.5, 32, 62.5, 39),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(40.5, 70.5)
        ..quadraticBezierTo(38.5, 75, 39.5, 79),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(59.5, 70.5)
        ..quadraticBezierTo(61.5, 75, 60.5, 79),
      seam,
    );

    // Soft sheen.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(37, 33), width: 20, height: 11),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Belly patch.
    final belly = Rect.fromCenter(
      center: const Offset(50, 80.5),
      width: 31,
      height: 17,
    );
    canvas.drawOval(
      belly,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6D6F6), Color(0xFFCDB4E9)],
        ).createShader(belly),
    );
  }

  // --------------------------------------------------------------- visor --
  void _paintVisor(
    Canvas canvas,
    _Pose p,
    bool happy,
    bool thinking,
    bool speaking,
  ) {
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(50, 50.5), width: 57, height: 33),
      const Radius.circular(16.5),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_visorTop, _visorBottom],
        ).createShader(visor.outerRect),
    );
    canvas.drawRRect(
      visor.deflate(0.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    // Eyes.
    _paintEye(canvas, const Offset(35.3, 46.6), p, happy, isLeft: true);
    _paintEye(canvas, const Offset(64.3, 46.6), p, happy, isLeft: false);

    // Cheeks.
    final cheek = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = happy ? 1.9 : 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF8FB6).withValues(
        alpha: p.expression == IbowExpression.sad
            ? 0.4
            : (happy || p.expression == IbowExpression.love ? 1 : 0.88),
      );
    for (final cx in const [29.8, 70.3]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - 3.4, 56.4)
          ..quadraticBezierTo(cx, 53.6, cx + 3.4, 56.4),
        cheek,
      );
    }

    _paintMouth(canvas, p, happy, thinking, speaking);
  }

  void _paintEye(
    Canvas canvas,
    Offset c,
    _Pose p,
    bool happy, {
    required bool isLeft,
  }) {
    final ex = p.expression;

    if (ex == IbowExpression.love) {
      // Beating hearts for eyes.
      final beat = 1 + math.sin(p.t * 9) * 0.08;
      canvas.drawPath(
        _heart(c.translate(0, 0.6), 4.6 * beat),
        Paint()..color = const Color(0xFFFF6FA3),
      );
      canvas.drawCircle(
        c.translate(-1.6, -1.6),
        0.9,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      return;
    }

    // ^ ^ happy arcs (a wink only closes the right eye).
    if (happy || (ex == IbowExpression.wink && !isLeft)) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 4.4, c.dy + 1.8)
          ..quadraticBezierTo(c.dx, c.dy - 4.6, c.dx + 4.4, c.dy + 1.8),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
      return;
    }

    final surprised = ex == IbowExpression.surprised;
    final sad = ex == IbowExpression.sad;
    final sleepy = ex == IbowExpression.sleepy;

    final closed = sleepy
        ? math.max(p.blink, 0.62 + math.sin(p.t * 1.3) * 0.08)
        : p.blink.clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final grow = surprised ? 1.16 : 1.0;
    canvas.scale(grow, grow * math.max(0.07, 1 - closed));

    // Socket + iris/pupil that moves with the gaze.
    canvas.drawCircle(
      Offset.zero,
      6.3,
      Paint()..color = const Color(0xFF2B1640),
    );
    var gaze = Offset(p.look.dx * 1.5, p.look.dy * 1.2);
    if (sad) gaze = Offset(gaze.dx * 0.5, gaze.dy * 0.4 + 1.1); // looks down
    canvas.drawCircle(gaze, surprised ? 4.9 : 5.5, Paint()..color = _eye);
    // Highlights follow the iris a little more than the socket (gives depth).
    canvas.drawCircle(
      gaze + const Offset(1.9, -2.2) + Offset(p.look.dx * 0.5, p.look.dy * 0.4),
      sad ? 1.5 : 1.95,
      Paint()..color = Colors.white,
    );
    _star(
      canvas,
      gaze + const Offset(-1.9, 2.0) + Offset(p.look.dx * 0.3, p.look.dy * 0.3),
      sad ? 1.1 : 1.5,
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // Brows: worried when sad, raised when surprised.
    if (sad || surprised) {
      final brow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE9DAFB).withValues(alpha: 0.85);
      final inner = isLeft ? 1.0 : -1.0; // toward the centre of the face
      if (sad) {
        canvas.drawLine(
          Offset(c.dx + inner * 3.6, c.dy - 8.2),
          Offset(c.dx - inner * 3.6, c.dy - 6.4),
          brow,
        );
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 3.6, c.dy - 8.2)
            ..quadraticBezierTo(c.dx, c.dy - 10.8, c.dx + 3.6, c.dy - 8.2),
          brow,
        );
      }
    }
  }

  Path _heart(Offset c, double s) {
    return Path()
      ..moveTo(c.dx, c.dy + s * 0.9)
      ..cubicTo(
        c.dx - s * 1.6,
        c.dy - s * 0.2,
        c.dx - s * 0.8,
        c.dy - s * 1.3,
        c.dx,
        c.dy - s * 0.45,
      )
      ..cubicTo(
        c.dx + s * 0.8,
        c.dy - s * 1.3,
        c.dx + s * 1.6,
        c.dy - s * 0.2,
        c.dx,
        c.dy + s * 0.9,
      )
      ..close();
  }

  void _paintMouth(
    Canvas canvas,
    _Pose p,
    bool happy,
    bool thinking,
    bool speaking,
  ) {
    double open = 0.55;
    double widthFactor = 1;
    double xOffset = 0;
    final ex = p.expression;

    // Shapes that aren't the usual smile.
    if (!speaking && ex == IbowExpression.sad) {
      canvas.drawPath(
        Path()
          ..moveTo(46.2, 61.4)
          ..quadraticBezierTo(50, 57.4, 53.8, 61.4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round
          ..color = _pink,
      );
      return;
    }
    if (!speaking && ex == IbowExpression.surprised) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 60.2),
          width: 5.2,
          height: 6.2,
        ),
        Paint()..color = _pink,
      );
      return;
    }
    if (!speaking && ex == IbowExpression.sleepy) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(50, 59.4),
          width: 3.4,
          height: 1.8,
        ),
        Paint()..color = _pink.withValues(alpha: 0.85),
      );
      return;
    }
    if (speaking) {
      final t = p.t;
      open =
          0.2 +
          0.8 *
              (math.sin(t * 12).abs() * (0.6 + 0.4 * math.sin(t * 4.1).abs()));
    } else if (thinking) {
      open = 0.45;
      widthFactor = 0.42;
      xOffset = 2.2;
    } else if (happy || ex == IbowExpression.love) {
      open = 1.0;
      widthFactor = 1.12;
    } else if (ex == IbowExpression.wink) {
      open = 0.8;
      widthFactor = 1.05;
      xOffset = 0.6;
    }

    final hw = 6.2 * widthFactor;
    final bottom = 2.0 + 4.7 * open;
    final path = Path()
      ..moveTo(-hw, -2.2)
      ..quadraticBezierTo(0, -3.5, hw, -2.2)
      ..cubicTo(hw * 0.95, bottom * 0.55, hw * 0.45, bottom, 0, bottom)
      ..cubicTo(-hw * 0.45, bottom, -hw * 0.95, bottom * 0.55, -hw, -2.2)
      ..close();

    canvas.save();
    canvas.translate(50 + xOffset, 58.3);
    canvas.drawPath(path, Paint()..color = _pink);
    // Tongue hint when the mouth is open.
    if (open > 0.5) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, bottom - 1.1),
          width: hw * 1.1,
          height: 2.0,
        ),
        Paint()..color = const Color(0xFFFF5C93).withValues(alpha: 0.55),
      );
    }
    canvas.restore();
  }

  // ------------------------------------------------- expression effects --
  void _paintExpressionFx(Canvas canvas, _Pose p) {
    final t = p.t;
    switch (p.expression) {
      case IbowExpression.love:
        // Hearts drifting up from IBOW.
        for (var i = 0; i < 3; i++) {
          final phase = (t * 0.55 + i / 3) % 1.0;
          final pos = Offset(
            50 + (i - 1) * 15 + math.sin((phase + i) * 6) * 3,
            38 - phase * 26,
          );
          canvas.drawPath(
            _heart(pos, 3.2 * (1 - phase * 0.5)),
            Paint()
              ..color = const Color(0xFFFF6FA3).withValues(alpha: 1 - phase),
          );
        }
      case IbowExpression.sleepy:
        // Floating z z z.
        for (var i = 0; i < 3; i++) {
          final phase = (t * 0.32 + i / 3) % 1.0;
          final o = Offset(72 + phase * 9, 38 - phase * 18);
          final z = 1.6 + i * 0.7;
          canvas.drawPath(
            Path()
              ..moveTo(o.dx - z, o.dy - z)
              ..lineTo(o.dx + z, o.dy - z)
              ..lineTo(o.dx - z, o.dy + z)
              ..lineTo(o.dx + z, o.dy + z),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFF7A55B8).withValues(alpha: 1 - phase),
          );
        }
      case IbowExpression.sad:
        // A small tear sliding down the left cheek.
        final phase = (t * 0.7) % 1.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(31.2, 52.4 + phase * 5.5),
            width: 1.6,
            height: 2.4,
          ),
          Paint()
            ..color = const Color(
              0xFF9ED8FF,
            ).withValues(alpha: 1 - phase * 0.8),
        );
      case IbowExpression.neutral:
      case IbowExpression.happy:
      case IbowExpression.surprised:
      case IbowExpression.wink:
        break;
    }
  }

  // ------------------------------------------------------------ sparkles --
  void _paintSparkles(Canvas canvas, double? r) {
    if (r == null || r <= 0.03 || r >= 1) return;
    const colors = [
      Color(0xFFFF8FB6),
      Color(0xFF86E8B2),
      Colors.white,
      Color(0xFFFFE08A),
    ];
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + 0.35;
      final progress = _smooth(0.05, 0.9, r);
      final dist = 20 + progress * 24 + (i.isEven ? 5 : 0);
      final pos = Offset(
        50 + math.cos(angle) * dist,
        44 + math.sin(angle) * dist * 0.85,
      );
      final fade = (1 - _smooth(0.55, 1.0, r));
      final size = (2.2 + (i % 3) * 0.9) * fade;
      if (size <= 0.1) continue;
      _star(
        canvas,
        pos,
        size,
        Paint()..color = colors[i % colors.length].withValues(alpha: fade),
      );
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  static double _smooth(double a, double b, double x) {
    final v = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return v * v * (3 - 2 * v);
  }

  @override
  bool shouldRepaint(covariant _IbowPainter oldDelegate) => true;
}
