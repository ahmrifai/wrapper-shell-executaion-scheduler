// lib/widgets/log_entry_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log_entry.dart';

class LogEntryTile extends StatelessWidget {
  final LogEntry entry;

  const LogEntryTile({super.key, required this.entry});

  Color get _borderColor {
    switch (entry.level) {
      case LogLevel.success:
        return const Color(0xFF22C55E);
      case LogLevel.error:
        return const Color(0xFFEF4444);
      case LogLevel.warning:
        return const Color(0xFFF59E0B);
      case LogLevel.info:
        return const Color(0xFF3B82F6);
    }
  }

  Color get _bgColor {
    switch (entry.level) {
      case LogLevel.success:
        return const Color(0xFFF0FDF4);
      case LogLevel.error:
        return const Color(0xFFFEF2F2);
      case LogLevel.warning:
        return const Color(0xFFFFFBEB);
      case LogLevel.info:
        return const Color(0xFFEFF6FF);
    }
  }

  Color get _textColor {
    switch (entry.level) {
      case LogLevel.success:
        return const Color(0xFF16A34A);
      case LogLevel.error:
        return const Color(0xFFDC2626);
      case LogLevel.warning:
        return const Color(0xFFD97706);
      case LogLevel.info:
        return const Color(0xFF2563EB);
    }
  }

  IconData get _icon {
    switch (entry.level) {
      case LogLevel.success:
        return Icons.check_circle_outline_rounded;
      case LogLevel.error:
        return Icons.error_outline_rounded;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy-MM-dd').format(entry.timestamp);
    final timeStr = DateFormat('HH:mm:ss').format(entry.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: _textColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: '$dateStr $timeStr',
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    const TextSpan(text: '  |  '),
                    TextSpan(
                      text: entry.levelLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '  |  '),
                    TextSpan(
                      text: entry.message,
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
