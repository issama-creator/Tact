import 'package:flutter/material.dart';

import '../platform/ime_platform.dart';
import '../theme/tact_theme.dart';

/// In-app keyboard chooser — avoids the system IME picker when possible.
Future<void> showKeyboardPickerSheet(
  BuildContext context, {
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: TactColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _KeyboardPickerSheet(onChanged: onChanged),
  );
}

class _KeyboardPickerSheet extends StatefulWidget {
  const _KeyboardPickerSheet({this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<_KeyboardPickerSheet> createState() => _KeyboardPickerSheetState();
}

class _KeyboardPickerSheetState extends State<_KeyboardPickerSheet> {
  ImeStatus? _status;
  bool _busy = false;
  String? _hint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await ImePlatform.getImeStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  Future<void> _pickTact() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _hint = null;
    });
    try {
      final status = _status ?? await ImePlatform.getImeStatus();
      if (!status.tactEnabled) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await ImePlatform.openImeSettings();
        return;
      }
      final result = await ImePlatform.activateTact(showPicker: false);
      await _finish(result, wanted: 'TACT');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickGboard() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _hint = null;
    });
    try {
      final status = _status ?? await ImePlatform.getImeStatus();
      if (!status.gboardInstalled) {
        setState(() => _hint = 'Gboard не установлен');
        return;
      }
      if (!status.gboardEnabled) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await ImePlatform.openImeSettings();
        return;
      }
      final result = await ImePlatform.activateGboard(showPicker: false);
      await _finish(result, wanted: 'Gboard');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(ImeActivateResult result, {required String wanted}) async {
    widget.onChanged?.call();
    await _load();
    if (!mounted) return;

    switch (result) {
      case ImeActivateResult.alreadyActive:
      case ImeActivateResult.selected:
        Navigator.of(context).pop();
      case ImeActivateResult.tactDisabled:
      case ImeActivateResult.gboardDisabled:
      case ImeActivateResult.noneEnabled:
        setState(() {
          _hint = 'Сначала разрешите $wanted в настройках Android';
        });
      case ImeActivateResult.pickerShown:
      case ImeActivateResult.unknown:
        setState(() {
          _hint =
              'Android не дал сменить клавиатуру напрямую. '
              'Нажмите «Все клавиатуры» ниже.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final tactOn = status?.isTactActive ?? false;
    final gboardOn = status?.isGboardActive ?? false;
    final tactEnabled = status?.tactEnabled ?? false;
    final gboardEnabled = status?.gboardEnabled ?? false;
    final gboardInstalled = status?.gboardInstalled ?? true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: TactColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Клавиатура',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TactColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Выберите, чем печатать',
              style: TextStyle(fontSize: 13, color: TactColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              title: 'TACT',
              subtitle: !tactEnabled
                  ? 'Нужно разрешить в системе'
                  : tactOn
                      ? 'Сейчас активна'
                      : 'Включена в системе',
              selected: tactOn,
              enabled: !_busy,
              accent: TactColors.purple,
              onTap: _pickTact,
            ),
            const SizedBox(height: 8),
            _OptionTile(
              title: 'Gboard',
              subtitle: !gboardInstalled
                  ? 'Не установлена'
                  : !gboardEnabled
                      ? 'Нужно разрешить в системе'
                      : gboardOn
                          ? 'Сейчас активна'
                          : 'Включена в системе',
              selected: gboardOn,
              enabled: !_busy && gboardInstalled,
              accent: TactColors.green,
              onTap: _pickGboard,
            ),
            if (_hint != null) ...[
              const SizedBox(height: 12),
              Text(
                _hint!,
                style: const TextStyle(
                  fontSize: 12,
                  color: TactColors.orange,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        Navigator.of(context).pop();
                        await ImePlatform.showInputMethodPicker();
                      },
                child: const Text(
                  'Все клавиатуры…',
                  style: TextStyle(color: TactColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.14)
          : TactColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.5) : TactColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? TactColors.textPrimary
                            : TactColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TactColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 22)
              else
                Icon(
                  Icons.circle_outlined,
                  color: enabled ? TactColors.textMuted : TactColors.surfaceBorder,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
