import 'package:flutter/material.dart';
import 'dart:math' as math;

class StudioWaveform extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  const StudioWaveform({super.key, required this.isPlaying, this.color = Colors.deepPurpleAccent});

  @override
  State<StudioWaveform> createState() => _StudioWaveformState();
}

class _StudioWaveformState extends State<StudioWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.generate(30, (index) => 0.1 + (index % 5) * 0.2);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(StudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_heights.length, (index) {
            double value = _controller.value;
            double height = 5 + (math.sin((value * 2 * math.pi) + (index * 0.5)) * 15).abs() * (widget.isPlaying ? 1.5 : 0.2);
            return Container(
              width: 4,
              height: 10 + height,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  if (widget.isPlaying)
                    BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
