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
  final full = '${snap.before}${snap.after}';
  return _containsWordToken(full, word);
}

bool _containsWordToken(String text, String word) {
  if (text.isEmpty) return false;
  final lower = text.toLowerCase();
  final needle = word.toLowerCase();
  var from = 0;
  while (from <= lower.length - needle.length) {
    final idx = lower.indexOf(needle, from);
    if (idx < 0) return false;
    final beforeOk = idx == 0 || _isTokenBoundary(text[idx - 1]);
    final afterIdx = idx + needle.length;
    final afterOk =
        afterIdx >= text.length || _isTokenBoundary(text[afterIdx]);
    if (beforeOk && afterOk) return true;
    from = idx + 1;
  }
  return false;
}

bool _isTokenBoundary(String char) {
  if (char.isEmpty) return true;
  final code = char.codeUnitAt(0);
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
