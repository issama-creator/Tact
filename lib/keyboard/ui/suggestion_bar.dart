/// Suggestion bar — matches TACT design: status strip + chips.
library;

import 'package:flutter/material.dart';

import '../actions/local_text_transform.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import 'panel_actions.dart';

/// Design tokens aligned with companion [PanelPreviewBar].
abstract final class _TactPanelColors {
  static const background = Color(0xFF1A1A22);
  static const chipBg = Color(0xFF2A2A2E);
  static const text = Color(0xFFE8E8EA);
  static const textMuted = Color(0xFF9A9AA3);
  static const action = Color(0xFF7C5CFF);
  static const spell = Color(0xFFE8913A);
  static const mat = Color(0xFFC94B4B);
  static const toxic = Color(0xFFE8B339);
  static const improve = Color(0xFF7C5CFF);
  static const undo = Color(0xFF3DDC97);
  static const border = Color(0xFF2E2E36);
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
          ? const SizedBox.expand()
          : SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                child: _PanelBody(panel: panel, onAction: onAction),
              ),
            ),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody({required this.panel, required this.onAction});

  final PanelState panel;
  final Future<void> Function(PanelAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return switch (panel) {
      PanelIdle() => const SizedBox.shrink(),
      PanelUndo(:final label) => _StatusBar(
          accent: _TactPanelColors.undo,
          icon: Icons.check_circle_outline,
          title: label,
          actionLabel: 'Отменить',
          onAction: () => onAction(const PanelActionUndo()),
        ),
      PanelSpell p => p.candidates.length <= 1
          ? _StatusBar(
              accent: _TactPanelColors.spell,
              icon: Icons.spellcheck,
              title: 'Найдены ошибки',
              subtitle: p.word,
              actionLabel: 'Исправить',
              onAction: p.candidates.isNotEmpty
                  ? () => onAction(PanelActionFixSpell(
                        panel: p,
                        candidate: p.candidates.first,
                      ))
                  : null,
            )
          : _SpellChipRow(
              word: p.word,
              candidates: p.candidates.take(3).toList(),
              onPick: (c) => onAction(PanelActionFixSpell(panel: p, candidate: c)),
            ),
      PanelMat p => _StatusBar(
          accent: _TactPanelColors.mat,
          icon: Icons.block,
          title: 'Обнаружен мат',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Убрать',
          onAction: () => onAction(PanelActionRemoveMat(panel: p)),
        ),
      PanelToxic p => _StatusBar(
          accent: _TactPanelColors.toxic,
          icon: Icons.warning_amber_rounded,
          title: p.level == ToxicLevel.conflict
              ? 'Возможен конфликт'
              : 'Резкий тон',
          subtitle: LocalTextTransform.censorForDisplay(p.word),
          actionLabel: 'Смягчить',
          onAction: () => onAction(PanelActionSoftenToxic(panel: p)),
        ),
      PanelImprove() => _StatusBar(
          accent: _TactPanelColors.improve,
          icon: Icons.auto_awesome,
          title: 'Можно улучшить текст',
          actionLabel: 'Улучшить',
          onAction: () => onAction(const PanelActionImprove()),
        ),
      PanelShortcut(:final trigger, :final expansions) => _ChipRow(
          chips: expansions
              .take(3)
              .map(
                (e) => _ChipData(
                  '$trigger → $e',
                  onTap: () => onAction(PanelActionShortcut(expansion: e)),
                ),
              )
              .toList(),
        ),
      PanelSuggestions(:final words) => _ChipRow(
          chips: words
              .take(4)
              .map(
                (w) => _ChipData(
                  w,
                  onTap: () => onAction(PanelActionSuggestion(word: w)),
                ),
              )
              .toList(),
        ),
    };
  }
}

/// Single-row spell panel: label + candidate chips (fits 52dp IME bar).
class _SpellChipRow extends StatelessWidget {
  const _SpellChipRow({
    required this.word,
    required this.candidates,
    required this.onPick,
  });

  final String word;
  final List<String> candidates;
  final void Function(String candidate) onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _TactPanelColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _TactPanelColors.spell.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _TactPanelColors.spell.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.spellcheck,
              color: _TactPanelColors.spell,
              size: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            word,
            style: const TextStyle(
              color: _TactPanelColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in candidates) ...[
                    _SuggestionChip(
                      chip: _ChipData(
                        c,
                        onTap: () => onPick(c),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
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
  const _ChipRow({required this.chips});

  final List<_ChipData> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _TactPanelColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _TactPanelColors.border),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final chip in chips) ...[
                _SuggestionChip(chip: chip),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.chip});

  final _ChipData chip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: chip.onTap != null,
      label: chip.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: chip.onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _TactPanelColors.chipBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                chip.label,
                style: const TextStyle(
                  color: _TactPanelColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
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
    required this.onAction,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _TactPanelColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: accent, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _TactPanelColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: _TactPanelColors.textMuted,
                      fontSize: 11,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onAction != null)
            Semantics(
              button: true,
              label: actionLabel,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: 44,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _TactPanelColors.action,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$actionLabel →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
