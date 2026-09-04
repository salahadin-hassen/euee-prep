/// Atomic execution boundary for content-pack import.
///
/// The canonical architecture (Decision 026) forbids Services from reaching
/// into Drift directly, yet import must be atomic so a failed import never
/// leaves partial content behind. This injected seam gives the
/// [ContentImportService] an atomic boundary without executing any queries
/// itself: every actual row write still flows through the existing
/// repositories inside [run], and Drift rolls the whole body back if it throws.
abstract interface class ContentImportTransaction {
  Future<T> run<T>(Future<T> Function() body);
}
