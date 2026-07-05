/// Contract implemented by every analysis engine.
library;

import '../input/text_context.dart';
import '../rules/rule_signal.dart';

abstract interface class SignalProvider {
  List<RuleSignal> analyze(TextContext ctx);
}
