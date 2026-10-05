import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MapLoadingIndicator extends StatelessWidget {
  const MapLoadingIndicator({super.key, this.size = 24.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/images/map.svg', width: size, height: size);
  }
}

class LoadingTextWithDots extends StatefulWidget {
  const LoadingTextWithDots({super.key});

  @override
  State<LoadingTextWithDots> createState() => _LoadingTextWithDotsState();
}

class _LoadingTextWithDotsState extends State<LoadingTextWithDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Cycle through 0, 1, 2 (representing 1, 2, 3 dots)
        final progress = _controller.value;
        int dotCount;
        if (progress < 0.33) {
          dotCount = 1;
        } else if (progress < 0.66) {
          dotCount = 2;
        } else {
          dotCount = 3;
        }

        return Text(
          'Loading${'.' * dotCount}',
          style:  TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.black87),
          ),
        );
      },
    );
  }
}
