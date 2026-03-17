import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeout;

  const CountdownTimer({
    super.key,
    required this.seconds,
    required this.onTimeout,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer _) {
    if (!mounted) return;
    setState(() => _remaining--);
    if (_remaining <= 0) {
      _timer?.cancel();
      widget.onTimeout();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraction = _remaining / widget.seconds;
    final color = fraction > 0.5
        ? cs.primary
        : fraction > 0.25
            ? Colors.orange
            : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: cs.outline,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$_remaining',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
