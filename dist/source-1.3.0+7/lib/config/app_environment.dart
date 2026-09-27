enum AppEnvironment { development, production }

abstract final class AppEnvironmentConfig {
  /// 当前运行环境。
  ///
  /// 本地开发时改为 [AppEnvironment.development]；当前正式版本使用
  /// [AppEnvironment.production]。
  static const AppEnvironment current = AppEnvironment.production;

  static const String developmentBaseUrl = 'http://127.0.0.1:8000';
  static const String productionBaseUrl = 'http://43.155.204.194:8000';

  static const String _runtimeOverride = String.fromEnvironment(
    'GUANGHENG_API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl =>
      resolve(environment: current, runtimeOverride: _runtimeOverride);

  /// Resolves the URL in one place and keeps environment selection testable.
  static String resolve({
    required AppEnvironment environment,
    String runtimeOverride = '',
  }) {
    final override = runtimeOverride.trim();
    if (override.isNotEmpty) return override;

    return switch (environment) {
      AppEnvironment.development => developmentBaseUrl,
      AppEnvironment.production => productionBaseUrl,
    };
  }
}
