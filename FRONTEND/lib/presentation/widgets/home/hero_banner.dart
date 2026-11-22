import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HeroBanner extends StatelessWidget {
  final String? userName;
  final bool showGreeting;
  final String backgroundImagePath;
  final String title;
  final String subtitle;
  final VoidCallback? onBookNowPressed;

  const HeroBanner({
    super.key,
    required this.userName,
    this.showGreeting = true,
    required this.backgroundImagePath,
    required this.title,
    required this.subtitle,
    this.onBookNowPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = backgroundImagePath.toLowerCase().endsWith('.svg');
    final greeting = showGreeting
        ? (userName == null ? 'Welcome to LeSgo' : 'Hello, $userName!')
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final wideCopy = textScale > 1.3 || constraints.maxWidth < 330;
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF241038)),
            ExcludeSemantics(
              child: isSvg
                  ? SvgPicture.asset(
                      backgroundImagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    )
                  : Image.asset(
                      backgroundImagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: wideCopy
                      ? const [
                          Color(0xFF241038),
                          Color(0xDE241038),
                          Color(0xAC241038),
                        ]
                      : const [
                          Color(0xFF241038),
                          Color(0xE6241038),
                          Color(0x19241038),
                        ],
                  stops: const [0, .40, 1],
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: wideCopy
                        ? (constraints.maxWidth - 36).clamp(0.0, 480.0)
                        : (constraints.maxWidth * .62).clamp(0.0, 340.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (greeting != null) ...[
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE2CFFC),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFF1E5FA),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: onBookNowPressed,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Book now'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF2E4FF),
                          foregroundColor: const Color(0xFF35134E),
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
