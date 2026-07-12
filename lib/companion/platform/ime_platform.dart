import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android hooks for IME setup and keyboard selection.
abstract final class ImePlatform {
  static const _channel = MethodChannel('com.example.tact/companion');

  static final List<VoidCallback> _reconcileListeners = <VoidCallback>[];
  static bool _handlerInstalled = false;

  static void ensureInitialized() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onKeyboardReconciled') {
        for (final listener in List<VoidCallback>.of(_reconcileListeners)) {
          listener();
        }
      }
      return null;
    });
  }

  static void addReconcileListener(VoidCallback listener) {
    ensureInitialized();
    if (!_reconcileListeners.contains(listener)) {
      _reconcileListeners.add(listener);
    }
  }

  static void removeReconcileListener(VoidCallback listener) {
    _reconcileListeners.remove(listener);
  }

  static Future<void> openImeSettings() =>
      _channel.invokeMethod<void>('openImeSettings');

  static Future<void> showInputMethodPicker() =>
      _channel.invokeMethod<void>('showInputMethodPicker');

  static Future<ImeActivateResult> activateTact({
    bool showPicker = false,
  }) async {
    final raw = await _channel.invokeMethod<String>(
      'activateTact',
      <String, dynamic>{'showPicker': showPicker},
    );
    return ImeActivateResult.from(raw);
  }

  static Future<ImeActivateResult> activateGboard({
    bool showPicker = false,
  }) async {
    final raw = await _channel.invokeMethod<String>(
      'activateGboard',
      <String, dynamic>{'showPicker': showPicker},
    );
    return ImeActivateResult.from(raw);
  }

  static Future<ImeActivateResult> reconcileKeyboard({
    bool showPicker = true,
  }) async {
    final raw = await _channel.invokeMethod<String>(
      'reconcileKeyboard',
      <String, dynamic>{'showPicker': showPicker},
    );
    return ImeActivateResult.from(raw);
  }

  static Future<ImeStatus> getImeStatus() async {
    final raw = await _channel.invokeMethod<String>('getImeStatus');
    if (raw == null || raw.isEmpty) return ImeStatus.empty();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['keyboards'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => ImeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return ImeStatus(
      defaultImeId: map['defaultImeId'] as String? ?? '',
      keyboards: list,
      gboardInstalled: map['gboardInstalled'] as bool? ?? false,
      gboardEnabled: map['gboardEnabled'] as bool? ?? false,
      tactEnabled: map['tactEnabled'] as bool? ?? false,
      tactIsDefault: map['tactIsDefault'] as bool? ?? false,
      gboardIsDefault: map['gboardIsDefault'] as bool? ?? false,
      activeKeyboard: map['activeKeyboard'] as String? ?? 'none',
      allSoftKeyboardsDisabled:
          map['allSoftKeyboardsDisabled'] as bool? ?? false,
    );
  }
}

enum ImeActivateResult {
  alreadyActive,
  selected,
  pickerShown,
  tactDisabled,
  gboardDisabled,
  noneEnabled,
  unknown;

  static ImeActivateResult from(String? raw) {
    return switch (raw) {
      'already_active' => ImeActivateResult.alreadyActive,
      'selected' => ImeActivateResult.selected,
      'picker_shown' => ImeActivateResult.pickerShown,
      'tact_disabled' => ImeActivateResult.tactDisabled,
      'gboard_disabled' => ImeActivateResult.gboardDisabled,
      'none_enabled' => ImeActivateResult.noneEnabled,
      _ => ImeActivateResult.unknown,
    };
  }
}

class ImeStatus {
  const ImeStatus({
    required this.defaultImeId,
    required this.keyboards,
    this.gboardInstalled = false,
    this.gboardEnabled = false,
    this.tactEnabled = false,
    this.tactIsDefault = false,
    this.gboardIsDefault = false,
    this.activeKeyboard = 'none',
    this.allSoftKeyboardsDisabled = false,
  });

  final String defaultImeId;
  final List<ImeEntry> keyboards;
  final bool gboardInstalled;
  final bool gboardEnabled;
  final bool tactEnabled;
  final bool tactIsDefault;
  final bool gboardIsDefault;
  final String activeKeyboard;
  final bool allSoftKeyboardsDisabled;

  ImeEntry? get tact => _find(isTact: true);
  ImeEntry? get gboard => _find(isGboard: true);

  String get activeKeyboardLabel => switch (activeKeyboard) {
    'TACT' => 'TACT',
    'Gboard' => 'Gboard',
    'other' => 'Другая клавиатура',
    _ => 'Нет активной клавиатуры',
  };

  bool get isTactActive => tactIsDefault || activeKeyboard == 'TACT';
  bool get isGboardActive => gboardIsDefault || activeKeyboard == 'Gboard';

  ImeEntry? _find({bool isTact = false, bool isGboard = false}) {
    for (final ImeEntry k in keyboards) {
      if (isTact && k.isTact) return k;
      if (isGboard && k.isGboard) return k;
    }
    return null;
  }

  static ImeStatus empty() => const ImeStatus(defaultImeId: '', keyboards: []);
}

class ImeEntry {
  const ImeEntry({
    required this.id,
    required this.label,
    required this.enabled,
    required this.isDefault,
    required this.isTact,
    required this.isGboard,
  });

  final String id;
  final String label;
  final bool enabled;
  final bool isDefault;
  final bool isTact;
  final bool isGboard;

  factory ImeEntry.fromJson(Map<String, dynamic> json) => ImeEntry(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? false,
    isDefault: json['isDefault'] as bool? ?? false,
    isTact: json['isTact'] as bool? ?? false,
    isGboard: json['isGboard'] as bool? ?? false,
  );
}
