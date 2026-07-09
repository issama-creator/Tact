/// QWERTY / ЙЦУКЕН keyboard neighbor map for spell candidate generation.
library;

abstract final class KeyboardProximity {
  static const _en = <String, String>{
    'q': 'wa', 'w': 'qase', 'e': 'wsdr', 'r': 'edft', 't': 'rfgy',
    'y': 'tghu', 'u': 'yhji', 'i': 'ujko', 'o': 'iklp', 'p': 'ol',
    'a': 'qwsz', 's': 'awedxz', 'd': 'serfcx', 'f': 'drtgvc', 'g': 'ftyhbv',
    'h': 'gyujnb', 'j': 'huikmn', 'k': 'jiolm', 'l': 'kop',
    'z': 'asx', 'x': 'zsdc', 'c': 'xdfv', 'v': 'cfgb', 'b': 'vghn',
    'n': 'bhjm', 'm': 'njk',
  };

  static const _ru = <String, String>{
    'й': 'ц', 'ц': 'йуы', 'у': 'цкв', 'к': 'уеа', 'е': 'кнп',
    'н': 'егш', 'г': 'ншо', 'ш': 'гщз', 'щ': 'шзх', 'з': 'щхъ',
    'х': 'зъ', 'ъ': 'хэ',
    'ф': 'ыва', 'ы': 'фвп', 'в': 'ыап', 'а': 'впр', 'п': 'аро',
    'р': 'пол', 'о': 'рлд', 'л': 'одж', 'д': 'лжэ', 'ж': 'дэ',
    'э': 'жю', 'ю': 'эб', 'я': 'чс', 'ч': 'ясм', 'с': 'чми',
    'м': 'сит', 'и': 'мть', 'т': 'иьб', 'ь': 'тб', 'б': 'ью',
  };

  /// Neighbor chars for substitution edits; [ch] null → common alphabet.
  static Iterable<String> neighbors(String? ch, {required String locale}) sync* {
    if (ch != null && ch.isNotEmpty) {
      final lower = ch.toLowerCase();
      final map = locale.startsWith('ru') ? _ru : _en;
      final n = map[lower];
      if (n != null) {
        yield lower;
        for (final c in n.split('')) {
          yield c;
        }
        return;
      }
      final code = lower.codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7A) {
        if (code > 0x61) yield String.fromCharCode(code - 1);
        if (code < 0x7A) yield String.fromCharCode(code + 1);
        yield lower;
        return;
      }
      if (code >= 0x0430 && code <= 0x044F) {
        if (code > 0x0430) yield String.fromCharCode(code - 1);
        if (code < 0x044F) yield String.fromCharCode(code + 1);
        yield lower;
        return;
      }
    }
    final alphabet = locale.startsWith('ru') ? _ruAlphabet : _enAlphabet;
    for (final c in alphabet.split('')) {
      yield c;
    }
  }

  static const _enAlphabet = 'abcdefghijklmnopqrstuvwxyz';
  static const _ruAlphabet = 'абвгдежзийклмнопрстуфхцчшщъыьэюя';

  /// Bonus ranking when typo char is a keyboard neighbor of dictionary char.
  static int neighborBonus(String input, String candidate, String locale) {
    if (input.length != candidate.length) return 0;
    var bonus = 0;
    final map = locale.startsWith('ru') ? _ru : _en;
    for (var i = 0; i < input.length; i++) {
      if (input[i] == candidate[i]) continue;
      final neighbors = map[input[i]];
      if (neighbors != null && neighbors.contains(candidate[i])) {
        bonus += 3;
      }
    }
    return bonus;
  }
}
