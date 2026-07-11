/// Whether a panel's anchored word still exists in the text field.
library;

import '../../core/bridge/ime_bridge_facade.dart';
import 'panel_state.dart';

/// Word tied to the current analysis panel, if any.
String? anchoredWord(PanelState panel) => switch (panel) {
      PanelMat(:final word) => word,
      PanelSpell(:final word) => word,
      PanelToxic(:final word) => word,
      PanelShortcut(:final trigger) => trigger,
      _ => null,
    };

/// Panels that should hide when the user erases the anchored token.
bool panelTracksAnchoredWord(PanelState panel) => anchoredWord(panel) != null;

/// Returns true when [word] appears as a whole token in surrounding text.
bool isAnchoredWordPresent(SurroundingSnapshot snap, String word) {
  if (word.isEmpty) return false;
  // Prefer scanning halves separately to avoid '${before}${after}' alloc when
  // the token cannot span the cursor (typical for panel anchors).
  if (_containsWordToken(snap.before, word) ||
      _containsWordToken(snap.after, word)) {
    return true;
  }
  // Cursor mid-token edge case.
  if (snap.before.isEmpty || snap.after.isEmpty) return false;
  final full = '${snap.before}${snap.after}';
  return _containsWordToken(full, word);
}

bool _containsWordToken(String text, String word) {
  if (text.isEmpty) return false;
  final needle = _maybeLower(word);
  var from = 0;
  while (from <= text.length - needle.length) {
    final idx = _indexOfIgnoreCase(text, needle, from);
    if (idx < 0) return false;
    final beforeOk = idx == 0 || _isTokenBoundaryCu(text.codeUnitAt(idx - 1));
    final afterIdx = idx + needle.length;
    final afterOk = afterIdx >= text.length ||
        _isTokenBoundaryCu(text.codeUnitAt(afterIdx));
    if (beforeOk && afterOk) return true;
    from = idx + 1;
  }
  return false;
}

/// Returns [s] unchanged when already lower; otherwise a lowered copy.
String _maybeLower(String s) {
  for (var i = 0; i < s.length; i++) {
    final cu = s.codeUnitAt(i);
    if (cu >= 0x41 && cu <= 0x5A) return s.toLowerCase();
    if (cu >= 0x0410 && cu <= 0x042F) return s.toLowerCase();
    if (cu == 0x0401) return s.toLowerCase();
  }
  return s;
}

int _indexOfIgnoreCase(String haystack, String needleLower, int from) {
  final nLen = needleLower.length;
  if (nLen == 0 || from > haystack.length - nLen) return -1;
  outer:
  for (var i = from; i <= haystack.length - nLen; i++) {
    for (var j = 0; j < nLen; j++) {
      if (_lowerCu(haystack.codeUnitAt(i + j)) !=
          needleLower.codeUnitAt(j)) {
        continue outer;
      }
    }
    return i;
  }
  return -1;
}

int _lowerCu(int cu) {
  if (cu >= 0x41 && cu <= 0x5A) return cu + 32;
  if (cu >= 0x0410 && cu <= 0x042F) return cu + 32;
  if (cu == 0x0401) return 0x0451;
  return cu;
}

bool _isTokenBoundaryCu(int code) {
  switch (code) {
    case 0x20: // space
    case 0x09: // \t
    case 0x0A: // \n
    case 0x0D: // \r
    case 0x2E: // .
    case 0x2C: // ,
    case 0x21: // !
    case 0x3F: // ?
    case 0x3B: // ;
    case 0x3A: // :
    case 0x2D: // -
    case 0x2014: // —
    case 0x28: // (
    case 0x29: // )
    case 0x5B: // [
    case 0x5D: // ]
    case 0x22: // "
    case 0x00AB: // «
    case 0x00BB: // »
    case 0x2026: // …
      return true;
    default:
      return false;
  }
}
