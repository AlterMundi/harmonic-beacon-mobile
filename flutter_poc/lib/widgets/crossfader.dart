import 'package:flutter/material.dart';

class Crossfader extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const Crossfader({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: const Color(0xFF6346FF),
            inactiveTrackColor: const Color(0xFFFBBF24).withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Beacon',
                style: TextStyle(
                  color: Color(0xFF6346FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\u25C4\u2500\u2500\u2500\u2500\u2500\u2500\u25BA',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                ),
              ),
              Text(
                'Voice',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
