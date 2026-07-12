/// Improve-text signal when the message is long enough.
library;

import '../input/text_context.dart';
import '../rules/rule_signal.dart';
import 'signal_provider.dart';

final class ImproveEngine implements SignalProvider {
  ImproveEngine({this.minChars = 30});

  final int minChars;

  @override
  List<RuleSignal> analyze(TextContext ctx) {
    if (ctx.messageLength < minChars) return const [];
    return [
      RuleSignal(
        kind: SignalKind.improve,
        severity: 40,
        confidence: 0.6,
        range: ctx.range,
      ),
    ];
  }
}
