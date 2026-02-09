import 'dart:math';

import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final int barCount;
  final Color color;

  const AudioVisualizer({
    super.key,
    this.barCount = 24,
    this.color = const Color(0xFF6346FF),
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;
  late List<double> _targetHeights;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(widget.barCount, (_) => _random.nextDouble());
    _targetHeights =
        List.generate(widget.barCount, (_) => _random.nextDouble());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_updateBars);

    _controller.repeat();
  }

  void _updateBars() {
    setState(() {
      for (int i = 0; i < widget.barCount; i++) {
        // Smoothly interpolate toward target
        _barHeights[i] += (_targetHeights[i] - _barHeights[i]) * 0.15;

        // Occasionally pick a new target
        if (_random.nextDouble() < 0.1) {
          _targetHeights[i] = 0.2 + _random.nextDouble() * 0.8;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth / (widget.barCount * 2);
        final maxHeight = constraints.maxHeight;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            final height = _barHeights[index] * maxHeight;
            // Create gradient opacity based on distance from center
            final distFromCenter =
                (index - widget.barCount / 2).abs() / (widget.barCount / 2);
            final opacity = 1.0 - (distFromCenter * 0.5);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: barWidth * 0.3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: barWidth,
                height: height.clamp(4.0, maxHeight),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(barWidth / 2),
                  color: widget.color.withOpacity(opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
