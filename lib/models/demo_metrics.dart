/// Centralized presentation fallback for metrics that the backend does not yet
/// expose. Keeping these values in one model prevents demo content from being
/// mixed with real API models and makes it straightforward to remove later.
abstract final class DemoMetrics {
  static const resilienceHours = 6.2;
}
