// lib/core/result.dart
//
// Result<T, E> — a lightweight success/failure type.
//
// Purpose:
//   Engines, repositories and the AI service return Result instead of throwing.
//   Exceptions on the hot path are expensive and unpredictable — Result forces
//   the caller to handle the error case at the call site.
//
// Contents (planned):
//   • sealed class Result<T, E>
//       - Ok<T, E>(T value)
//       - Err<T, E>(E error)
//   • Convenience extensions: map, mapErr, unwrapOr, when.
//
// Depends on: nothing.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
