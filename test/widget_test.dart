import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guangheng/app.dart';
import 'package:guangheng/models/backend_models.dart';
import 'package:guangheng/repositories/backend_repository.dart';
import 'package:guangheng/services/backend_api_client.dart';
import 'package:guangheng/viewmodels/backend_view_model.dart';
import 'package:guangheng/views/station/station_pages.dart';
import 'package:provider/provider.dart';

class TestBackendRepository extends BackendRepository {
  TestBackendRepository() : super(BackendApiClient(baseUrl: 'http://test'));

  BackendSnapshot? nextSnapshot;
  String selectedAutonomyLevel = 'CONFIRM';
  int? approvedProposalId;
  int? rejectedProposalId;
  int? approvedActionSetId;
  int? rejectedActionSetId;

  @override
  Future<BackendSnapshot> load() async => nextSnapshot ?? snapshot();

  @override
  Future<void> approveProposal(int id) async {
    approvedProposalId = id;
  }

  @override
  Future<void> rejectProposal(int id) async {
    rejectedProposalId = id;
  }

  @override
  Future<CoordinatedActionSet> approveActionSet(int id) async {
    approvedActionSetId = id;
    return actionSet(status: 'SUCCEEDED', verificationStatus: 'VERIFIED');
  }

  @override
  Future<CoordinatedActionSet> rejectActionSet(int id) async {
    rejectedActionSetId = id;
    return actionSet(status: 'REJECTED');
  }

  @override
  Future<String> updateAutonomyLevel(String level) async {
    selectedAutonomyLevel = level;
    return level;
  }
}

CoordinatedActionSet actionSet({
  String status = 'PENDING',
  String verificationStatus = 'PENDING',
}) => CoordinatedActionSet(
  id: 8,
  title: '吸收光伏余电',
  reason: 'Smart Meter 检测到约 2300 W 电网反送，可协调储能提升自用率。',
  status: status,
  verificationStatus: verificationStatus,
  expectedGridDeltaW: 2300,
  beforeGridPowerW: status == 'PENDING' ? null : -2300,
  afterGridPowerW: status == 'SUCCEEDED' ? -50 : null,
  actualGridDeltaW: status == 'SUCCEEDED' ? 2250 : null,
  verificationMessage: status == 'SUCCEEDED'
      ? 'Smart Meter 已验证电网反送减少约 2250 W。'
      : null,
  items: [
    const CoordinatedActionItem(
      id: 1,
      sequence: 1,
      deviceName: 'Solarbank 4',
      capability: 'battery_power_direction',
      currentValue: 1,
      targetValue: 0,
      status: 'PENDING',
    ),
    CoordinatedActionItem(
      id: 2,
      sequence: 2,
      deviceName: 'Solarbank 4',
      capability: 'battery_power_setpoint',
      currentValue: 0,
      targetValue: 1200,
      status: status == 'SUCCEEDED' ? 'SUCCEEDED' : 'PENDING',
      resultMessage: status == 'SUCCEEDED' ? '设备写入与状态回读一致。' : null,
    ),
    CoordinatedActionItem(
      id: 3,
      sequence: 3,
      deviceName: 'Solarbank Max AC',
      capability: 'battery_power_setpoint',
      currentValue: 0,
      targetValue: 1100,
      status: status == 'SUCCEEDED' ? 'SUCCEEDED' : 'PENDING',
    ),
  ],
);

BackendSnapshot snapshot({
  bool withPending = false,
  bool withActionSet = false,
  String actionSetStatus = 'PENDING',
}) => BackendSnapshot(
  energy: const EnergyState(
    solarW: 1200,
    homeLoadW: 900,
    chargeW: 300,
    soc: 68,
    batteryStatus: 'charging',
    sourceMode: 'simulator',
  ),
  today: EnergyToday(
    available: true,
    summary: const EnergyTodaySummary(
      generationKwh: 8.4,
      consumptionKwh: 6.7,
      savingsCny: 2.9,
      generationChangePercent: 12,
      consumptionChangePercent: -8,
      savingsChangePercent: 6,
      tariffPricePerKwh: .54,
    ),
    flow: List.generate(
      12,
      (hour) => EnergyFlowPoint(
        time: DateTime(2026, 9, 20, hour),
        hour: hour,
        solarPowerW: hour * 120,
        homeLoadW: 900,
        coveragePercent: 100,
      ),
    ),
    coveragePercent: 100,
  ),
  schedule: EnergySchedule(
    available: true,
    points: List.generate(
      24,
      (hour) => EnergySchedulePoint(
        time: DateTime(2026, 9, 20, hour),
        hour: hour,
        solarPowerW: hour >= 7 && hour <= 18
            ? 3200 * (1 - (hour - 12).abs() / 7).clamp(0, 1)
            : 0,
        loadPowerW: 1800 + (hour >= 18 ? 900 : 0),
        netPowerW: 0,
        action: hour < 7
            ? 'PRESERVE_RESERVE'
            : hour < 17
            ? 'STORE_SURPLUS'
            : 'COVER_DEFICIT',
        confidence: 'MEDIUM',
      ),
    ),
    strategy: 'BACKUP',
    advisoryOnly: true,
    executable: false,
    projectedSolarKwh: 18.4,
    projectedLoadKwh: 15.2,
  ),
  report: EnergyReport(
    available: true,
    tariffPricePerKwh: .54,
    carbonFactorKgPerKwh: .6096,
    carbonProvider: 'MEE_NBS',
    carbonReferenceYear: 2023,
    periods: {
      for (final name in ['today', 'week', 'month'])
        name: EnergyReportPeriod(
          metrics: const EnergyReportMetrics(
            consumptionKwh: 6.7,
            generationKwh: 8.4,
            gridImportKwh: 2.1,
            solarSelfUsePercent: 72,
            referenceBaselineCostCny: 3.62,
            actualGridCostCny: 1.13,
            savingsCny: 2.49,
            savingsPercent: 68.8,
            carbonReductionKg: 2.8,
          ),
          daily: [
            EnergyReportDailyPoint(
              date: DateTime(2026, 9, 20),
              actualGridCostCny: 1.13,
              savingsCny: 2.49,
              carbonReductionKg: 2.8,
            ),
          ],
          coveragePercent: 100,
        ),
    },
  ),
  weather: const WeatherContext(condition: 'partly_cloudy', temperature: 25),
  solar: const ForecastData(method: 'solar-test', points: [], next24h: null),
  load: const ForecastData(method: 'load-test', points: [], next24h: 12),
  strategy: const StrategyState('BACKUP', backupReserveTarget: 35),
  autonomy: AutonomyStatus(
    agentState: withPending ? 'ACTION_REQUIRED' : 'MONITORING',
    enabled: false,
    unreadCount: withPending ? 12 : 0,
    latestDecision: const DecisionSummary(
      strategy: 'BACKUP',
      version: 'v2',
      confidence: 'LOW',
      currentValue: 80,
      targetValue: 80,
      actionRequired: false,
      reasonCode: 'TARGET_ALREADY_SATISFIED',
    ),
    pendingProposal: withPending
        ? const PendingProposal(
            id: 42,
            status: 'PENDING',
            capability: 'backup_reserve',
            currentValue: 80,
            targetValue: 30,
          )
        : null,
  ),
  decisions: const [
    DecisionRun(
      id: 1,
      status: 'COMPLETED',
      strategy: 'BACKUP',
      currentValue: 80,
      targetValue: 80,
      reasonCode: 'TARGET_ALREADY_SATISFIED',
      confidence: 'LOW',
      actionRequired: false,
    ),
  ],
  station: StationSummary(
    available: true,
    online: true,
    dataQuality: 'good',
    coveragePercent: 100,
    deviceId: 1,
    displayName: '家庭能源中心',
    sourceMode: 'simulator',
    observedAt: DateTime(2026, 9, 20, 12),
    nodes: const [
      StationNode(
        key: 'solar',
        label: '光伏',
        available: true,
        direction: 'out',
        powerW: 1200,
      ),
      StationNode(
        key: 'home',
        label: '家庭',
        available: true,
        direction: 'in',
        powerW: 900,
      ),
      StationNode(
        key: 'battery',
        label: '储能',
        available: true,
        direction: 'in',
        powerW: 300,
      ),
      StationNode(
        key: 'grid',
        label: '电网',
        available: true,
        direction: 'idle',
        powerW: 0,
      ),
    ],
  ),
  batteryInsight: const BatteryInsight(
    available: true,
    assumptions: ['备电时长按当前家庭负载估算', '关键负载尚未配置'],
    soc: 68,
    capacityKwh: 10,
    currentEnergyKwh: 6.8,
    reservePercent: 35,
    protectedEnergyKwh: 3.5,
    usableEnergyKwh: 5.8,
    homeLoadW: 900,
    wholeHomeHours: 5.9,
    status: 'Charging',
  ),
  devices: const [
    DiscoveredDevice(
      deviceId: 'solix-test',
      model: 'Anker SOLIX Solarbank 4 E5000 Pro',
      online: true,
      sourceMode: 'simulator',
      firmware: 'SIM-1.0.0',
      deviceType: 'storage',
      topologyRole: 'storage',
      boundDeviceId: 1,
      controlEnabled: true,
      telemetry: [
        DeviceCapability(
          name: 'battery_soc',
          access: 'read',
          available: true,
          value: 68,
          unit: '%',
        ),
        DeviceCapability(
          name: 'device_status',
          access: 'read',
          available: true,
          value: 'Charging',
        ),
      ],
      controls: [
        DeviceCapability(
          name: 'backup_reserve',
          access: 'read_write',
          available: true,
          value: 35,
          unit: '%',
          verified: true,
          verificationStatus: 'verified',
          verificationMethod: 'home_assistant_state_readback',
          verificationNote: '已完成 Home Assistant 写入与状态回读验证',
          readbackReliable: true,
        ),
      ],
    ),
  ],
  profiles: const [
    DeviceProfile(
      id: 'solix_storage',
      name: 'Anker SOLIX 储能系统',
      deviceType: 'storage',
      telemetry: ['battery_soc'],
      controls: ['backup_reserve'],
      verifiedControls: ['backup_reserve'],
    ),
    DeviceProfile(
      id: 'smart_plug_gen_2',
      name: 'Anker SOLIX Smart Plug Gen 2',
      deviceType: 'smart_plug',
      telemetry: ['real_time_power'],
      controls: ['power_switch'],
      verifiedControls: [],
    ),
    DeviceProfile(
      id: 'smart_meter_gen_2',
      name: 'Anker SOLIX Smart Meter Gen 2',
      deviceType: 'smart_meter',
      telemetry: ['primary_total_active_power'],
      controls: [],
      verifiedControls: [],
    ),
  ],
  areaLoads: const AreaLoadView(
    available: true,
    totalPowerW: 900,
    areas: [
      AreaLoad(
        id: 'living_room',
        name: '客厅',
        totalPowerW: 900,
        entities: [
          AreaLoadEntity(
            entityId: 'sensor.living_room_power',
            name: '客厅负载',
            available: true,
            includedInTotal: true,
            powerW: 900,
          ),
        ],
      ),
    ],
    unassigned: [],
  ),
  actionSet: withActionSet
      ? actionSet(
          status: actionSetStatus,
          verificationStatus: actionSetStatus == 'SUCCEEDED'
              ? 'VERIFIED'
              : 'PENDING',
        )
      : null,
);

Future<void> pumpAt(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    GuangHengApp(enableInteractive3d: false, initialData: snapshot()),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [360.0, 390.0, 430.0]) {
    testWidgets('responsive real-data pages at ${width.toInt()}dp', (
      tester,
    ) async {
      await pumpAt(tester, width);
      expect(find.text('光伏'), findsOneWidget);
      expect(find.text('运行中'), findsOneWidget);
      await tester.tap(find.text('策略'));
      await tester.pumpAndSettle();
      expect(find.text('备电优先'), findsWidgets);
      expect(find.text('当前策略'), findsOneWidget);
      expect(find.text('24 小时计划'), findsOneWidget);
      expect(find.text('今日调度'), findsOneWidget);
      expect(find.text('备用电量 35%'), findsOneWidget);
      expect(find.text('电池充电'), findsOneWidget);
      expect(find.text('光伏供电'), findsOneWidget);
      expect(find.text('电池放电'), findsOneWidget);
      expect(find.text('备用时段'), findsOneWidget);
      final scheduleBar = find.byKey(const Key('schedule-segment-bar'));
      expect(scheduleBar, findsOneWidget);
      expect(tester.getSize(scheduleBar).height, 32);
      await tester.drag(find.byType(ListView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(find.text('确认模式'), findsWidgets);
      await tester.tap(find.text('报表'));
      await tester.pumpAndSettle();
      expect(find.text('参考基线 vs 实际购电'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      final savingChart = find.byKey(const Key('saving-trend-chart'));
      expect(savingChart, findsOneWidget);
      expect(tester.getSize(savingChart).height, 184);
      expect(find.text('相比参考基线，本期节省 69%'), findsOneWidget);
      expect(find.text('预计减少约 2.80 kg 碳排放'), findsOneWidget);
      expect(find.text('光衡完成能源分析'), findsOneWidget);
      await tester.tap(find.text('设备'));
      await tester.pumpAndSettle();
      expect(find.text('Anker SOLIX Solarbank 4 E5000 Pro'), findsOneWidget);
      expect(find.text('1 台设备 · 1 台在线 · 1 项控制已验证'), findsOneWidget);
      expect(find.text('1 个区域'), findsOneWidget);
      expect(find.text('3 类设备'), findsOneWidget);
      final loadTile = find.byKey(const Key('platform-tile-家庭负载'));
      final profileTile = find.byKey(const Key('platform-tile-设备能力档案'));
      expect(tester.getSize(loadTile), tester.getSize(profileTile));
      expect(tester.getSize(loadTile).height, 108);
      await tester.tap(find.text('家庭负载'));
      await tester.pumpAndSettle();
      expect(find.text('空间用电'), findsOneWidget);
      expect(find.text('客厅'), findsOneWidget);
    });
  }

  testWidgets('autonomy level persists and full access requires confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final repository = TestBackendRepository();
    await tester.pumpWidget(
      GuangHengApp(
        enableInteractive3d: false,
        initialData: snapshot(),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('策略').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('观察模式'));
    await tester.pumpAndSettle();

    expect(repository.selectedAutonomyLevel, 'OBSERVE');
    expect(find.text('当前'), findsOneWidget);
    expect(find.text('已切换到观察模式'), findsOneWidget);

    await tester.tap(find.text('完全访问'));
    await tester.pumpAndSettle();
    expect(find.text('开启完全访问？'), findsOneWidget);
    expect(find.text('安全检查、设备在线检查、能力校验和执行回读仍然有效。'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(repository.selectedAutonomyLevel, 'OBSERVE');

    await tester.tap(find.text('完全访问'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开启完全访问'));
    await tester.pumpAndSettle();
    expect(repository.selectedAutonomyLevel, 'AUTO');
    expect(find.text('完全访问'), findsWidgets);
  });

  testWidgets('pending proposal actions work without narrow-screen overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final repository = TestBackendRepository();
    await tester.pumpWidget(
      GuangHengApp(
        enableInteractive3d: false,
        initialData: snapshot(withPending: true),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('策略'));
    await tester.pumpAndSettle();
    expect(find.text('暂不执行'), findsOneWidget);
    expect(find.text('确认执行'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('确认执行'));
    await tester.pumpAndSettle();
    expect(find.text('确认备电调整'), findsOneWidget);
    await tester.tap(find.text('确认执行').last);
    await tester.pumpAndSettle();
    expect(repository.approvedProposalId, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completed Smart Meter result does not hide a pending strategy proposal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        GuangHengApp(
          enableInteractive3d: false,
          initialData: snapshot(
            withPending: true,
            withActionSet: true,
            actionSetStatus: 'SUCCEEDED',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('允许执行'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('最近一次执行验证'), findsOneWidget);

      await tester.tap(find.text('策略').last);
      await tester.pumpAndSettle();
      expect(find.text('确认执行'), findsOneWidget);
      expect(find.text('最近一次执行验证'), findsOneWidget);
      expect(find.text('Smart Meter 已验证电网反送减少约 2250 W。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'coordinated action set uses one approval and fits a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final repository = TestBackendRepository();
      repository.nextSnapshot = snapshot(withActionSet: true);
      await tester.pumpWidget(
        GuangHengApp(
          enableInteractive3d: false,
          initialData: snapshot(withActionSet: true),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('策略').last);
      await tester.pumpAndSettle();
      expect(find.text('跨设备协同建议'), findsOneWidget);
      await tester.tap(find.text('跨设备协同建议'));
      await tester.pumpAndSettle();
      expect(find.text('执行步骤'), findsOneWidget);
      expect(find.text('Solarbank 4'), findsWidgets);
      expect(find.text('Solarbank Max AC'), findsOneWidget);
      expect(find.text('确认全部步骤'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('确认全部步骤'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认全部步骤'));
      await tester.pumpAndSettle();
      expect(repository.approvedActionSetId, 8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'device control shows real value and Chinese verification state',
    (tester) async {
      final repository = TestBackendRepository();
      final viewModel = BackendViewModel(repository, data: snapshot());
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: MaterialApp(
            home: DeviceDetailPage(device: snapshot().devices.first),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('储能控制中心'), findsOneWidget);
      expect(find.text('充电中'), findsOneWidget);
      expect(find.text('已完成 Home Assistant 写入与状态回读验证'), findsWidgets);
      expect(find.text('35%'), findsWidgets);
    },
  );

  testWidgets('Smart Meter real-time fields and values use Chinese labels', (
    tester,
  ) async {
    const meter = DiscoveredDevice(
      deviceId: 'meter-test',
      model: 'Anker SOLIX Smart Meter Gen 2',
      online: true,
      sourceMode: 'simulator',
      deviceType: 'smart_meter',
      topologyRole: 'meter',
      telemetry: [
        DeviceCapability(
          name: 'meter_type',
          access: 'read',
          available: true,
          value: 'three_phase',
        ),
        DeviceCapability(
          name: 'primary_total_active_power',
          access: 'read',
          available: true,
          value: -2300,
          unit: 'W',
        ),
        DeviceCapability(
          name: 'primary_phase_1_current',
          access: 'read',
          available: true,
          value: 3.4,
          unit: 'A',
        ),
      ],
      controls: [],
    );
    final repository = TestBackendRepository();
    final viewModel = BackendViewModel(repository, data: snapshot());
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: DeviceDetailPage(device: meter)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anker SOLIX Smart Meter Gen 2'), findsWidgets);
    expect(find.text('电表类型'), findsOneWidget);
    expect(find.text('三相'), findsOneWidget);
    expect(find.text('主回路总有功功率'), findsOneWidget);
    expect(find.text('主回路一相电流'), findsOneWidget);
    expect(find.text('meter_type'), findsNothing);
    expect(find.text('three_phase'), findsNothing);
    expect(find.text('primary_total_active_power'), findsNothing);
  });

  testWidgets('Smart Plug real-time fields use Chinese labels', (tester) async {
    const plug = DiscoveredDevice(
      deviceId: 'plug-test',
      model: 'Anker SOLIX Smart Plug Gen 2',
      online: true,
      sourceMode: 'simulator',
      deviceType: 'smart_plug',
      topologyRole: 'controllable_load',
      telemetry: [
        DeviceCapability(
          name: 'real_time_power',
          access: 'read',
          available: true,
          value: 800,
          unit: 'W',
        ),
        DeviceCapability(
          name: 'cumulative_energy',
          access: 'read',
          available: true,
          value: 54.2,
          unit: 'kWh',
        ),
        DeviceCapability(
          name: 'switch_status',
          access: 'read',
          available: true,
          value: 'connected',
        ),
      ],
      controls: [],
    );
    final repository = TestBackendRepository();
    final viewModel = BackendViewModel(repository, data: snapshot());
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: DeviceDetailPage(device: plug)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anker SOLIX Smart Plug Gen 2'), findsWidgets);
    expect(find.text('实时功率'), findsOneWidget);
    expect(find.text('累计用电量'), findsOneWidget);
    expect(find.text('插座状态'), findsOneWidget);
    expect(find.text('已连接'), findsOneWidget);
    expect(find.text('real_time_power'), findsNothing);
    expect(find.text('connected'), findsNothing);
  });

  testWidgets(
    'critical load sheet survives keyboard resize and route dismiss',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final repository = TestBackendRepository();
      final viewModel = BackendViewModel(repository, data: snapshot());
      addTearDown(viewModel.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: const MaterialApp(home: CriticalLoadPage()),
        ),
      );
      await tester.tap(find.text('添加'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '设备名称'), '冰箱');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('保存关键负载'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('report calendar uses consistent Chinese localization', (
    tester,
  ) async {
    await pumpAt(tester, 390);
    await tester.tap(find.text('报表'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('年'), findsWidgets);
    expect(find.text('周日'), findsOneWidget);
    expect(find.text('September 2026'), findsNothing);
  });
}
