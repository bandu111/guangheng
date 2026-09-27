import 'package:flutter_test/flutter_test.dart';
import 'package:guangheng/config/app_environment.dart';
import 'package:guangheng/services/backend_api_client.dart';

void main() {
  test('committed default is production', () {
    expect(AppEnvironmentConfig.current, AppEnvironment.production);
    expect(
      AppEnvironmentConfig.resolve(environment: AppEnvironment.production),
      'https://43.155.204.194',
    );
  });

  test('development resolves to the local backend', () {
    expect(
      AppEnvironmentConfig.resolve(environment: AppEnvironment.development),
      'http://127.0.0.1:8000',
    );
  });

  test('runtime override has the highest priority', () {
    const override = String.fromEnvironment(
      'GUANGHENG_API_BASE_URL',
      defaultValue: '',
    );
    if (override.isNotEmpty) {
      expect(AppEnvironmentConfig.baseUrl, override.trim());
    }
    expect(
      AppEnvironmentConfig.resolve(
        environment: AppEnvironment.production,
        runtimeOverride: ' http://127.0.0.1:8010 ',
      ),
      'http://127.0.0.1:8010',
    );
  });

  test('API client still accepts an injected test URL', () {
    final client = BackendApiClient(baseUrl: 'http://127.0.0.1:8999');
    expect(client.baseUrl, 'http://127.0.0.1:8999');
  });
}
