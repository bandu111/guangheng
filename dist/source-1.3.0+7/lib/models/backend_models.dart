class EnergyState {
  const EnergyState({
    this.solarW,
    this.homeLoadW,
    this.chargeW,
    this.dischargeW,
    this.gridImportW,
    this.gridExportW,
    this.soc,
    this.batteryStatus,
    this.sourceMode,
  });
  final double? solarW,
      homeLoadW,
      chargeW,
      dischargeW,
      gridImportW,
      gridExportW,
      soc;
  final String? batteryStatus, sourceMode;
  factory EnergyState.fromJson(Map<String, dynamic> json) {
    final power = json['power'] as Map<String, dynamic>? ?? {};
    final storage = json['storage'] as Map<String, dynamic>? ?? {};
    final source = json['source'] as Map<String, dynamic>? ?? {};
    double? n(String key, Map<String, dynamic> map) =>
        (map[key] as num?)?.toDouble();
    return EnergyState(
      solarW: n('solar_w', power),
      homeLoadW: n('home_load_w', power),
      chargeW: n('battery_charging_w', power),
      dischargeW: n('battery_discharging_w', power),
      gridImportW: n('grid_import_w', power),
      gridExportW: n('grid_export_w', power),
      soc: n('soc_percent', storage),
      batteryStatus: storage['status'] as String?,
      sourceMode: source['source_mode'] as String?,
    );
  }
}

class StationNode {
  const StationNode({
    required this.key,
    required this.label,
    required this.available,
    required this.direction,
    this.powerW,
    this.status,
  });
  final String key, label, direction;
  final bool available;
  final double? powerW;
  final String? status;
  factory StationNode.fromJson(Map<String, dynamic> j) => StationNode(
    key: '${j['key']}',
    label: '${j['label']}',
    available: j['available'] == true,
    direction: '${j['direction'] ?? 'idle'}',
    powerW: (j['power_w'] as num?)?.toDouble(),
    status: j['status'] as String?,
  );
}

class StationSummary {
  const StationSummary({
    required this.available,
    required this.online,
    required this.dataQuality,
    required this.nodes,
    required this.coveragePercent,
    this.deviceId,
    this.displayName,
    this.sourceMode,
    this.observedAt,
    this.diagnostic,
  });
  final bool available, online;
  final String dataQuality;
  final List<StationNode> nodes;
  final double coveragePercent;
  final int? deviceId;
  final String? displayName, sourceMode, diagnostic;
  final DateTime? observedAt;
  factory StationSummary.fromJson(Map<String, dynamic> j) {
    final source = j['source'] as Map<String, dynamic>? ?? {};
    final today = j['today'] as Map<String, dynamic>? ?? {};
    return StationSummary(
      available: j['available'] == true,
      online: j['online'] == true,
      dataQuality: '${j['data_quality'] ?? 'missing'}',
      nodes: (j['nodes'] as List? ?? [])
          .map((e) => StationNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      coveragePercent: (today['coverage_percent'] as num?)?.toDouble() ?? 0,
      deviceId: (source['device_id'] as num?)?.toInt(),
      displayName: source['display_name'] as String?,
      sourceMode: source['source_mode'] as String?,
      observedAt: DateTime.tryParse('${j['observed_at']}'),
      diagnostic: j['diagnostic'] as String?,
    );
  }
  StationNode? node(String key) {
    for (final item in nodes) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class DeviceCapability {
  const DeviceCapability({
    required this.name,
    required this.access,
    required this.available,
    this.value,
    this.unit,
    this.verified,
    this.verificationStatus,
    this.verificationMethod,
    this.verificationNote,
    this.readbackReliable,
    this.entityId,
    this.min,
    this.max,
    this.step,
  });
  final String name, access;
  final bool available;
  final dynamic value;
  final String? unit;
  final bool? verified;
  final String? verificationStatus, verificationMethod, verificationNote;
  final bool? readbackReliable;
  final String? entityId;
  final double? min, max, step;
  factory DeviceCapability.fromJson(Map<String, dynamic> j) => DeviceCapability(
    name: '${j['name']}',
    access: '${j['access']}',
    available: j['available'] == true,
    value: j['value'],
    unit: j['unit'] as String?,
    verified: j['verified'] as bool?,
    verificationStatus: j['verification_status'] as String?,
    verificationMethod: j['verification_method'] as String?,
    verificationNote: j['verification_note'] as String?,
    readbackReliable: j['readback_reliable'] as bool?,
    entityId: j['entity_id'] as String?,
    min: (j['min'] as num?)?.toDouble(),
    max: (j['max'] as num?)?.toDouble(),
    step: (j['step'] as num?)?.toDouble(),
  );
}

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.deviceId,
    required this.model,
    required this.online,
    required this.sourceMode,
    required this.telemetry,
    required this.controls,
    this.firmware,
    this.serialNumber,
    this.deviceType = 'unknown',
    this.topologyRole = 'unknown',
    this.profileId,
    this.profileName,
    this.boundDeviceId,
    this.controlEnabled = false,
  });
  final String deviceId, model, sourceMode;
  final bool online;
  final String deviceType, topologyRole;
  final String? firmware, serialNumber, profileId, profileName;
  final int? boundDeviceId;
  final bool controlEnabled;
  final List<DeviceCapability> telemetry, controls;
  factory DiscoveredDevice.fromJson(Map<String, dynamic> j) => DiscoveredDevice(
    deviceId: '${j['device_id']}',
    model: '${j['model']}',
    online: j['online'] == true,
    sourceMode: '${j['source_mode'] ?? ''}',
    firmware: j['firmware_version'] as String?,
    serialNumber: j['serial_number'] as String?,
    deviceType: '${j['device_type'] ?? 'unknown'}',
    topologyRole: '${j['topology_role'] ?? 'unknown'}',
    profileId: j['profile_id'] as String?,
    profileName: j['profile_name'] as String?,
    boundDeviceId: (j['bound_device_id'] as num?)?.toInt(),
    controlEnabled: j['control_enabled'] == true,
    telemetry: (j['telemetry'] as List? ?? [])
        .map((e) => DeviceCapability.fromJson(e as Map<String, dynamic>))
        .toList(),
    controls: (j['controls'] as List? ?? [])
        .map((e) => DeviceCapability.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class BatteryInsight {
  const BatteryInsight({
    required this.available,
    required this.assumptions,
    this.soc,
    this.capacityKwh,
    this.currentEnergyKwh,
    this.reservePercent,
    this.protectedEnergyKwh,
    this.usableEnergyKwh,
    this.homeLoadW,
    this.wholeHomeHours,
    this.criticalLoadHours,
    this.status,
    this.observedAt,
  });
  final bool available;
  final double? soc,
      capacityKwh,
      currentEnergyKwh,
      reservePercent,
      protectedEnergyKwh,
      usableEnergyKwh,
      homeLoadW,
      wholeHomeHours,
      criticalLoadHours;
  final String? status;
  final DateTime? observedAt;
  final List<String> assumptions;
  factory BatteryInsight.fromJson(Map<String, dynamic> j) => BatteryInsight(
    available: j['available'] == true,
    soc: (j['soc_percent'] as num?)?.toDouble(),
    capacityKwh: (j['capacity_kwh'] as num?)?.toDouble(),
    currentEnergyKwh: (j['current_energy_kwh'] as num?)?.toDouble(),
    reservePercent: (j['reserve_percent'] as num?)?.toDouble(),
    protectedEnergyKwh: (j['protected_energy_kwh'] as num?)?.toDouble(),
    usableEnergyKwh: (j['usable_energy_kwh'] as num?)?.toDouble(),
    homeLoadW: (j['whole_home_load_w'] as num?)?.toDouble(),
    wholeHomeHours: (j['whole_home_backup_hours'] as num?)?.toDouble(),
    criticalLoadHours: (j['critical_load_backup_hours'] as num?)?.toDouble(),
    status: j['status'] as String?,
    observedAt: DateTime.tryParse('${j['observed_at']}'),
    assumptions: (j['assumptions'] as List? ?? []).map((e) => '$e').toList(),
  );
}

class SolarInputChannel {
  const SolarInputChannel({
    required this.key,
    required this.label,
    required this.available,
    this.powerW,
    this.voltageV,
    this.currentA,
    this.energyKwh,
  });
  final String key, label;
  final bool available;
  final double? powerW, voltageV, currentA, energyKwh;
  factory SolarInputChannel.fromJson(Map<String, dynamic> j) =>
      SolarInputChannel(
        key: '${j['key']}',
        label: '${j['label']}',
        available: j['available'] == true,
        powerW: (j['power_w'] as num?)?.toDouble(),
        voltageV: (j['voltage_v'] as num?)?.toDouble(),
        currentA: (j['current_a'] as num?)?.toDouble(),
        energyKwh: (j['energy_kwh'] as num?)?.toDouble(),
      );
}

class SolarComponent {
  const SolarComponent({
    required this.key,
    required this.label,
    required this.available,
    this.powerW,
    this.energyKwh,
  });
  final String key, label;
  final bool available;
  final double? powerW, energyKwh;
  factory SolarComponent.fromJson(Map<String, dynamic> j) => SolarComponent(
    key: '${j['key']}',
    label: '${j['label']}',
    available: j['available'] == true,
    powerW: (j['power_w'] as num?)?.toDouble(),
    energyKwh: (j['energy_kwh'] as num?)?.toDouble(),
  );
}

class SolarArrayInsight {
  const SolarArrayInsight({
    required this.available,
    required this.deviceOnline,
    required this.channelsAvailable,
    required this.componentsAvailable,
    required this.channels,
    required this.components,
    this.aggregatePowerW,
    this.diagnostic,
  });
  final bool available, deviceOnline, channelsAvailable, componentsAvailable;
  final double? aggregatePowerW;
  final List<SolarInputChannel> channels;
  final List<SolarComponent> components;
  final String? diagnostic;
  factory SolarArrayInsight.fromJson(Map<String, dynamic> j) =>
      SolarArrayInsight(
        available: j['available'] == true,
        deviceOnline: j['device_online'] == true,
        channelsAvailable: j['channel_data_available'] == true,
        componentsAvailable: j['component_data_available'] == true,
        aggregatePowerW: (j['aggregate_power_w'] as num?)?.toDouble(),
        channels: (j['mppt_channels'] as List? ?? [])
            .map((e) => SolarInputChannel.fromJson(e as Map<String, dynamic>))
            .toList(),
        components: (j['components'] as List? ?? [])
            .map((e) => SolarComponent.fromJson(e as Map<String, dynamic>))
            .toList(),
        diagnostic: j['diagnostic'] as String?,
      );
}

class HealthCheck {
  const HealthCheck({
    required this.key,
    required this.label,
    required this.status,
    required this.detail,
    required this.blocking,
  });
  final String key, label, status, detail;
  final bool blocking;
  factory HealthCheck.fromJson(Map<String, dynamic> j) => HealthCheck(
    key: '${j['key']}',
    label: '${j['label']}',
    status: '${j['status']}',
    detail: '${j['detail']}',
    blocking: j['blocking'] == true,
  );
}

class SystemHealth {
  const SystemHealth({
    required this.status,
    required this.checks,
    required this.recoveryActions,
    this.observedAt,
  });
  final String status;
  final List<HealthCheck> checks;
  final List<String> recoveryActions;
  final DateTime? observedAt;
  factory SystemHealth.fromJson(Map<String, dynamic> j) => SystemHealth(
    status: '${j['status']}',
    checks: (j['checks'] as List? ?? [])
        .map((e) => HealthCheck.fromJson(e as Map<String, dynamic>))
        .toList(),
    recoveryActions: (j['recovery_actions'] as List? ?? [])
        .map((e) => '$e')
        .toList(),
    observedAt: DateTime.tryParse('${j['observed_at']}'),
  );
}

class CriticalLoad {
  const CriticalLoad({
    required this.id,
    required this.name,
    required this.category,
    required this.ratedPowerW,
    required this.enabled,
  });
  final int id;
  final String name, category;
  final double ratedPowerW;
  final bool enabled;
  factory CriticalLoad.fromJson(Map<String, dynamic> j) => CriticalLoad(
    id: (j['id'] as num).toInt(),
    name: '${j['name']}',
    category: '${j['category']}',
    ratedPowerW: (j['rated_power_w'] as num).toDouble(),
    enabled: j['enabled'] == true,
  );
}

class CriticalLoadConfig {
  const CriticalLoadConfig({
    required this.loads,
    required this.totalPowerW,
    required this.enabledCount,
  });
  final List<CriticalLoad> loads;
  final double totalPowerW;
  final int enabledCount;
  factory CriticalLoadConfig.fromJson(Map<String, dynamic> j) =>
      CriticalLoadConfig(
        loads: (j['loads'] as List? ?? [])
            .map((e) => CriticalLoad.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPowerW: (j['total_power_w'] as num?)?.toDouble() ?? 0,
        enabledCount: (j['enabled_count'] as num?)?.toInt() ?? 0,
      );
}

class EnergyTodaySummary {
  const EnergyTodaySummary({
    this.generationKwh,
    this.consumptionKwh,
    this.gridImportKwh,
    this.savingsCny,
    this.generationChangePercent,
    this.consumptionChangePercent,
    this.savingsChangePercent,
    this.tariffPricePerKwh,
    this.currency = 'CNY',
  });
  final double? generationKwh;
  final double? consumptionKwh;
  final double? gridImportKwh;
  final double? savingsCny;
  final double? generationChangePercent;
  final double? consumptionChangePercent;
  final double? savingsChangePercent;
  final double? tariffPricePerKwh;
  final String currency;

  factory EnergyTodaySummary.fromJson(Map<String, dynamic> json) =>
      EnergyTodaySummary(
        generationKwh: (json['generation_kwh'] as num?)?.toDouble(),
        consumptionKwh: (json['consumption_kwh'] as num?)?.toDouble(),
        gridImportKwh: (json['grid_import_kwh'] as num?)?.toDouble(),
        savingsCny: (json['savings_cny'] as num?)?.toDouble(),
        generationChangePercent: (json['generation_change_percent'] as num?)
            ?.toDouble(),
        consumptionChangePercent: (json['consumption_change_percent'] as num?)
            ?.toDouble(),
        savingsChangePercent: (json['savings_change_percent'] as num?)
            ?.toDouble(),
        tariffPricePerKwh: (json['tariff_price_per_kwh'] as num?)?.toDouble(),
        currency: '${json['currency'] ?? 'CNY'}',
      );
}

class EnergyFlowPoint {
  const EnergyFlowPoint({
    required this.time,
    required this.hour,
    this.solarPowerW,
    this.homeLoadW,
    this.gridImportW,
    required this.coveragePercent,
  });
  final DateTime time;
  final int hour;
  final double? solarPowerW, homeLoadW, gridImportW;
  final double coveragePercent;

  factory EnergyFlowPoint.fromJson(Map<String, dynamic> json) =>
      EnergyFlowPoint(
        time: DateTime.parse('${json['time']}'),
        hour: (json['hour'] as num).toInt(),
        solarPowerW: (json['solar_power_w'] as num?)?.toDouble(),
        homeLoadW: (json['home_load_w'] as num?)?.toDouble(),
        gridImportW: (json['grid_import_w'] as num?)?.toDouble(),
        coveragePercent: (json['coverage_percent'] as num?)?.toDouble() ?? 0,
      );
}

class EnergyToday {
  const EnergyToday({
    required this.available,
    required this.summary,
    required this.flow,
    required this.coveragePercent,
  });
  final bool available;
  final EnergyTodaySummary summary;
  final List<EnergyFlowPoint> flow;
  final double coveragePercent;

  factory EnergyToday.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>? ?? {};
    return EnergyToday(
      available: json['available'] == true,
      summary: EnergyTodaySummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
      flow: (json['flow'] as List? ?? [])
          .map((item) => EnergyFlowPoint.fromJson(item))
          .toList(),
      coveragePercent: (source['coverage_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeviceProfile {
  const DeviceProfile({
    required this.id,
    required this.name,
    required this.deviceType,
    required this.telemetry,
    required this.controls,
    required this.verifiedControls,
    this.supportStatus = 'supported',
    this.firmwareRequirement,
  });
  final String id, name, deviceType;
  final String supportStatus;
  final String? firmwareRequirement;
  final List<String> telemetry, controls, verifiedControls;
  factory DeviceProfile.fromJson(Map<String, dynamic> j) => DeviceProfile(
    id: '${j['profile_id']}',
    name: '${j['display_name']}',
    deviceType: '${j['device_type']}',
    telemetry: (j['telemetry'] as List? ?? []).map((e) => '$e').toList(),
    controls: (j['controls'] as List? ?? []).map((e) => '$e').toList(),
    verifiedControls: (j['verified_controls'] as List? ?? [])
        .map((e) => '$e')
        .toList(),
    supportStatus: '${j['support_status'] ?? 'supported'}',
    firmwareRequirement: j['firmware_requirement'] as String?,
  );
}

class AreaLoadEntity {
  const AreaLoadEntity({
    required this.entityId,
    required this.name,
    required this.available,
    required this.includedInTotal,
    this.powerW,
  });
  final String entityId, name;
  final bool available, includedInTotal;
  final double? powerW;
  factory AreaLoadEntity.fromJson(Map<String, dynamic> j) => AreaLoadEntity(
    entityId: '${j['entity_id']}',
    name: '${j['name']}',
    available: j['available'] == true,
    includedInTotal: j['included_in_total'] == true,
    powerW: (j['power_w'] as num?)?.toDouble(),
  );
}

class AreaLoad {
  const AreaLoad({
    required this.id,
    required this.name,
    required this.totalPowerW,
    required this.entities,
  });
  final String? id;
  final String name;
  final double totalPowerW;
  final List<AreaLoadEntity> entities;
  factory AreaLoad.fromJson(Map<String, dynamic> j) => AreaLoad(
    id: j['area_id'] as String?,
    name: '${j['name']}',
    totalPowerW: (j['total_power_w'] as num?)?.toDouble() ?? 0,
    entities: (j['entities'] as List? ?? [])
        .map((e) => AreaLoadEntity.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class AreaLoadView {
  const AreaLoadView({
    required this.available,
    required this.totalPowerW,
    required this.areas,
    required this.unassigned,
    this.diagnostic,
  });
  final bool available;
  final double totalPowerW;
  final List<AreaLoad> areas;
  final List<AreaLoadEntity> unassigned;
  final String? diagnostic;
  factory AreaLoadView.fromJson(Map<String, dynamic> j) => AreaLoadView(
    available: j['available'] == true,
    totalPowerW: (j['total_power_w'] as num?)?.toDouble() ?? 0,
    areas: (j['areas'] as List? ?? [])
        .map((e) => AreaLoad.fromJson(e as Map<String, dynamic>))
        .toList(),
    unassigned: (j['unassigned'] as List? ?? [])
        .map((e) => AreaLoadEntity.fromJson(e as Map<String, dynamic>))
        .toList(),
    diagnostic: j['diagnostic'] as String?,
  );
}

class MeterPhase {
  const MeterPhase({
    this.phase = '',
    this.powerW,
    this.currentA,
    this.voltageV,
  });
  final String phase;
  final double? powerW, currentA, voltageV;
  factory MeterPhase.fromJson(Map<String, dynamic> j) => MeterPhase(
    phase: '${j['phase']}',
    powerW: (j['active_power_w'] as num?)?.toDouble(),
    currentA: (j['current_a'] as num?)?.toDouble(),
    voltageV: (j['voltage_v'] as num?)?.toDouble(),
  );
}

class MeterChannel {
  const MeterChannel({
    required this.channel,
    required this.phases,
    this.activePowerW,
    this.reactivePowerW,
    this.powerFactor,
    this.forwardEnergyKwh,
    this.reverseEnergyKwh,
  });
  final String channel;
  final List<MeterPhase> phases;
  final double? activePowerW,
      reactivePowerW,
      powerFactor,
      forwardEnergyKwh,
      reverseEnergyKwh;
  factory MeterChannel.fromJson(Map<String, dynamic> j) => MeterChannel(
    channel: '${j['channel']}',
    activePowerW: (j['total_active_power_w'] as num?)?.toDouble(),
    reactivePowerW: (j['total_reactive_power_w'] as num?)?.toDouble(),
    powerFactor: (j['power_factor'] as num?)?.toDouble(),
    forwardEnergyKwh: (j['forward_energy_kwh'] as num?)?.toDouble(),
    reverseEnergyKwh: (j['reverse_energy_kwh'] as num?)?.toDouble(),
    phases: (j['phases'] as List? ?? [])
        .map((e) => MeterPhase.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class SmartMeterInsight {
  const SmartMeterInsight({
    required this.available,
    required this.deviceId,
    required this.model,
    required this.online,
    required this.channels,
    this.meterType,
    this.diagnostic,
  });
  final bool available, online;
  final String deviceId, model;
  final String? meterType, diagnostic;
  final List<MeterChannel> channels;
  factory SmartMeterInsight.fromJson(Map<String, dynamic> j) =>
      SmartMeterInsight(
        available: j['available'] == true,
        deviceId: '${j['device_id']}',
        model: '${j['model']}',
        online: j['online'] == true,
        meterType: j['meter_type'] as String?,
        diagnostic: j['diagnostic'] as String?,
        channels: (j['channels'] as List? ?? [])
            .map((e) => MeterChannel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class EnergySchedulePoint {
  const EnergySchedulePoint({
    required this.time,
    required this.hour,
    required this.action,
    required this.confidence,
    this.solarPowerW,
    this.loadPowerW,
    this.netPowerW,
  });
  final DateTime time;
  final int hour;
  final String action, confidence;
  final double? solarPowerW, loadPowerW, netPowerW;

  factory EnergySchedulePoint.fromJson(Map<String, dynamic> json) =>
      EnergySchedulePoint(
        time: DateTime.parse('${json['time']}'),
        hour: (json['hour'] as num).toInt(),
        action: '${json['action']}',
        confidence: '${json['confidence']}',
        solarPowerW: (json['solar_power_w'] as num?)?.toDouble(),
        loadPowerW: (json['load_power_w'] as num?)?.toDouble(),
        netPowerW: (json['net_power_w'] as num?)?.toDouble(),
      );
}

class EnergySchedule {
  const EnergySchedule({
    required this.available,
    required this.points,
    required this.strategy,
    required this.advisoryOnly,
    required this.executable,
    this.projectedSolarKwh,
    this.projectedLoadKwh,
    this.projectedSurplusKwh,
    this.projectedDeficitKwh,
  });
  final bool available, advisoryOnly, executable;
  final List<EnergySchedulePoint> points;
  final String strategy;
  final double? projectedSolarKwh,
      projectedLoadKwh,
      projectedSurplusKwh,
      projectedDeficitKwh;

  factory EnergySchedule.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final source = json['source'] as Map<String, dynamic>? ?? {};
    return EnergySchedule(
      available: json['available'] == true,
      points: (json['points'] as List? ?? [])
          .map((item) => EnergySchedulePoint.fromJson(item))
          .toList(),
      strategy: '${source['strategy'] ?? ''}',
      advisoryOnly: source['advisory_only'] == true,
      executable: source['executable'] == true,
      projectedSolarKwh: (summary['projected_solar_kwh'] as num?)?.toDouble(),
      projectedLoadKwh: (summary['projected_load_kwh'] as num?)?.toDouble(),
      projectedSurplusKwh: (summary['projected_surplus_kwh'] as num?)
          ?.toDouble(),
      projectedDeficitKwh: (summary['projected_deficit_kwh'] as num?)
          ?.toDouble(),
    );
  }
}

class EnergyReportMetrics {
  const EnergyReportMetrics({
    this.consumptionKwh,
    this.generationKwh,
    this.gridImportKwh,
    this.gridExportKwh,
    this.solarSelfUsePercent,
    this.referenceBaselineCostCny,
    this.actualGridCostCny,
    this.savingsCny,
    this.savingsPercent,
    this.carbonReductionKg,
  });
  final double? consumptionKwh,
      generationKwh,
      gridImportKwh,
      gridExportKwh,
      solarSelfUsePercent,
      referenceBaselineCostCny,
      actualGridCostCny,
      savingsCny,
      savingsPercent,
      carbonReductionKg;

  factory EnergyReportMetrics.fromJson(Map<String, dynamic> json) =>
      EnergyReportMetrics(
        consumptionKwh: (json['consumption_kwh'] as num?)?.toDouble(),
        generationKwh: (json['generation_kwh'] as num?)?.toDouble(),
        gridImportKwh: (json['grid_import_kwh'] as num?)?.toDouble(),
        gridExportKwh: (json['grid_export_kwh'] as num?)?.toDouble(),
        solarSelfUsePercent: (json['solar_self_use_percent'] as num?)
            ?.toDouble(),
        referenceBaselineCostCny: (json['reference_baseline_cost_cny'] as num?)
            ?.toDouble(),
        actualGridCostCny: (json['actual_grid_cost_cny'] as num?)?.toDouble(),
        savingsCny: (json['savings_cny'] as num?)?.toDouble(),
        savingsPercent: (json['savings_percent'] as num?)?.toDouble(),
        carbonReductionKg: (json['carbon_reduction_kg'] as num?)?.toDouble(),
      );
}

class EnergyReportDailyPoint {
  const EnergyReportDailyPoint({
    required this.date,
    this.gridImportKwh,
    this.actualGridCostCny,
    this.savingsCny,
    this.carbonReductionKg,
  });
  final DateTime date;
  final double? gridImportKwh, actualGridCostCny, savingsCny, carbonReductionKg;

  factory EnergyReportDailyPoint.fromJson(Map<String, dynamic> json) =>
      EnergyReportDailyPoint(
        date: DateTime.parse('${json['date']}'),
        gridImportKwh: (json['grid_import_kwh'] as num?)?.toDouble(),
        actualGridCostCny: (json['actual_grid_cost_cny'] as num?)?.toDouble(),
        savingsCny: (json['savings_cny'] as num?)?.toDouble(),
        carbonReductionKg: (json['carbon_reduction_kg'] as num?)?.toDouble(),
      );
}

class EnergyReportPeriod {
  const EnergyReportPeriod({
    required this.metrics,
    required this.daily,
    required this.coveragePercent,
  });
  final EnergyReportMetrics metrics;
  final List<EnergyReportDailyPoint> daily;
  final double coveragePercent;

  factory EnergyReportPeriod.fromJson(Map<String, dynamic> json) =>
      EnergyReportPeriod(
        metrics: EnergyReportMetrics.fromJson(
          json['metrics'] as Map<String, dynamic>? ?? {},
        ),
        daily: (json['daily'] as List? ?? [])
            .map((item) => EnergyReportDailyPoint.fromJson(item))
            .toList(),
        coveragePercent: (json['coverage_percent'] as num?)?.toDouble() ?? 0,
      );
}

class EnergyReport {
  const EnergyReport({
    required this.available,
    required this.periods,
    this.tariffPricePerKwh,
    this.carbonFactorKgPerKwh,
    this.carbonProvider,
    this.carbonReferenceYear,
  });
  final bool available;
  final Map<String, EnergyReportPeriod> periods;
  final double? tariffPricePerKwh, carbonFactorKgPerKwh;
  final String? carbonProvider;
  final int? carbonReferenceYear;

  factory EnergyReport.fromJson(Map<String, dynamic> json) {
    final periods = json['periods'] as Map<String, dynamic>? ?? {};
    final tariff = json['tariff'] as Map<String, dynamic>?;
    final carbon = json['carbon'] as Map<String, dynamic>?;
    return EnergyReport(
      available: json['available'] == true,
      periods: periods.map(
        (key, value) => MapEntry(
          key,
          EnergyReportPeriod.fromJson(value as Map<String, dynamic>),
        ),
      ),
      tariffPricePerKwh: (tariff?['price_per_kwh'] as num?)?.toDouble(),
      carbonFactorKgPerKwh: (carbon?['factor_kg_co2_per_kwh'] as num?)
          ?.toDouble(),
      carbonProvider: carbon?['provider'] as String?,
      carbonReferenceYear: (carbon?['reference_year'] as num?)?.toInt(),
    );
  }
}

class WeatherContext {
  const WeatherContext({this.condition, this.temperature, this.weatherCode});
  final String? condition;
  final double? temperature;
  final int? weatherCode;
  factory WeatherContext.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>?;
    return WeatherContext(
      condition: c?['condition'] as String?,
      temperature: (c?['temperature_c'] as num?)?.toDouble(),
      weatherCode: (c?['weather_code'] as num?)?.toInt(),
    );
  }
}

class ForecastPoint {
  const ForecastPoint(this.time, this.value, this.confidence);
  final DateTime? time;
  final double? value;
  final String? confidence;
}

class ForecastData {
  const ForecastData({
    required this.method,
    required this.points,
    this.next24h,
  });
  final String? method;
  final List<ForecastPoint> points;
  final double? next24h;
  factory ForecastData.solar(Map<String, dynamic> j) => ForecastData(
    method: j['method'] as String?,
    points: (j['forecast'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ForecastPoint(
        DateTime.tryParse('${m['time']}'),
        (m['solar_power_w'] as num?)?.toDouble(),
        m['confidence'] as String?,
      );
    }).toList(),
    next24h:
        ((j['summary'] as Map<String, dynamic>?)?['next_24h_energy_kwh']
                as num?)
            ?.toDouble(),
  );
  factory ForecastData.load(Map<String, dynamic> j) => ForecastData(
    method: j['method'] as String?,
    points: (j['forecast'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return ForecastPoint(
        DateTime.tryParse('${m['time']}'),
        (m['load_power_w'] as num?)?.toDouble(),
        m['confidence'] as String?,
      );
    }).toList(),
    next24h:
        ((j['summary'] as Map<String, dynamic>?)?['next_24h_energy_kwh']
                as num?)
            ?.toDouble(),
  );
}

class StrategyState {
  const StrategyState(this.mode, {this.backupReserveTarget});
  final String mode;
  final double? backupReserveTarget;
  factory StrategyState.fromJson(Map<String, dynamic> j) => StrategyState(
    '${j['mode']}',
    backupReserveTarget: (j['backup_reserve_target'] as num?)?.toDouble(),
  );
}

class PendingProposal {
  const PendingProposal({
    required this.id,
    required this.status,
    required this.capability,
    this.currentValue,
    this.targetValue,
  });
  final int id;
  final String status, capability;
  final double? currentValue, targetValue;
  factory PendingProposal.fromJson(Map<String, dynamic> j) => PendingProposal(
    id: (j['id'] as num).toInt(),
    status: '${j['status']}',
    capability: '${j['capability']}',
    currentValue: (j['current_value'] as num?)?.toDouble(),
    targetValue: (j['target_value'] as num?)?.toDouble(),
  );
}

class DecisionSummary {
  const DecisionSummary({
    this.runId,
    this.strategy,
    this.version,
    this.confidence,
    this.currentValue,
    this.targetValue,
    this.actionRequired,
    this.reasonCode,
    this.evaluatedAt,
    this.resultCode,
  });
  final int? runId;
  final String? strategy, version, confidence, reasonCode, resultCode;
  final double? currentValue, targetValue;
  final bool? actionRequired;
  final DateTime? evaluatedAt;
  factory DecisionSummary.fromJson(Map<String, dynamic> j) => DecisionSummary(
    runId: (j['run_id'] as num?)?.toInt(),
    strategy: j['strategy'] as String?,
    version: j['optimizer_version'] as String?,
    confidence: j['confidence'] as String?,
    currentValue: (j['current_value'] as num?)?.toDouble(),
    targetValue: (j['target_value'] as num?)?.toDouble(),
    actionRequired: j['action_required'] as bool?,
    reasonCode: j['reason_code'] as String?,
    evaluatedAt: DateTime.tryParse('${j['evaluated_at']}'),
    resultCode: j['result_code'] as String?,
  );
}

class AutonomyStatus {
  const AutonomyStatus({
    required this.agentState,
    required this.enabled,
    required this.unreadCount,
    this.autonomyLevel = 'CONFIRM',
    this.latestDecision,
    this.pendingProposal,
  });
  final String agentState;
  final bool enabled;
  final int unreadCount;
  final String autonomyLevel;
  final DecisionSummary? latestDecision;
  final PendingProposal? pendingProposal;
  factory AutonomyStatus.fromJson(Map<String, dynamic> j) => AutonomyStatus(
    agentState: '${j['agent_state']}',
    enabled: j['enabled'] == true,
    unreadCount: (j['unread_notification_count'] as num?)?.toInt() ?? 0,
    autonomyLevel: j['autonomy_level'] as String? ?? 'CONFIRM',
    latestDecision: j['latest_decision'] is Map<String, dynamic>
        ? DecisionSummary.fromJson(j['latest_decision'])
        : null,
    pendingProposal: j['pending_proposal'] is Map<String, dynamic>
        ? PendingProposal.fromJson(j['pending_proposal'])
        : null,
  );

  AutonomyStatus copyWith({String? autonomyLevel}) => AutonomyStatus(
    agentState: agentState,
    enabled: enabled,
    unreadCount: unreadCount,
    autonomyLevel: autonomyLevel ?? this.autonomyLevel,
    latestDecision: latestDecision,
    pendingProposal: pendingProposal,
  );
}

class NotificationEventModel {
  const NotificationEventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });
  final int id;
  final String type, title, message, status;
  final DateTime? createdAt;
  factory NotificationEventModel.fromJson(Map<String, dynamic> j) =>
      NotificationEventModel(
        id: (j['id'] as num).toInt(),
        type: '${j['event_type']}',
        title: '${j['title']}',
        message: '${j['message']}',
        status: '${j['status']}',
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );
}

class DecisionRun {
  const DecisionRun({
    required this.id,
    required this.status,
    this.strategy,
    this.currentValue,
    this.targetValue,
    this.reasonCode,
    this.confidence,
    this.actionRequired,
    this.completedAt,
  });
  final int id;
  final String status;
  final String? strategy, reasonCode, confidence;
  final double? currentValue, targetValue;
  final bool? actionRequired;
  final DateTime? completedAt;
  factory DecisionRun.fromJson(Map<String, dynamic> j) => DecisionRun(
    id: (j['id'] as num).toInt(),
    status: '${j['status']}',
    strategy: j['strategy'] as String?,
    currentValue: (j['current_value'] as num?)?.toDouble(),
    targetValue: (j['target_value'] as num?)?.toDouble(),
    reasonCode: j['reason_code'] as String?,
    confidence: j['confidence'] as String?,
    actionRequired: j['action_required'] as bool?,
    completedAt: DateTime.tryParse('${j['completed_at']}'),
  );
}

class AuditRecord {
  const AuditRecord(this.kind, this.title, this.detail, this.time);
  final String kind, title, detail;
  final DateTime? time;
}
