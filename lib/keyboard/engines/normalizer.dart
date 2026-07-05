/// Fast text normalizer for lexicon and spell lookups.
library;

/// Configuration for [Normalizer].
final class NormalizerConfig {
  const NormalizerConfig({
    this.foldYo = true,
    this.collapseRepeatedLetters = true,
    this.maxRepeatedLetters = 3,
    this.stripPunctuation = true,
  });

  /// Map Cyrillic `ё` → `е` when true.
  final bool foldYo;
  final bool collapseRepeatedLetters;
  final int maxRepeatedLetters;
  final bool stripPunctuation;
}

/// Shared normalizer used across engines.
final class Normalizer {
  Normalizer([NormalizerConfig config = const NormalizerConfig()])
      : _config = config;

  final NormalizerConfig _config;
  final StringBuffer _out = StringBuffer();

  /// General normalization: lowercase, trim, strip invisibles, collapse repeats.
  String normalize(String input) => _run(input, foldLeet: false);

  /// Lexicon path — includes leetspeak folding and punctuation stripping.
  String normalizeForLexicon(String input) => _run(input, foldLeet: true);

  String _run(String input, {required bool foldLeet}) {
    var start = 0;
    var end = input.length;
    while (start < end && _isSpace(input.codeUnitAt(start))) start++;
    while (end > start && _isSpace(input.codeUnitAt(end - 1))) end--;
    if (start >= end) return '';

    _out.clear();
    var prev = 0;
    var run = 0;

    for (var i = start; i < end; i++) {
      final cu = input.codeUnitAt(i);
      if (_isInvisible(cu)) continue;

      var ch = _lower(cu);
      if (_config.foldYo && ch == 0x0451) ch = 0x0435; // ё → е

      if (_config.stripPunctuation && _isPunctuation(ch)) continue;

      if (foldLeet) {
        final mapped = _leetMap(ch);
        if (mapped == 0) continue;
        ch = mapped;
      }

      if (_config.collapseRepeatedLetters && ch == prev) {
        run++;
        if (run > _config.maxRepeatedLetters) continue;
      } else {
        prev = ch;
        run = 1;
      }

      _out.writeCharCode(ch);
    }

    return _out.toString();
  }

  static int _lower(int cu) {
    if (cu >= 0x41 && cu <= 0x5A) return cu + 32;
    if (cu >= 0xC0 && cu <= 0xDE && cu != 0xD7) return cu + 32;
    if (cu >= 0x0410 && cu <= 0x042F) return cu + 32;
    return cu;
  }

  static bool _isSpace(int cu) =>
      cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D;

  static bool _isInvisible(int cu) =>
      cu == 0x200B ||
      cu == 0x200C ||
      cu == 0x200D ||
      cu == 0xFEFF ||
      cu == 0x00AD;

  static bool _isPunctuation(int cu) {
    if ((cu >= 0x21 && cu <= 0x2F) ||
        (cu >= 0x3A && cu <= 0x40) ||
        (cu >= 0x5B && cu <= 0x60) ||
        (cu >= 0x7B && cu <= 0x7E)) {
      return true;
    }
    return cu == 0x2026;
  }

  static int _leetMap(int cu) {
    switch (cu) {
      case 0x30:
        return 0x6F;
      case 0x31:
        return 0x69;
      case 0x33:
        return 0x65;
      case 0x34:
        return 0x61;
      case 0x35:
        return 0x73;
      case 0x37:
        return 0x74;
      case 0x40:
        return 0x61;
      case 0x24:
        return 0x73;
      case 0x2A:
        return 0;
      default:
        return cu;
    }
  }
}
