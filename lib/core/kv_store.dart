// lib/core/kv_store.dart
//
// Thin key-value store wrapper.
//
// Purpose:
//   Repositories (settings, statistics, personal shortcuts index) depend on
//   this small interface instead of `shared_preferences` directly. Keeps
//   swapping the backend a one-file change.
//
// Contents (planned):
//   • abstract class KvStore { getString/setString/getInt/setInt/getBool/setBool/remove/keys }
//   • class SharedPrefsKvStore implements KvStore  (default impl)
//
// Depends on: shared_preferences (added when this is implemented).
// Must NOT: leak the underlying package outside this file.
//
// TODO: implement.
library;
