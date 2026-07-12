import 'package:flutter/material.dart';

import '../platform/ime_platform.dart';
import '../theme/tact_theme.dart';
import 'keyboard_picker_sheet.dart';
import 'tact_widgets.dart';

/// One light card: open in-app keyboard chooser (no system picker by default).
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

  Future<void> _openPicker() async {
    final status = await ImePlatform.getImeStatus();
    if (!mounted) return;
    if (!status.tactEnabled) {
      await ImePlatform.openImeSettings();
      return;
    }
    await showKeyboardPickerSheet(context, onChanged: _refresh);
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
              'Не удалось прочитать статус клавиатуры',
              style: TextStyle(fontSize: 13, color: TactColors.textSecondary),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const TactCard(
            child: SizedBox(
              height: 56,
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
        final on = status.isTactActive;

        return TactCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Клавиатура',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TactColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !tactEnabled
                          ? TactColors.textMuted
                          : on
                              ? TactColors.green
                              : TactColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !tactEnabled
                          ? 'TACT не разрешена в системе'
                          : on
                              ? 'Сейчас: TACT'
                              : status.isGboardActive
                                  ? 'Сейчас: Gboard'
                                  : 'Сейчас: ${status.activeKeyboardLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TactColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!tactEnabled)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: ImePlatform.openImeSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: TactColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Разрешить в настройках'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _openPicker,
                    style: FilledButton.styleFrom(
                      backgroundColor: TactColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Выбрать клавиатуру'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
