/// Fast guards for spell / lexicon engines — no regex on the hot path.
library;

abstract final class TextSkip {
  static bool shouldSkip(String word) {
    if (word.isEmpty) return true;
    if (_isNumeric(word)) return true;
    if (_looksLikeUrl(word)) return true;
    if (_looksLikeEmail(word)) return true;
    if (_hasEmoji(word)) return true;
    return false;
  }

  static bool _isNumeric(String word) {
    for (var i = 0; i < word.length; i++) {
      final cu = word.codeUnitAt(i);
      final isDigit = cu >= 0x30 && cu <= 0x39;
      final isSep = cu == 0x2E || cu == 0x2C || cu == 0x2D || cu == 0x2B;
      if (!isDigit && !isSep) return false;
    }
    return true;
  }

  static bool _looksLikeUrl(String word) {
    final lower = _asciiLower(word);
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');
  }

  static bool _looksLikeEmail(String word) {
    var at = 0;
    var dotAfter = false;
    for (var i = 0; i < word.length; i++) {
      final cu = word.codeUnitAt(i);
      if (cu == 0x40) {
        at++;
        continue;
      }
      if (at > 0 && cu == 0x2E) dotAfter = true;
    }
    return at == 1 && dotAfter;
  }

  static bool _hasEmoji(String word) {
    for (final rune in word.runes) {
      if (rune >= 0x1F300) return true;
      if (rune >= 0x2600 && rune <= 0x27BF) return true;
    }
    return false;
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
