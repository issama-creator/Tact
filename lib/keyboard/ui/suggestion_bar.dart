/// Suggestion bar — status strip + chips, adaptive for narrow IME slots.
library;

import 'package:flutter/material.dart';

import '../actions/local_text_transform.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import 'panel_actions.dart';

/// Design tokens aligned with companion [PanelPreviewBar].
abstract final class _TactPanelColors {
  static const surface = Color(0xFF22212A);
  static const chipBg = Color(0xFF2E2D36);
  static const text = Color(0xFFE8E8EA);
  static const textMuted = Color(0xFF9A9AA3);
  static const action = Color(0xFF7C5CFF);
  static const actionPressed = Color(0xFF6A4FE0);
  static const mat = Color(0xFFC94B4B);
  static const toxic = Color(0xFFE8B339);
  static const improve = Color(0xFF7C5CFF);
  static const undo = Color(0xFF3DDC97);
  static const border = Color(0xFF33323C);
  /// Gboard-style suggestion separators (mid-gray on dark bar).
  static const suggestionDivider = Color(0xFF6A6A72);
}

/// Responsive sizing for ~38dp IME suggestion slots (320–430+ px wide).
final class _PanelMetrics {
  const _PanelMetrics({
    required this.width,
    required this.inlineSubtitle,
    required this.iconSize,
    required this.titleSize,
    required this.subtitleSize,
    required this.actionFontSize,
    required this.chipFontSize,
    required this.hPad,
    required this.gap,
    required this.chipPadH,
    required this.chipPadV,
    required this.actionPadH,
    required this.actionPadV,
    required this.radius,
  });

  final double width;
  final bool inlineSubtitle;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final double actionFontSize;
  final double chipFontSize;
  final double hPad;
  final double gap;
  final double chipPadH;
  final double chipPadV;
  final double actionPadH;
  final double actionPadV;
  final double radius;

  static const tight = _PanelMetrics(
    width: 320,
    inlineSubtitle: true,
    iconSize: 16,
    titleSize: 11,
    subtitleSize: 10,
    actionFontSize: 10,
    chipFontSize: 11,
    hPad: 6,
    gap: 5,
    chipPadH: 8,
    chipPadV: 4,
    actionPadH: 8,
    actionPadV: 4,
    radius: 7,
  );

  static const compact = _PanelMetrics(
    width: 360,
    inlineSubtitle: true,
    iconSize: 18,
    titleSize: 12,
    subtitleSize: 11,
    actionFontSize: 11,
    chipFontSize: 12,
    hPad: 8,
    gap: 6,
    chipPadH: 10,
    chipPadV: 5,
    actionPadH: 10,
    actionPadV: 5,
    radius: 8,
  );

  static const comfortable = _PanelMetrics(
    width: 400,
    inlineSubtitle: false,
    iconSize: 18,
    titleSize: 12,
    subtitleSize: 11,
    actionFontSize: 11,
    chipFontSize: 12,
    hPad: 8,
    gap: 6,
    chipPadH: 10,
    chipPadV: 5,
    actionPadH: 10,
    actionPadV: 5,
    radius: 8,
  );

  /// Bucketed metrics — zero alloc after first width class is known.
  factory _PanelMetrics.forWidth(double width) {
    if (width < 340) return tight;
    if (width < 380) return compact;
    return comfortable;
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
    color: _TactPanelColors.text,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );
  static const _chip12 = TextStyle(
    color: _TactPanelColors.text,
    fontSize: 12,
    fontWeight: FontWeight.w500,
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

/// Quiet brand mark for the idle suggestion strip — identifies Tact without
/// competing with chips or status content.
class _TactBrandMark extends StatelessWidget {
  const _TactBrandMark();

  static const _style = TextStyle(
    color: Color(0x669A9AA3),
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.8,
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
                final metrics = _PanelMetrics.forWidth(constraints.maxWidth);
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 340 ? 4 : 6,
                    vertical: 1,
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
          title: 'Обнаружен мат',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Убрать',
          metrics: metrics,
          onAction: () => onAction(PanelActionRemoveMat(panel: p)),
        ),
      PanelToxic p => _StatusBar(
          accent: _TactPanelColors.toxic,
          icon: Icons.warning_amber_rounded,
          title: p.level == ToxicLevel.conflict
              ? 'Возможен конфликт'
              : 'Найдено токсичное слово',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Смягчить',
          metrics: metrics,
          onAction: () => onAction(PanelActionSoftenToxic(panel: p)),
        ),
      PanelImprove() => _StatusBar(
          accent: _TactPanelColors.improve,
          icon: Icons.auto_awesome,
          title: 'Можно улучшить текст',
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _TactPanelColors.surface,
        borderRadius: BorderRadius.circular(m.radius),
        border: Border.all(color: _TactPanelColors.border),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(m.radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              accent.withValues(alpha: 0.14),
              accent.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: m.hPad + 2,
            right: m.hPad,
            top: 3,
            bottom: 3,
          ),
          child: Row(
            children: [
              _AccentIcon(accent: accent, icon: icon, size: m.iconSize),
              SizedBox(width: m.gap),
              Expanded(child: _StatusMessage(
                title: title,
                subtitle: hasSubtitle ? subtitle! : null,
                inline: m.inlineSubtitle,
                metrics: m,
              )),
              if (onAction != null) ...[
                SizedBox(width: m.gap),
                _PanelActionButton(
                  label: actionLabel,
                  metrics: m,
                  onTap: onAction!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentIcon extends StatelessWidget {
  const _AccentIcon({
    required this.accent,
    required this.icon,
    required this.size,
  });

  final Color accent;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: accent, size: size),
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
          borderRadius: BorderRadius.circular(6),
          child: Ink(
            decoration: BoxDecoration(
              color: _TactPanelColors.action,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.actionPadH,
                vertical: metrics.actionPadV,
              ),
              child: _PanelText(
                '$label →',
                style: metrics.actionStyle,
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

/// Gboard-style: suggestions share the bar equally, thin ticks between them.
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
          if (i > 0) const _SuggestionDivider(),
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

/// Short vertical tick — does not span the full bar height (like Gboard).
class _SuggestionDivider extends StatelessWidget {
  const _SuggestionDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      width: 12,
      thickness: 1,
      indent: 8,
      endIndent: 8,
      color: _TactPanelColors.suggestionDivider,
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
              padding: EdgeInsets.symmetric(horizontal: metrics.hPad),
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
          vertical: 3,
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
