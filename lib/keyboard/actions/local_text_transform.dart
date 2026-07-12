/// Local AI-compatible text improvement — no network.
library;

/// Offline soften/tone adjustments until [AiService] is wired.
abstract final class LocalTextTransform {
  static String softenWord(String word) {
    final lower = _asciiLower(word);
    const map = {
      'идиот': 'не лучший вариант',
      'дурак': 'неудачное слово',
      'тупой': 'неудачное слово',
      'stupid': 'not ideal',
      'idiot': 'not ideal',
      'hate': 'dislike',
      'moron': 'not ideal',
      'kill': 'hurt',
      'die': 'leave',
    };
    return map[lower] ?? _mildPlaceholder(word);
  }

  static String improveMessage(String message) {
    if (message.isEmpty) return message;
    final trimmed = _collapseSpaces(message.trim());
    if (trimmed.isEmpty) return trimmed;
    return _capitalizeFirst(trimmed);
  }

  /// Light punctuation pass: spaces after .,!? and collapse doubles.
  static String fixPunctuation(String message) {
    if (message.isEmpty) return message;
    var s = _collapseSpaces(message.trim());
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      buf.write(ch);
      if ((ch == '.' || ch == '!' || ch == '?') && i + 1 < s.length) {
        final next = s.codeUnitAt(i + 1);
        final nextIsSpace = next == 0x20 || next == 0x0A || next == 0x09;
        final nextIsEnd = next == 0x2E || next == 0x21 || next == 0x3F;
        if (!nextIsSpace && !nextIsEnd) buf.write(' ');
      }
    }
    return _collapseSpaces(buf.toString());
  }

  /// Orthography stub offline: capitalize + collapse spaces.
  static String fixOrthography(String message) => improveMessage(message);

  static String matReplacement(String word) {
    if (word.isEmpty) return '***';
    final stars = '*' * word.runes.length.clamp(3, 8);
    return stars;
  }

  /// Panel subtitle: show start of word, mask last 1–2 letters.
  static String censorForDisplay(String word) {
    final runes = word.runes.toList();
    if (runes.isEmpty) return word;
    if (runes.length == 1) return '*';
    final maskCount = runes.length <= 2 ? 1 : 2;
    final visible = runes.length - maskCount;
    return '${String.fromCharCodes(runes.take(visible))}${'*' * maskCount}';
  }

  static String _mildPlaceholder(String word) {
    if (word.isEmpty) return word;
    return '...';
  }

  static String _collapseSpaces(String input) {
    final buf = StringBuffer();
    var prevSpace = false;
    for (var i = 0; i < input.length; i++) {
      final cu = input.codeUnitAt(i);
      final isSpace = cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D;
      if (isSpace) {
        if (!prevSpace) buf.write(' ');
        prevSpace = true;
      } else {
        buf.writeCharCode(cu);
        prevSpace = false;
      }
    }
    return buf.toString();
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    final first = s.runes.first;
    final rest = s.runes.skip(1);
    return String.fromCharCodes([_upper(first), ...rest]);
  }

  static int _upper(int rune) {
    if (rune >= 0x61 && rune <= 0x7A) return rune - 32;
    if (rune >= 0x0430 && rune <= 0x044F) return rune - 32;
    return rune;
  }

  static String _asciiLower(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final cu = s.codeUnitAt(i);
      if (cu >= 0x41 && cu <= 0x5A) {
        buf.writeCharCode(cu + 32);
      } else {
        buf.writeCharCode(cu);
      }
    }
    return buf.toString();
  }
}
