/// Identifies which environment the app is running in.
///
/// Deliberately unused at this stage — reserved for when there's an actual
/// need to distinguish development/staging/production (e.g. once the
/// payment backend from Milestone 7 exists and needs a base URL per
/// environment). No logic implemented yet; see docs/AI_RULES.md.
enum Environment {
  development,
  staging,
  production,
}
