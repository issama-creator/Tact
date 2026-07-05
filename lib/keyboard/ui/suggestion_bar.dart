// lib/keyboard/ui/suggestion_bar.dart
//
// SuggestionBar — the (currently empty) container above the keys.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SuggestionBar extends StatefulWidget {
  const SuggestionBar({super.key});

  @override
  State<SuggestionBar> createState() => _SuggestionBarState();
}

class _SuggestionBarState extends State<SuggestionBar> {
  static const MethodChannel _bridge =
      MethodChannel('com.example.tact.ime/bridge');

  Color _backgroundColor = const Color(0xFF171719);

  @override
  void initState() {
    super.initState();
    _bridge.setMethodCallHandler(_onCall);
    // Wait until the first frame — native bridge may not be ready during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _signalReady());
  }

  @override
  void dispose() {
    _bridge.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _signalReady() async {
    try {
      await _bridge.invokeMethod('ready');
    } catch (_) {
      // Bridge not wired yet — theme falls back to the default color.
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'setTheme':
        _applyTheme(call.arguments);
        return null;
      case 'onStartInputView':
      case 'onFinishInputView':
      case 'onSelectionChanged':
      case 'onWordCommitted':
        return null;
      default:
        return null;
    }
  }

  void _applyTheme(Object? arguments) {
    if (arguments is! String) return;
    Object? decoded;
    try {
      decoded = jsonDecode(arguments);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    final Object? bg = decoded['background'];
    final int? argb = switch (bg) {
      final int v => v,
      final double v => v.toInt(),
      _ => null,
    };
    if (argb == null || !mounted) return;
    setState(() {
      _backgroundColor = Color(argb & 0xFFFFFFFF);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundColor,
      child: const SizedBox.expand(),
    );
  }
}
