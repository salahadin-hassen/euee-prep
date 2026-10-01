/// Application-wide configuration values.
///
/// Environment-driven values live here (the module's reserved place in the
/// architecture, Milestone 0 amendment). See docs/AI_RULES.md: no speculative
/// features — values are only added when a real consumer exists.
class AppConfig {
  const AppConfig._();

  /// Base URL of the backend serving the published-paper catalog, e.g.
  /// `https://example.vercel.app`.
  ///
  /// Injected at build/run time:
  /// `flutter run --dart-define=API_BASE_URL=https://example.vercel.app`
  ///
  /// Empty when not configured; the catalog fetch fails with a clear error
  /// instead of guessing a URL.
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// The running app version, compared against each pack's
  /// `minimum_app_version` before and during import.
  static const String currentAppVersion = '1.0.0';
}
