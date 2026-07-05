// lib/companion/onboarding/onboarding.dart
//
// Onboarding flow — welcome + enable-IME. One file, two widgets.
//
// Why one file:
//   These two screens always change together. The whole flow is small
//   (~2 screens). Splitting into two files creates navigation friction for
//   the maintainers.
//
// Contents (planned):
//   • class OnboardingScreen  — welcome + "what TACT is" (from PRODUCT.md).
//   • class EnableImeScreen   — deep-links into system Language & Input.
//   • Small local model for "step done" state.
//
// Depends on: core/kv_store.dart (persist "onboarding_completed"),
//             core/bridge/ime_bridge_facade.dart (check if TACT is enabled).
// Must NOT: import keyboard engines or state machine.
//
// TODO: implement.
library;
