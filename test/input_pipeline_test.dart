// test/input_pipeline_test.dart
//
// InputPipeline behavior:
//   • Words shorter than 3 chars are dropped before any engine is called.
//   • A subsequent keystroke cancels the currently-pending signal batch
//     (latest-only). Stale results never reach the state machine.
//   • Engines are called with an immutable TextContext.
//
// Uses fake engines + a fake bridge.
//
// TODO: implement.
library;
