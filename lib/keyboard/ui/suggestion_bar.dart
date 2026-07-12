/// Suggestion bar — status strip + chips, adaptive for narrow IME slots.
library;

import 'package:flutter/material.dart';

import '../actions/local_text_transform.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import '../theme/keyboard_theme.dart';
import 'panel_actions.dart';

/// Semantic alert accents — stay recognizable on every keyboard theme.
abstract final class _PanelAlertColors {
  static const mat = Color(0xFFD07A7A);
  static const toxic = Color(0xFFC9A86A);
  static const undo = Color(0xFF6BC49A);
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

  TextStyle titleStyle(Color color) => TextStyle(
        color: color,
        fontSize: titleSize,
        fontWeight: FontWeight.w600,
        height: 1.15,
        decoration: TextDecoration.none,
      );

  TextStyle subtitleStyle(Color color) => TextStyle(
        color: color,
        fontSize: subtitleSize,
        fontWeight: FontWeight.w500,
        height: 1.15,
        decoration: TextDecoration.none,
      );

  TextStyle chipStyle(Color color) => TextStyle(
        color: color,
        fontSize: chipFontSize == 11 ? 13 : 14,
        fontWeight: FontWeight.w400,
        height: 1.0,
        decoration: TextDecoration.none,
      );

  TextStyle actionStyle(Color color) => TextStyle(
        color: color,
        fontSize: actionFontSize,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      );
}

/// Quiet brand mark for the idle suggestion strip — almost a watermark.
class _TactBrandMark extends StatelessWidget {
  const _TactBrandMark({required this.surface});

  final KeyboardSurfaceTheme surface;

  @override
  Widget build(BuildContext context) {
    final alpha = surface.isLight ? 0.35 : 0.24;
    return Center(
      child: Text(
        'Tact',
        key: const Key('tact_brand_mark'),
        style: TextStyle(
          color: surface.keyTextMuted.withValues(alpha: alpha),
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 2.0,
          height: 1.0,
          decoration: TextDecoration.none,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SuggestionBar extends StatelessWidget {
  const SuggestionBar({
    super.key,
    required this.panel,
    required this.surface,
    required this.onAction,
  });

  final PanelState panel;
  final KeyboardSurfaceTheme surface;
  final Future<void> Function(PanelAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('suggestion_bar_root'),
      color: surface.background,
      child: panel is PanelIdle
          ? _TactBrandMark(surface: surface)
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
                    surface: surface,
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
    required this.surface,
  });

  final PanelState panel;
  final Future<void> Function(PanelAction action) onAction;
  final _PanelMetrics metrics;
  final KeyboardSurfaceTheme surface;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        surface.divider.withValues(alpha: surface.isLight ? 1 : 0.55);
    final brand = surface.accent;

    return switch (panel) {
      PanelIdle() => const SizedBox.shrink(),
      PanelUndo(:final label) => _StatusBar(
          surface: surface,
          accent: _PanelAlertColors.undo,
          brandAccent: brand,
          icon: Icons.check_circle_outline,
          title: label,
          actionLabel: 'Отменить',
          metrics: metrics,
          onAction: () => onAction(const PanelActionUndo()),
        ),
      PanelMat p => _StatusBar(
          surface: surface,
          accent: _PanelAlertColors.mat,
          brandAccent: brand,
          icon: Icons.block,
          title: 'Мат',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Убрать',
          metrics: metrics,
          onAction: () => onAction(PanelActionRemoveMat(panel: p)),
        ),
      PanelToxic p => _StatusBar(
          surface: surface,
          accent: _PanelAlertColors.toxic,
          brandAccent: brand,
          icon: Icons.warning_amber_rounded,
          title: p.level == ToxicLevel.conflict ? 'Конфликт' : 'Токсично',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Смягчить',
          metrics: metrics,
          onAction: () => onAction(PanelActionSoftenToxic(panel: p)),
        ),
      PanelImprove() => _StatusBar(
          surface: surface,
          accent: brand,
          brandAccent: brand,
          icon: Icons.auto_awesome,
          title: 'Можно улучшить',
          actionLabel: 'Улучшить',
          metrics: metrics,
          onAction: () => onAction(const PanelActionImprove()),
        ),
      PanelAiAssist() => _AiAssistBar(
          metrics: metrics,
          surface: surface,
          brandAccent: brand,
          onOrthography: () => onAction(
            const PanelActionAiAssist(chip: AiAssistChip.orthography),
          ),
          onPunctuation: () => onAction(
            const PanelActionAiAssist(chip: AiAssistChip.punctuation),
          ),
          onImprove: () => onAction(
            const PanelActionAiAssist(chip: AiAssistChip.improve),
          ),
        ),
      PanelShortcut(:final trigger, :final expansions) => _EqualChipRow(
          metrics: metrics,
          surface: surface,
          dividerColor: dividerColor,
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
          surface: surface,
          dividerColor: dividerColor,
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
    required this.surface,
    required this.accent,
    required this.brandAccent,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.metrics,
    required this.onAction,
  });

  final KeyboardSurfaceTheme surface;
  final Color accent;
  final Color brandAccent;
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
                surface: surface,
              ),
            ),
            if (onAction != null) ...[
              SizedBox(width: m.gap + 6),
              _PanelActionButton(
                label: actionLabel,
                metrics: m,
                brandAccent: brandAccent,
                textColor: surface.keyText,
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
    required this.surface,
  });

  final String title;
  final String? subtitle;
  final bool inline;
  final _PanelMetrics metrics;
  final KeyboardSurfaceTheme surface;

  @override
  Widget build(BuildContext context) {
    final titleStyle = metrics.titleStyle(surface.keyText);
    final subtitleStyle = metrics.subtitleStyle(surface.keyTextMuted);

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
    required this.brandAccent,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final _PanelMetrics metrics;
  final Color brandAccent;
  final Color textColor;
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
              color: brandAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(metrics.radius * 0.7),
              border: Border.all(
                color: brandAccent.withValues(alpha: 0.45),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.actionPadH,
                vertical: metrics.actionPadV,
              ),
              child: _PanelText(
                label,
                style: metrics.actionStyle(textColor),
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

/// AI actions — clearly not dictionary suggestions: badge + accent pills.
class _AiAssistBar extends StatelessWidget {
  const _AiAssistBar({
    required this.metrics,
    required this.surface,
    required this.brandAccent,
    required this.onOrthography,
    required this.onPunctuation,
    required this.onImprove,
  });

  final _PanelMetrics metrics;
  final KeyboardSurfaceTheme surface;
  final Color brandAccent;
  final VoidCallback onOrthography;
  final VoidCallback onPunctuation;
  final VoidCallback onImprove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: brandAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(metrics.radius * 0.7),
            border: Border.all(
              color: brandAccent.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: metrics.iconSize * 0.85,
                color: brandAccent,
              ),
              const SizedBox(width: 4),
              Text(
                'ИИ',
                style: TextStyle(
                  color: brandAccent,
                  fontSize: metrics.actionFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: metrics.gap),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AiActionPill(
                  label: PanelAiAssist.chipLabels[0],
                  metrics: metrics,
                  surface: surface,
                  brandAccent: brandAccent,
                  onTap: onOrthography,
                ),
                SizedBox(width: metrics.gap),
                _AiActionPill(
                  label: PanelAiAssist.chipLabels[1],
                  metrics: metrics,
                  surface: surface,
                  brandAccent: brandAccent,
                  onTap: onPunctuation,
                ),
                SizedBox(width: metrics.gap),
                _AiActionPill(
                  label: PanelAiAssist.chipLabels[2],
                  metrics: metrics,
                  surface: surface,
                  brandAccent: brandAccent,
                  onTap: onImprove,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AiActionPill extends StatelessWidget {
  const _AiActionPill({
    required this.label,
    required this.metrics,
    required this.surface,
    required this.brandAccent,
    required this.onTap,
  });

  final String label;
  final _PanelMetrics metrics;
  final KeyboardSurfaceTheme surface;
  final Color brandAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'ИИ: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(metrics.radius * 0.7),
          child: Ink(
            decoration: BoxDecoration(
              color: surface.chipBg,
              borderRadius: BorderRadius.circular(metrics.radius * 0.7),
              border: Border.all(
                color: brandAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.actionPadH,
                vertical: metrics.actionPadV,
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: surface.keyText,
                  fontSize: metrics.chipFontSize.clamp(11, 13).toDouble(),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gboard-style: equal columns, hairline ticks, full-bleed strip.
class _EqualChipRow extends StatelessWidget {
  const _EqualChipRow({
    required this.chips,
    required this.metrics,
    required this.surface,
    required this.dividerColor,
  });

  final List<_ChipData> chips;
  final _PanelMetrics metrics;
  final KeyboardSurfaceTheme surface;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0)
            _SuggestionDivider(
              inset: metrics.dividerInset + 2,
              color: dividerColor,
            ),
          Expanded(
            child: _EqualSuggestionSlot(
              chip: chips[i],
              metrics: metrics,
              textColor: surface.keyTextMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Short vertical tick — inset so it doesn't span the full bar height.
class _SuggestionDivider extends StatelessWidget {
  const _SuggestionDivider({required this.inset, required this.color});

  final double inset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: inset,
      endIndent: inset,
      color: color,
    );
  }
}

class _EqualSuggestionSlot extends StatelessWidget {
  const _EqualSuggestionSlot({
    required this.chip,
    required this.metrics,
    required this.textColor,
  });

  final _ChipData chip;
  final _PanelMetrics metrics;
  final Color textColor;

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
                style: metrics.chipStyle(textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
