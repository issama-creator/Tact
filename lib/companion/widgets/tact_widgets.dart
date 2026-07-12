import 'package:flutter/material.dart';
import '../theme/tact_theme.dart';

/// Consistent section title used below page headers.
class TactSectionLabel extends StatelessWidget {
  const TactSectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: TactColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

class TactCard extends StatelessWidget {
  const TactCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? TactColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: TactColors.surfaceBorder, width: 0.5),
      ),
      child: child,
    );
  }
}

class TactSectionHeader extends StatelessWidget {
  const TactSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: TactColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 14,
              color: TactColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class TactToggleRow extends StatelessWidget {
  const TactToggleRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TactLayout.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TactColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TactColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TactSettingsRow extends StatelessWidget {
  const TactSettingsRow({
    super.key,
    required this.title,
    this.trailing,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    return Semantics(
      button: interactive,
      label: subtitle != null ? '$title, $subtitle' : title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: interactive ? null : Colors.transparent,
          highlightColor: interactive ? null : Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TactLayout.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            color: titleColor ?? TactColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TactColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (showChevron && interactive) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: TactColors.textMuted,
                      size: 22,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CommunicationScoreRing extends StatelessWidget {
  const CommunicationScoreRing({
    super.key,
    required this.score,
    required this.maxScore,
    this.size = 100,
  });

  final int score;
  final int maxScore;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: TactColors.textPrimary,
                  height: 1,
                ),
              ),
              Text(
                '/$maxScore',
                style: const TextStyle(
                  fontSize: 13,
                  color: TactColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const stroke = 8.0;

    final bg = Paint()
      ..color = const Color(0xFF1F2937)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        startAngle: -1.57,
        endAngle: 4.71,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      2 * 3.14159 * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class PanelPreviewBar extends StatelessWidget {
  const PanelPreviewBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: const Color(0xFFC9A86A).withValues(alpha: 0.9),
              size: 16,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8EAED),
                  ),
                  children: [
                    TextSpan(text: 'Токсично'),
                    TextSpan(
                      text: ' · туп***',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B929C),
                      ),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9B8F).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFF2A9B8F).withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                'Смягчить',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8EAED),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniKeyboardPreview extends StatelessWidget {
  const MiniKeyboardPreview({super.key, this.showPanel = true});

  final bool showPanel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12141A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TactColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPanel) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: PanelPreviewBar(),
            ),
            const SizedBox(height: 6),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
            child: Column(
              children: [
                _keyRow(['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х']),
                const SizedBox(height: 4),
                _keyRow(['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э']),
                const SizedBox(height: 4),
                _keyRow(['⇧', 'я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '⌫']),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _fnKey('?123', flex: 1.35),
                    _fnKey('🙂,', flex: 1),
                    _fnKey('🌐', flex: 1),
                    Expanded(
                      flex: 48,
                      child: Container(
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C2028),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: const Color(0x28FFFFFF),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Русский',
                          style: TextStyle(
                            fontSize: 8,
                            color: TactColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    _fnKey('.', flex: 1),
                    _fnKey('↵', flex: 1.6, accent: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys, {bool flexLast = false}) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++)
          Expanded(
            child: Container(
              height: 28,
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 2,
                right: i == keys.length - 1 ? 0 : 2,
              ),
              decoration: BoxDecoration(
                color: i == 0 || i == keys.length - 1
                    ? const Color(0xFF1C2028)
                    : const Color(0xFF2A2E36),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0x28FFFFFF), width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                keys[i],
                style: TextStyle(
                  fontSize: keys[i].length > 1 ? 9 : 11,
                  color: TactColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fnKey(String label, {required double flex, bool accent = false}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Container(
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: accent ? TactColors.accent : const Color(0xFF1C2028),
          borderRadius: BorderRadius.circular(7),
          border: accent
              ? null
              : Border.all(color: const Color(0x28FFFFFF), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 2 ? 8 : 10,
            color: accent ? Colors.white : TactColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
