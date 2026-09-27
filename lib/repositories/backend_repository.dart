import '../core/utils/api_date_time.dart';
import '../models/backend_models.dart';
import '../services/backend_api_client.dart';

class BackendSnapshot {
  const BackendSnapshot({
    this.energy,
    this.today,
    this.schedule,
    this.report,
    this.weather,
    this.solar,
    this.load,
    this.strategy,
    this.autonomy,
    this.notifications = const [],
    this.decisions = const [],
    this.proposals = const [],
    this.executions = const [],
    this.station,
    this.batteryInsight,
    this.devices = const [],
    this.health,
    this.criticalLoads,
    this.profiles = const [],
    this.areaLoads,
    this.meterInsights = const {},
    this.solarArrays = const {},
    this.actionSet,
  });
  final EnergyState? energy;
  final EnergyToday? today;
  final EnergySchedule? schedule;
  final EnergyReport? report;
  final WeatherContext? weather;
  final ForecastData? solar, load;
  final StrategyState? strategy;
  final AutonomyStatus? autonomy;
  final List<NotificationEventModel> notifications;
  final List<DecisionRun> decisions;
  final List<AuditRecord> proposals, executions;
  final StationSummary? station;
  final BatteryInsight? batteryInsight;
  final List<DiscoveredDevice> devices;
  final SystemHealth? health;
  final CriticalLoadConfig? criticalLoads;
  final List<DeviceProfile> profiles;
  final AreaLoadView? areaLoads;
  final Map<String, SmartMeterInsight> meterInsights;
  final Map<String, SolarArrayInsight> solarArrays;
  final CoordinatedActionSet? actionSet;

  BackendSnapshot copyWith({CoordinatedActionSet? actionSet}) =>
      BackendSnapshot(
        energy: energy,
        today: today,
        schedule: schedule,
        report: report,
        weather: weather,
        solar: solar,
        load: load,
        strategy: strategy,
        autonomy: autonomy,
        notifications: notifications,
        decisions: decisions,
        proposals: proposals,
        executions: executions,
        station: station,
        batteryInsight: batteryInsight,
        devices: devices,
        health: health,
        criticalLoads: criticalLoads,
        profiles: profiles,
        areaLoads: areaLoads,
        meterInsights: meterInsights,
        solarArrays: solarArrays,
        actionSet: actionSet ?? this.actionSet,
      );
}

class BackendRepository {
  BackendRepository(this.api);
  final BackendApiClient api;
  Future<T?> _safe<T>(Future<T> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }

  Future<BackendSnapshot> load() async {
    final results = await Future.wait<dynamic>([
      _safe(() => api.getJson('/api/v1/energy/state')),
      _safe(() => api.getJson('/api/v1/energy/today')),
      _safe(() => api.getJson('/api/v1/energy/schedule/24h')),
      _safe(() => api.getJson('/api/v1/report/energy')),
      _safe(() => api.getJson('/api/v1/weather')),
      _safe(() => api.getJson('/api/v1/solar-forecast')),
      _safe(() => api.getJson('/api/v1/load-forecast')),
      _safe(() => api.getJson('/api/v1/strategy')),
      _safe(() => api.getJson('/api/v1/autonomy/status')),
      _safe(() => api.getJson('/api/v1/notifications?limit=50')),
      _safe(() => api.getJson('/api/v1/autonomy/decisions?limit=50')),
      _safe(() => api.getJson('/api/v1/proposals')),
      _safe(() => api.getJson('/api/v1/executions')),
      _safe(() => api.getJson('/api/v1/stations/current')),
      _safe(() => api.getJson('/api/v1/devices/discover/bound')),
      _safe(() => api.getJson('/api/v1/health/summary')),
      _safe(() => api.getJson('/api/v1/critical-loads')),
      _safe(() => api.getJson('/api/v1/devices/profiles/catalog')),
      _safe(() => api.getJson('/api/v1/areas/load-view')),
      _safe(() => api.getJson('/api/v1/action-sets')),
    ]);
    List<AuditRecord> audits(
      dynamic raw,
      String kind,
      String listKey,
      String statusKey,
    ) {
      if (raw is! Map<String, dynamic>) return const [];
      return (raw[listKey] as List? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return AuditRecord(
          kind,
          '$kind #${m['id']}',
          '${m[statusKey]} · ${m['capability'] ?? m['result_code'] ?? ''}',
          parseApiDateTime(m['updated_at'] ?? m['created_at']),
        );
      }).toList();
    }

    final n = results[9] as Map<String, dynamic>?;
    final d = results[10] as Map<String, dynamic>?;
    final station = results[13] is Map<String, dynamic>
        ? StationSummary.fromJson(results[13])
        : null;
    final insightRaw = station?.deviceId == null
        ? null
        : await _safe(
            () => api.getJson(
              '/api/v1/devices/${station!.deviceId}/battery-insight',
            ),
          );
    final discovered = results[14] as Map<String, dynamic>?;
    final devices = (discovered?['devices'] as List? ?? [])
        .map((e) => DiscoveredDevice.fromJson(e as Map<String, dynamic>))
        .toList();
    final meterEntries = await Future.wait(
      devices.where((device) => device.deviceType == 'smart_meter').map((
        device,
      ) async {
        final raw = await _safe(
          () => api.getJson('/api/v1/meters/${device.deviceId}/insight'),
        );
        return MapEntry(
          device.deviceId,
          raw is Map<String, dynamic> ? SmartMeterInsight.fromJson(raw) : null,
        );
      }),
    );
    final solarEntries = await Future.wait(
      devices.where((device) => device.deviceType == 'storage').map((
        device,
      ) async {
        final raw = await _safe(
          () => api.getJson(
            '/api/v1/devices/${device.deviceId}/solar-array-insight',
          ),
        );
        return MapEntry(
          device.deviceId,
          raw is Map<String, dynamic> ? SolarArrayInsight.fromJson(raw) : null,
        );
      }),
    );
    return BackendSnapshot(
      energy: results[0] is Map<String, dynamic>
          ? EnergyState.fromJson(results[0])
          : null,
      today: results[1] is Map<String, dynamic>
          ? EnergyToday.fromJson(results[1])
          : null,
      schedule: results[2] is Map<String, dynamic>
          ? EnergySchedule.fromJson(results[2])
          : null,
      report: results[3] is Map<String, dynamic>
          ? EnergyReport.fromJson(results[3])
          : null,
      weather: results[4] is Map<String, dynamic>
          ? WeatherContext.fromJson(results[4])
          : null,
      solar: results[5] is Map<String, dynamic>
          ? ForecastData.solar(results[5])
          : null,
      load: results[6] is Map<String, dynamic>
          ? ForecastData.load(results[6])
          : null,
      strategy: results[7] is Map<String, dynamic>
          ? StrategyState.fromJson(results[7])
          : null,
      autonomy: results[8] is Map<String, dynamic>
          ? AutonomyStatus.fromJson(results[8])
          : null,
      notifications: (n?['notifications'] as List? ?? [])
          .map((e) => NotificationEventModel.fromJson(e))
          .toList(),
      decisions: (d?['decisions'] as List? ?? [])
          .map((e) => DecisionRun.fromJson(e))
          .toList(),
      proposals: audits(results[11], '方案', 'proposals', 'status'),
      executions: audits(results[12], '执行', 'executions', 'status'),
      station: station,
      batteryInsight: insightRaw is Map<String, dynamic>
          ? BatteryInsight.fromJson(insightRaw)
          : null,
      devices: devices,
      health: results[15] is Map<String, dynamic>
          ? SystemHealth.fromJson(results[15])
          : null,
      criticalLoads: results[16] is Map<String, dynamic>
          ? CriticalLoadConfig.fromJson(results[16])
          : null,
      profiles: results[17] is Map<String, dynamic>
          ? ((results[17]['profiles'] as List? ?? [])
                .map((e) => DeviceProfile.fromJson(e as Map<String, dynamic>))
                .toList())
          : const [],
      areaLoads: results[18] is Map<String, dynamic>
          ? AreaLoadView.fromJson(results[18])
          : null,
      meterInsights: {
        for (final entry in meterEntries)
          if (entry.value != null) entry.key: entry.value!,
      },
      solarArrays: {
        for (final entry in solarEntries)
          if (entry.value != null) entry.key: entry.value!,
      },
      actionSet:
          results[19] is Map<String, dynamic> &&
              ((results[19] as Map<String, dynamic>)['action_sets'] as List?)
                      ?.isNotEmpty ==
                  true
          ? CoordinatedActionSet.fromJson(
              ((results[19] as Map<String, dynamic>)['action_sets'] as List)
                      .first
                  as Map<String, dynamic>,
            )
          : null,
    );
  }

  Future<StrategyState> updateStrategy(String mode) async =>
      StrategyState.fromJson(
        await api.putJson('/api/v1/strategy', {'mode': mode}),
      );
  Future<String> updateAutonomyLevel(String level) async {
    final response = await api.putJson('/api/v1/autonomy/level', {
      'level': level,
    });
    return '${response['level']}';
  }

  Future<void> markRead(int id) async =>
      api.patch('/api/v1/notifications/$id/read');

  Future<void> approveProposal(int id) async =>
      api.postJson('/api/v1/proposals/$id/approve');

  Future<void> rejectProposal(int id) async =>
      api.postJson('/api/v1/proposals/$id/reject');

  Future<CoordinatedActionSet> approveActionSet(int id) async =>
      CoordinatedActionSet.fromJson(
        await api.postJson('/api/v1/action-sets/$id/approve'),
      );

  Future<CoordinatedActionSet> rejectActionSet(int id) async =>
      CoordinatedActionSet.fromJson(
        await api.postJson('/api/v1/action-sets/$id/reject'),
      );

  Future<CoordinatedActionSet> getActionSet(int id) async =>
      CoordinatedActionSet.fromJson(
        await api.getJson('/api/v1/action-sets/$id'),
      );

  Future<void> addCriticalLoad({
    required String name,
    required String category,
    required double ratedPowerW,
  }) async => api.postJson('/api/v1/critical-loads', {
    'name': name,
    'category': category,
    'rated_power_w': ratedPowerW,
    'enabled': true,
  });

  Future<void> setCriticalLoadEnabled(int id, bool enabled) async =>
      api.patchJson('/api/v1/critical-loads/$id', {'enabled': enabled});

  Future<void> deleteCriticalLoad(int id) async =>
      api.delete('/api/v1/critical-loads/$id');

  Future<void> bindDevice(String sourceDeviceId) async =>
      api.postJson('/api/v1/devices/$sourceDeviceId/bind', {
        'observe_enabled': true,
        'propose_enabled': true,
        'control_enabled': false,
      });

  Future<void> setDeviceControlEnabled(int id, bool enabled) async =>
      api.patchJson('/api/v1/devices/$id', {'control_enabled': enabled});

  Future<List<CompanionTerminal>> listCompanionTerminals() async =>
      (await api.getList('/api/v1/companion/devices'))
          .map(
            (item) => CompanionTerminal.fromJson(item as Map<String, dynamic>),
          )
          .toList();

  Future<CompanionTerminal> confirmCompanionPairing(String code) async =>
      CompanionTerminal.fromJson(
        await api.postJson('/api/v1/companion/pairing/confirm', {'code': code}),
      );

  Future<CompanionTerminal> revokeCompanion(String deviceUid) async =>
      CompanionTerminal.fromJson(
        await api.postJson('/api/v1/companion/devices/$deviceUid/revoke'),
      );

  Future<String> setSmartPlugPower(int id, bool targetOn) async {
    final proposal = await api.postJson(
      '/api/v1/devices/$id/switch-proposals',
      {'target_on': targetOn},
    );
    final proposalId = (proposal['id'] as num).toInt();
    final result = await api.postJson('/api/v1/proposals/$proposalId/approve');
    final finalProposal = result['proposal'] as Map<String, dynamic>?;
    return '${finalProposal?['status'] ?? 'UNKNOWN'}';
  }

  Future<String> setStorageControl(
    int id,
    String capability,
    double targetValue,
  ) async {
    final proposal = await api.postJson(
      '/api/v1/devices/$id/control-proposals',
      {'capability': capability, 'target_value': targetValue},
    );
    final proposalId = (proposal['id'] as num).toInt();
    final result = await api.postJson('/api/v1/proposals/$proposalId/approve');
    final finalProposal = result['proposal'] as Map<String, dynamic>?;
    return '${finalProposal?['status'] ?? 'UNKNOWN'}';
  }
}
