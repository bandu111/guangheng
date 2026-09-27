import 'dart:convert';
import 'dart:io';

import 'package:guangheng/models/backend_models.dart';

const _baseUrl = String.fromEnvironment(
  'GUANGHENG_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

Future<Map<String, dynamic>> _get(HttpClient client, String path) async {
  final request = await client.getUrl(Uri.parse('$_baseUrl$path'));
  final response = await request.close();
  final body = await utf8.decoder.bind(response).join();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('$path returned ${response.statusCode}');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

double? _reserve(Map<String, dynamic> deviceState) {
  final runtime = deviceState['runtime'] as Map<String, dynamic>?;
  final controls = runtime?['controls'] as List? ?? const [];
  for (final item in controls) {
    final control = item as Map<String, dynamic>;
    if (control['name'] == 'backup_reserve') {
      return (control['value'] as num?)?.toDouble();
    }
  }
  return null;
}

Future<void> main() async {
  final client = HttpClient();
  try {
    final beforeProposals = await _get(client, '/api/v1/proposals');
    final beforeExecutions = await _get(client, '/api/v1/executions');
    final beforeDevice = await _get(client, '/api/v1/devices/1/state');

    final energy = EnergyState.fromJson(
      await _get(client, '/api/v1/energy/state'),
    );
    final today = EnergyToday.fromJson(
      await _get(client, '/api/v1/energy/today'),
    );
    final weather = WeatherContext.fromJson(
      await _get(client, '/api/v1/weather'),
    );
    final solar = ForecastData.solar(
      await _get(client, '/api/v1/solar-forecast'),
    );
    final load = ForecastData.load(await _get(client, '/api/v1/load-forecast'));
    final strategy = StrategyState.fromJson(
      await _get(client, '/api/v1/strategy'),
    );
    final autonomy = AutonomyStatus.fromJson(
      await _get(client, '/api/v1/autonomy/status'),
    );
    final notifications = await _get(client, '/api/v1/notifications?limit=50');
    final decisions = await _get(client, '/api/v1/autonomy/decisions?limit=50');

    final afterProposals = await _get(client, '/api/v1/proposals');
    final afterExecutions = await _get(client, '/api/v1/executions');
    final afterDevice = await _get(client, '/api/v1/devices/1/state');

    final before = (
      proposals: beforeProposals['count'],
      executions: beforeExecutions['count'],
      reserve: _reserve(beforeDevice),
    );
    final after = (
      proposals: afterProposals['count'],
      executions: afterExecutions['count'],
      reserve: _reserve(afterDevice),
    );
    if (before != after) {
      throw StateError(
        'Read-only E2E changed backend state: $before -> $after',
      );
    }

    stdout.writeln(
      jsonEncode({
        'energy': {
          'solar_w': energy.solarW,
          'home_load_w': energy.homeLoadW,
          'soc_percent': energy.soc,
          'battery_status': energy.batteryStatus,
        },
        'energy_today': {
          'generation_kwh': today.summary.generationKwh,
          'consumption_kwh': today.summary.consumptionKwh,
          'savings_cny': today.summary.savingsCny,
          'flow_points': today.flow.length,
          'coverage_percent': today.coveragePercent,
        },
        'weather': {
          'condition': weather.condition,
          'temperature_c': weather.temperature,
        },
        'forecast': {
          'solar_points': solar.points.length,
          'load_points': load.points.length,
        },
        'strategy': strategy.mode,
        'autonomy': {
          'agent_state': autonomy.agentState,
          'current_value': autonomy.latestDecision?.currentValue,
          'target_value': autonomy.latestDecision?.targetValue,
          'reason_code': autonomy.latestDecision?.reasonCode,
          'pending_proposal': autonomy.pendingProposal?.id,
        },
        'notification_count': notifications['count'],
        'decision_count': decisions['count'],
        'state_before': {
          'proposal_count': before.proposals,
          'execution_count': before.executions,
          'backup_reserve': before.reserve,
        },
        'state_after': {
          'proposal_count': after.proposals,
          'execution_count': after.executions,
          'backup_reserve': after.reserve,
        },
      }),
    );
  } finally {
    client.close(force: true);
  }
}
