/// Dart-side IME bridge — events and text mutations.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../keyboard/actions/text_replacement.dart';
import '../../keyboard/input/text_context.dart';

final class WordEvent {
  const WordEvent({
    required this.word,
    required this.locale,
    this.before = '',
    this.after = '',
    this.deleteBefore = 0,
    this.deleteAfter = 0,
    this.boundary = '',
  });

  final String word;
  final String locale;
  final String before;
  final String after;
  final int deleteBefore;
  final int deleteAfter;
  final String boundary;

  TextContext toContext() {
    final start = before.length;
    return TextContext(
      word: word,
      before: before,
      after: after,
      range: EditRange(start, start + word.length),
      locale: locale,
      fullMessage: '$before$word$after',
    );
  }

  ActionContext toActionContext() => ActionContext(
        word: word,
        locale: locale,
        deleteBefore: deleteBefore,
        deleteAfter: deleteAfter,
        boundary: boundary,
        before: before,
        after: after,
      );
}

final class ReplaceOutcome {
  const ReplaceOutcome({
    required this.selectionStart,
    required this.selectionEnd,
    required this.replacedText,
    required this.insertedLength,
    required this.previousSelectionStart,
    required this.previousSelectionEnd,
  });

  final int selectionStart;
  final int selectionEnd;
  final String replacedText;
  final int insertedLength;
  final int previousSelectionStart;
  final int previousSelectionEnd;
}

final class SurroundingSnapshot {
  const SurroundingSnapshot({
    required this.before,
    required this.after,
    required this.selectionStart,
    required this.selectionEnd,
    required this.isPassword,
  });

  final String before;
  final String after;
  final int selectionStart;
  final int selectionEnd;
  final bool isPassword;
}

/// Facade over the native MethodChannel for the IME suggestion bar.
class ImeBridge {
  ImeBridge({MethodChannel? channel, FakeTextField? fakeField})
      : _channel = channel ?? const MethodChannel('com.example.tact.ime/bridge'),
        _fake = fakeField;

  final MethodChannel _channel;
  final FakeTextField? _fake;
  final StreamController<WordEvent> _words = StreamController.broadcast();

  void Function(int argb)? onThemeArgb;
  void Function()? onInputViewStarted;
  void Function()? onFieldFinished;

  Stream<WordEvent> get onWordCommitted => _words.stream;

  bool get isFake => _fake != null;

  void emitWord(WordEvent event) {
    if (!_words.isClosed) _words.add(event);
  }

  void attachHandler() {
    if (_fake != null) return;
    _channel.setMethodCallHandler(_onCall);
  }

  void detachHandler() {
    if (_fake != null) return;
    _channel.setMethodCallHandler(null);
  }

  Future<void> signalReady() async {
    if (_fake != null) return;
    try {
      await _channel.invokeMethod<void>('ready');
    } catch (_) {}
  }

  Future<void> commitText(String text) async {
    if (_fake != null) {
      _fake!.insert(text);
      return;
    }
    await _channel.invokeMethod<void>('commitText', {'text': text});
  }

  Future<void> deleteSurrounding(int before, int after) async {
    if (_fake != null) {
      _fake!.deleteSurrounding(before, after);
      return;
    }
    await _channel.invokeMethod<void>('deleteSurrounding', {
      'before': before,
      'after': after,
    });
  }

  Future<ReplaceOutcome?> replaceSurrounding({
    required int deleteBefore,
    required int deleteAfter,
    required String replacement,
  }) async {
    if (_fake != null) {
      return _fake!.replaceSurrounding(
        deleteBefore: deleteBefore,
        deleteAfter: deleteAfter,
        replacement: replacement,
      );
    }
    final raw = await _channel.invokeMethod<Object?>('replaceSurrounding', {
      'deleteBefore': deleteBefore,
      'deleteAfter': deleteAfter,
      'replacement': replacement,
    });
    return _parseReplaceOutcome(raw);
  }

  Future<SurroundingSnapshot?> getSurroundingText({
    int before = 512,
    int after = 128,
  }) async {
    if (_fake != null) return _fake!.snapshot();
    final raw = await _channel.invokeMethod<Object?>('getSurroundingText', {
      'before': before,
      'after': after,
    });
    final map = _asMap(raw);
    if (map == null) return null;
    return SurroundingSnapshot(
      before: map['before'] as String? ?? '',
      after: map['after'] as String? ?? '',
      selectionStart: map['selectionStart'] as int? ?? 0,
      selectionEnd: map['selectionEnd'] as int? ?? 0,
      isPassword: map['isPassword'] as bool? ?? false,
    );
  }

  Future<void> setSelection(int start, int end) async {
    if (_fake != null) {
      _fake!.setSelection(start, end);
      return;
    }
    await _channel.invokeMethod<void>('setSelection', {
      'start': start,
      'end': end,
    });
  }

  Future<void> actionHaptic() async {
    if (_fake != null) return;
    try {
      await _channel.invokeMethod<void>('actionHaptic');
    } catch (_) {}
  }

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'onWordCommitted':
        _handleWord(call.arguments);
        return null;
      case 'setTheme':
        _handleTheme(call.arguments);
        return null;
      case 'onStartInputView':
        onInputViewStarted?.call();
        return null;
      case 'onFinishInputView':
        onFieldFinished?.call();
        return null;
      case 'onSelectionChanged':
        return null;
      default:
        return null;
    }
  }

  void _handleWord(Object? arguments) {
    final map = _asMap(arguments);
    if (map == null) return;
    final word = map['word'];
    final locale = map['locale'];
    if (word is! String || locale is! String) return;
    _words.add(
      WordEvent(
        word: word,
        locale: locale,
        before: map['before'] as String? ?? '',
        after: map['after'] as String? ?? '',
        deleteBefore: map['deleteBefore'] as int? ?? word.length,
        deleteAfter: map['deleteAfter'] as int? ?? 0,
        boundary: map['boundary'] as String? ?? '',
      ),
    );
  }

  void _handleTheme(Object? arguments) {
    final map = _asMap(arguments);
    if (map == null) return;
    final bg = map['background'];
    final int? argb = switch (bg) {
      final int v => v,
      final double v => v.toInt(),
      _ => null,
    };
    if (argb != null) onThemeArgb?.call(argb);
  }

  ReplaceOutcome? _parseReplaceOutcome(Object? raw) {
    final map = _asMap(raw);
    if (map == null) return null;
    return ReplaceOutcome(
      selectionStart: map['selectionStart'] as int? ?? -1,
      selectionEnd: map['selectionEnd'] as int? ?? -1,
      replacedText: map['replacedText'] as String? ?? '',
      insertedLength: map['insertedLength'] as int? ??
          (map['replacement'] as String? ?? '').length,
      previousSelectionStart: map['previousSelectionStart'] as int? ?? -1,
      previousSelectionEnd: map['previousSelectionEnd'] as int? ?? -1,
    );
  }

  Map<String, dynamic>? _asMap(Object? arguments) {
    if (arguments is Map) return Map<String, dynamic>.from(arguments);
    if (arguments is String) {
      try {
        final decoded = jsonDecode(arguments);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  void dispose() {
    detachHandler();
    _words.close();
  }
}

/// In-memory text field for unit tests.
final class FakeTextField {
  FakeTextField({
    this.text = '',
    this.isPassword = false,
    int? selectionStart,
    int? selectionEnd,
  }) {
    final end = selectionEnd ?? text.length;
    this.selectionStart = selectionStart ?? end;
    this.selectionEnd = selectionEnd ?? end;
  }

  String text;
  late int selectionStart;
  late int selectionEnd;
  bool isPassword;

  void insert(String value) {
    final s = selectionStart.clamp(0, text.length);
    final e = selectionEnd.clamp(0, text.length);
    text = text.substring(0, s) + value + text.substring(e);
    final pos = s + value.length;
    selectionStart = pos;
    selectionEnd = pos;
  }

  void deleteSurrounding(int before, int after) {
    final cursor = selectionEnd.clamp(0, text.length);
    final start = (cursor - before).clamp(0, text.length);
    final end = (cursor + after).clamp(0, text.length);
    text = text.substring(0, start) + text.substring(end);
    selectionStart = start;
    selectionEnd = start;
  }

  ReplaceOutcome? replaceSurrounding({
    required int deleteBefore,
    required int deleteAfter,
    required String replacement,
  }) {
    if (deleteBefore < 0 || deleteAfter < 0) return null;
    final prevStart = selectionStart;
    final prevEnd = selectionEnd;
    final cursor = selectionEnd.clamp(0, text.length);
    final start = (cursor - deleteBefore).clamp(0, text.length);
    final end = (cursor + deleteAfter).clamp(0, text.length);
    final replaced = text.substring(start, end);
    text = text.substring(0, start) + replacement + text.substring(end);
    final newCursor = start + replacement.length;
    selectionStart = newCursor;
    selectionEnd = newCursor;
    return ReplaceOutcome(
      selectionStart: newCursor,
      selectionEnd: newCursor,
      replacedText: replaced,
      insertedLength: replacement.length,
      previousSelectionStart: prevStart,
      previousSelectionEnd: prevEnd,
    );
  }

  void setSelection(int start, int end) {
    selectionStart = start.clamp(0, text.length);
    selectionEnd = end.clamp(0, text.length);
  }

  SurroundingSnapshot snapshot() => SurroundingSnapshot(
        before: text.substring(0, selectionStart.clamp(0, text.length)),
        after: text.substring(selectionEnd.clamp(0, text.length)),
        selectionStart: selectionStart,
        selectionEnd: selectionEnd,
        isPassword: isPassword,
      );
}
