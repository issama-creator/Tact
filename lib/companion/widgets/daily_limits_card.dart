import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import 'tact_widgets.dart';

/// Compact daily usage limits — shared by Keyboard and Profile.
class DailyLimitsCard extends StatefulWidget {
  const DailyLimitsCard({super.key, required this.state});

  final CompanionAppState state;

  @override
  State<DailyLimitsCard> createState() => _DailyLimitsCardState();
}

class _DailyLimitsCardState extends State<DailyLimitsCard> {
  Timer? _timer;
  Duration _untilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _untilReset = _remainingToday();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _untilReset = _remainingToday());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static Duration _remainingToday() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return TactCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          _LimitRow(
            label: 'Орфография',
            used: s.orthographyUsed,
            limit: s.orthographyLimit,
            color: TactColors.orange,
          ),
          const SizedBox(height: 10),
          _LimitRow(
            label: 'Пунктуация',
            used: s.punctuationUsed,
            limit: s.punctuationLimit,
            color: TactColors.purple,
          ),
          const SizedBox(height: 10),
          _LimitRow(
            label: 'Улучшить текст',
            used: s.improveTextUsed,
            limit: s.improveTextLimit,
            color: TactColors.blue,
          ),
          const SizedBox(height: 10),
          Text(
            'Обновление через ${_formatDuration(_untilReset)}',
            style: const TextStyle(
              fontSize: 11,
              color: TactColors.textMuted,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.label,
    required this.used,
    required this.limit,
    required this.color,
  });

  final String label;
  final int used;
  final int limit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: TactColors.textPrimary,
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$used',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' / $limit',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TactColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
    );
  }
}
