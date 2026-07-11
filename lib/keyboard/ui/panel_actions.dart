/// Sealed action intents from the suggestion bar.
library;

import '../panel/panel_state.dart';

sealed class PanelAction {
  const PanelAction();
}

final class PanelActionUndo extends PanelAction {
  const PanelActionUndo();
}

final class PanelActionRemoveMat extends PanelAction {
  const PanelActionRemoveMat({required this.panel});
  final PanelMat panel;
}

final class PanelActionSoftenToxic extends PanelAction {
  const PanelActionSoftenToxic({required this.panel});
  final PanelToxic panel;
}

final class PanelActionImprove extends PanelAction {
  const PanelActionImprove();
}

final class PanelActionShortcut extends PanelAction {
  const PanelActionShortcut({required this.expansion});
  final String expansion;
}

final class PanelActionSuggestion extends PanelAction {
  const PanelActionSuggestion({required this.word});
  final String word;
}
