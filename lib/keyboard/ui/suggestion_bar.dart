/// Suggestion bar — status strip + chips, adaptive for narrow IME slots.
library;

import 'package:flutter/material.dart';

import '../actions/local_text_transform.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import 'panel_actions.dart';

/// Soft dark tokens — same family as keyboard, low-contrast alerts.
abstract final class _TactPanelColors {
  /// Match native panel bar — no brown/yellow wash.
  static const surface = Color(0xFF161920);
  static const chipBg = Color(0xFF2A2E36);
  static const text = Color(0xFFE8EAED);
  static const textMuted = Color(0xFF8B929C);
  static const action = Color(0xFF2A9B8F);
  static const actionPressed = Color(0xFF238078);
  static const mat = Color(0xFFD07A7A);
  static const toxic = Color(0xFFC9A86A);
  static const improve = Color(0xFF5BA89E);
  static const undo = Color(0xFF6BC49A);
  static const border = Color(0xFF252A32);
  static const suggestionDivider = Color(0xFF3A4048);
}

/// Responsive sizing for the IME suggestion slot (width + height).
final class _PanelMetrics {
  const _PanelMetrics({
    required this.width,
    required this.height,
    required this.inlineSubtitle,
    required this.iconSize,
    required this.titleSize,
    required this.subtitleSize,
    required this.actionFontSize,
    required this.chipFontSize,
    required this.outerH,
    required this.outerV,
    required this.hPad,
    required this.vPad,
    required this.gap,
    required this.chipPadH,
    required this.chipPadV,
    required this.actionPadH,
    required this.actionPadV,
    required this.radius,
    required this.dividerInset,
  });

  final double width;
  final double height;
  final bool inlineSubtitle;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final double actionFontSize;
  final double chipFontSize;
  final double outerH;
  final double outerV;
  final double hPad;
  final double vPad;
  final double gap;
  final double chipPadH;
  final double chipPadV;
  final double actionPadH;
  final double actionPadV;
  final double radius;
  final double dividerInset;

  /// Bucketed metrics from available slot — width and height both matter.
  factory _PanelMetrics.forConstraints(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
        ? constraints.maxHeight
        : 36.0;

    if (w < 340 || h < 34) {
      return _PanelMetrics(
        width: w,
        height: h,
        inlineSubtitle: true,
        iconSize: 14,
        titleSize: 11,
        subtitleSize: 10,
        actionFontSize: 10,
        chipFontSize: 11,
        outerH: 4,
        outerV: 2,
        hPad: 6,
        vPad: 3,
        gap: 5,
        chipPadH: 8,
        chipPadV: 3,
        actionPadH: 8,
        actionPadV: 3,
        radius: 7,
        dividerInset: 6,
      );
    }
    if (w < 400 || h < 40) {
      return _PanelMetrics(
        width: w,
        height: h,
        inlineSubtitle: true,
        iconSize: 15,
        titleSize: 11,
        subtitleSize: 10,
        actionFontSize: 10,
        chipFontSize: 11,
        outerH: 5,
        outerV: 2,
        hPad: 7,
        vPad: 3,
        gap: 5,
        chipPadH: 8,
        chipPadV: 3,
        actionPadH: 9,
        actionPadV: 4,
        radius: 8,
        dividerInset: 7,
      );
    }
    return _PanelMetrics(
      width: w,
      height: h,
      inlineSubtitle: w < 380,
      iconSize: 16,
      titleSize: 12,
      subtitleSize: 10,
      actionFontSize: 11,
      chipFontSize: 12,
      outerH: 5,
      outerV: 3,
      hPad: 8,
      vPad: 4,
      gap: 6,
      chipPadH: 10,
      chipPadV: 4,
      actionPadH: 10,
      actionPadV: 4,
      radius: 8,
      dividerInset: 8,
    );
  }

  TextStyle get titleStyle => switch (titleSize) {
        11 => _title11,
        _ => _title12,
      };

  TextStyle get subtitleStyle => switch (subtitleSize) {
        10 => _subtitle10,
        _ => _subtitle11,
      };

  TextStyle get chipStyle => switch (chipFontSize) {
        11 => _chip11,
        _ => _chip12,
      };

  TextStyle get actionStyle => switch (actionFontSize) {
        10 => _action10,
        _ => _action11,
      };

  static const _title11 = TextStyle(
    color: _TactPanelColors.text,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.15,
    decoration: TextDecoration.none,
  );
  static const _title12 = TextStyle(
    color: _TactPanelColors.text,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.15,
    decoration: TextDecoration.none,
  );
  static const _subtitle10 = TextStyle(
    color: _TactPanelColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.15,
    decoration: TextDecoration.none,
  );
  static const _subtitle11 = TextStyle(
    color: _TactPanelColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.15,
    decoration: TextDecoration.none,
  );
  static const _chip11 = TextStyle(
    color: _TactPanelColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.0,
    decoration: TextDecoration.none,
  );
  static const _chip12 = TextStyle(
    color: _TactPanelColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    decoration: TextDecoration.none,
  );
  static const _action10 = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );
  static const _action11 = TextStyle(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );
}

/// Quiet brand mark for the idle suggestion strip — almost a watermark.
class _TactBrandMark extends StatelessWidget {
  const _TactBrandMark();

  static const _style = TextStyle(
    color: Color(0x3D8B929C),
    fontSize: 9,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
    height: 1.0,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tact',
        key: Key('tact_brand_mark'),
        style: _style,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SuggestionBar extends StatelessWidget {
  const SuggestionBar({
    super.key,
    required this.panel,
    required this.backgroundColor,
    required this.onAction,
  });

  final PanelState panel;
  final Color backgroundColor;
  final Future<void> Function(PanelAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('suggestion_bar_root'),
      color: backgroundColor,
      child: panel is PanelIdle
          ? const _TactBrandMark()
          : LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _PanelMetrics.forConstraints(constraints);
                final gboardStrip =
                    panel is PanelSuggestions || panel is PanelShortcut;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: gboardStrip ? 0 : metrics.outerH,
                    vertical: gboardStrip ? 0 : metrics.outerV,
                  ),
                  child: _PanelBody(
                    panel: panel,
                    onAction: onAction,
                    metrics: metrics,
                  ),
                );
              },
            ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({
    required this.panel,
    required this.onAction,
    required this.metrics,
  });

  final PanelState panel;
  final Future<void> Function(PanelAction action) onAction;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return switch (panel) {
      PanelIdle() => const SizedBox.shrink(),
      PanelUndo(:final label) => _StatusBar(
          accent: _TactPanelColors.undo,
          icon: Icons.check_circle_outline,
          title: label,
          actionLabel: 'Отменить',
          metrics: metrics,
          onAction: () => onAction(const PanelActionUndo()),
        ),
      PanelMat p => _StatusBar(
          accent: _TactPanelColors.mat,
          icon: Icons.block,
          title: 'Мат',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Убрать',
          metrics: metrics,
          onAction: () => onAction(PanelActionRemoveMat(panel: p)),
        ),
      PanelToxic p => _StatusBar(
          accent: _TactPanelColors.toxic,
          icon: Icons.warning_amber_rounded,
          title: p.level == ToxicLevel.conflict ? 'Конфликт' : 'Токсично',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Смягчить',
          metrics: metrics,
          onAction: () => onAction(PanelActionSoftenToxic(panel: p)),
        ),
      PanelImprove() => _StatusBar(
          accent: _TactPanelColors.improve,
          icon: Icons.auto_awesome,
          title: 'Можно улучшить',
          actionLabel: 'Улучшить',
          metrics: metrics,
          onAction: () => onAction(const PanelActionImprove()),
        ),
      PanelShortcut(:final trigger, :final expansions) => _EqualChipRow(
          metrics: metrics,
          chips: expansions
              .take(3)
              .map(
                (e) => _ChipData(
                  '$trigger → $e',
                  onTap: () => onAction(PanelActionShortcut(expansion: e)),
                ),
              )
              .toList(growable: false),
        ),
      PanelSuggestions(:final words) => _EqualChipRow(
          metrics: metrics,
          chips: words
              .take(3)
              .map(
                (w) => _ChipData(
                  w,
                  onTap: () => onAction(PanelActionSuggestion(word: w)),
                ),
              )
              .toList(growable: false),
        ),
    };
  }
}

/// Label exposed to semantics (and widget tests) without decorative noise.
class _PanelText extends StatelessWidget {
  const _PanelText(this.text, {required this.style, this.maxLines = 1});

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Text(
        text,
        style: style.copyWith(decoration: TextDecoration.none),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.accent,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.metrics,
    required this.onAction,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final _PanelMetrics metrics;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    // Compact centered cluster — not stretched edge-to-edge.
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.hPad),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: accent.withValues(alpha: 0.9), size: m.iconSize),
            SizedBox(width: m.gap),
            Flexible(
              child: _StatusMessage(
                title: title,
                subtitle: hasSubtitle ? subtitle! : null,
                inline: true,
                metrics: m,
              ),
            ),
            if (onAction != null) ...[
              SizedBox(width: m.gap + 6),
              _PanelActionButton(
                label: actionLabel,
                metrics: m,
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.title,
    required this.subtitle,
    required this.inline,
    required this.metrics,
  });

  final String title;
  final String? subtitle;
  final bool inline;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final titleStyle = metrics.titleStyle;
    final subtitleStyle = metrics.subtitleStyle;

    if (subtitle == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _PanelText(title, style: titleStyle),
      );
    }

    if (inline) {
      final combined = '$title · $subtitle';
      return Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          label: combined,
          excludeSemantics: true,
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: titleStyle,
              children: [
                TextSpan(text: title),
                TextSpan(
                  text: ' · $subtitle',
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelText(title, style: titleStyle),
        _PanelText(subtitle!, style: subtitleStyle),
      ],
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.label,
    required this.metrics,
    required this.onTap,
  });

  final String label;
  final _PanelMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(metrics.radius * 0.7),
          child: Ink(
            decoration: BoxDecoration(
              color: _TactPanelColors.action.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(metrics.radius * 0.7),
              border: Border.all(
                color: _TactPanelColors.action.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.actionPadH,
                vertical: metrics.actionPadV,
              ),
              child: _PanelText(
                label,
                style: metrics.actionStyle.copyWith(
                  color: _TactPanelColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ChipData {
  const _ChipData(this.label, {this.onTap});
  final String label;
  final VoidCallback? onTap;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips, required this.metrics});

  final List<_ChipData> chips;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return _PanelSurface(
      metrics: metrics,
      borderColor: _TactPanelColors.border,
      child: _ChipScroller(metrics: metrics, chips: chips),
    );
  }
}

/// Gboard-style: equal columns, hairline ticks, full-bleed strip.
class _EqualChipRow extends StatelessWidget {
  const _EqualChipRow({required this.chips, required this.metrics});

  final List<_ChipData> chips;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) _SuggestionDivider(inset: metrics.dividerInset + 2),
          Expanded(
            child: _EqualSuggestionSlot(
              chip: chips[i],
              metrics: metrics,
            ),
          ),
        ],
      ],
    );
  }
}

/// Short vertical tick — inset so it doesn't span the full bar height.
class _SuggestionDivider extends StatelessWidget {
  const _SuggestionDivider({required this.inset});

  final double inset;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: inset,
      endIndent: inset,
      color: _TactPanelColors.suggestionDivider.withValues(alpha: 0.55),
    );
  }
}

class _EqualSuggestionSlot extends StatelessWidget {
  const _EqualSuggestionSlot({required this.chip, required this.metrics});

  final _ChipData chip;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: chip.onTap != null,
      label: chip.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: chip.onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PanelText(
                chip.label,
                style: metrics.chipStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const _PanelSurface({
    required this.metrics,
    required this.borderColor,
    this.accent,
    required this.child,
  });

  final _PanelMetrics metrics;
  final Color borderColor;
  final Color? accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _TactPanelColors.surface,
        borderRadius: BorderRadius.circular(metrics.radius),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.hPad,
          vertical: metrics.vPad,
        ),
        child: child,
      ),
    );
  }
}

class _ChipScroller extends StatelessWidget {
  const _ChipScroller({required this.metrics, required this.chips});

  final _PanelMetrics metrics;
  final List<_ChipData> chips;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[
              _SuggestionChip(chip: chip, metrics: metrics),
              SizedBox(width: metrics.gap),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.chip, required this.metrics});

  final _ChipData chip;
  final _PanelMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: chip.onTap != null,
      label: chip.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: chip.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            decoration: BoxDecoration(
              color: _TactPanelColors.chipBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _TactPanelColors.border.withValues(alpha: 0.8),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.chipPadH,
                vertical: metrics.chipPadV,
              ),
              child: _PanelText(
                chip.label,
                style: metrics.chipStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
