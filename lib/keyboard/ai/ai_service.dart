// lib/keyboard/ai/ai_service.dart
//
// AiService — the ONE file that owns everything AI in TACT.
//
// Contents (planned):
//   • Interface + HTTP implementation + DTOs in one file. Split later when
//     one of them grows past ~200 lines. Startup pragmatism.
//
//   • abstract class AiService {
//       Future<Result<String, AiError>> fix     (String text, {CancellationToken? token});
//       Future<Result<String, AiError>> improve (String text, {CancellationToken? token});
//       Future<Result<String, AiError>> soften  (String text, {CancellationToken? token});
//     }
//
//   • class HttpAiService implements AiService  — the real client.
//   • class NullAiService implements AiService  — always returns Err(offline).
//         Used when the network is unreachable, when the user has disabled AI
//         in settings, or when API credentials are missing. Chips grey out
//         gracefully. Typing is never affected.
//
// Golden rules:
//   • AiService is called ONLY from text_actions.dart, ONLY after an explicit
//     ActionTapped event. There is no path from typing → AiService.
//   • Every call takes a CancellationToken. A new keystroke cancels the token.
//   • Requests are ephemeral. No user text is persisted here.
//   • Timeouts are short (< 5 s) — the user will just keep typing.
//
// Depends on: core/result.dart. HTTP dependency added when this is implemented.
// Must NOT: touch the panel or the state machine directly.
//
// TODO: implement.
library;
