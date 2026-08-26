import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _weekdayFormat = DateFormat('EEE');

/// A macOS-Calendar-style tile: red weekday header, big day number below,
/// live (updates itself, no external state needed). Generic "shows today's
/// date" convention, not a copy of any specific app's icon asset.
class CalendarTile extends StatefulWidget {
  const CalendarTile({super.key});

  @override
  State<CalendarTile> createState() => _CalendarTileState();
}

class _CalendarTileState extends State<CalendarTile> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFF3B30),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            _weekdayFormat.format(_now).toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_now.day}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
