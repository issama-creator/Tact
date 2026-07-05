import 'package:flutter/material.dart';

import '../platform/ime_platform.dart';
import '../theme/tact_theme.dart';
import 'tact_widgets.dart';

/// Shows which keyboard is active and helps switch TACT ↔ Gboard.
class ImeStatusCard extends StatefulWidget {
  const ImeStatusCard({super.key});

  @override
  State<ImeStatusCard> createState() => _ImeStatusCardState();
}

class _ImeStatusCardState extends State<ImeStatusCard>
    with WidgetsBindingObserver {
  Future<ImeStatus>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ImePlatform.addReconcileListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    ImePlatform.removeReconcileListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _future = ImePlatform.getImeStatus();
    });
  }

  Future<void> _activateTact() async {
    await ImePlatform.activateTact();
    _refresh();
  }

  Future<void> _activateGboard() async {
    await ImePlatform.activateGboard();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImeStatus>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return const TactCard(
            child: Text(
              'Не удалось прочитать статус клавиатур',
              style: TextStyle(fontSize: 12, color: TactColors.textSecondary),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const TactCard(
            child: SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        final status = snap.data ?? ImeStatus.empty();
        final tactEnabled = status.tact?.enabled ?? status.tactEnabled;
        final gboardInstalled =
            status.gboardInstalled || status.gboard != null;
        final gboardEnabled =
            status.gboard?.enabled ?? status.gboardEnabled;
        final allOff = status.allSoftKeyboardsDisabled ||
            (gboardInstalled && !gboardEnabled && !tactEnabled);

        final tactWrong = tactEnabled && !status.isTactActive;
        final gboardWrong =
            !tactEnabled && gboardEnabled && !status.isGboardActive;

        return TactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Активная клавиатура',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TactColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: TactColors.textMuted,
                    onPressed: _refresh,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                status.activeKeyboardLabel,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: status.isTactActive
                      ? TactColors.purple
                      : status.isGboardActive
                          ? TactColors.green
                          : TactColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _statusRow('TACT', tactEnabled, status.isTactActive),
              const SizedBox(height: 6),
              _statusRow(
                'Gboard',
                gboardEnabled,
                status.isGboardActive,
                missing: !gboardInstalled,
              ),
              if (tactWrong) ...[
                const SizedBox(height: 10),
                _warning(
                  'TACT включён, но сейчас показывается другая клавиатура.',
                  TactColors.orange,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _activateTact,
                    style: FilledButton.styleFrom(
                      backgroundColor: TactColors.purple,
                    ),
                    child: const Text('Сделать TACT активной'),
                  ),
                ),
              ] else if (gboardWrong) ...[
                const SizedBox(height: 10),
                _warning(
                  'TACT выключен — нужно активировать Gboard.',
                  TactColors.orange,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _activateGboard,
                    style: FilledButton.styleFrom(
                      backgroundColor: TactColors.green,
                    ),
                    child: const Text('Сделать Gboard активной'),
                  ),
                ),
              ] else if (allOff) ...[
                const SizedBox(height: 10),
                _warning(
                  'Все клавиатуры выключены. Включите Gboard или TACT '
                  'в системных настройках.',
                  TactColors.red,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: ImePlatform.openImeSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: TactColors.purple,
                    ),
                    child: const Text('Управление клавиатурами'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Gboard и TACT могут работать вместе — обе клавиатуры '
                'остаются включёнными. Смена: кнопки ниже или удержание 🌐.',
                style: TextStyle(
                  fontSize: 10,
                  color: TactColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _warning(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: TactColors.textSecondary,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _statusRow(
    String name,
    bool enabled,
    bool isActive, {
    bool missing = false,
  }) {
    final Color dot;
    final String text;
    if (missing) {
      dot = TactColors.textMuted;
      text = 'не установлен';
    } else if (!enabled) {
      dot = TactColors.red;
      text = 'выключен в системе';
    } else if (isActive) {
      dot = TactColors.green;
      text = 'показывается сейчас';
    } else {
      dot = TactColors.orange;
      text = 'включён, но не активен';
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: TactColors.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: TactColors.textSecondary),
        ),
      ],
    );
  }
}
