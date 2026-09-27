import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../viewmodels/backend_view_model.dart';
import '../shared/motion_widgets.dart';
import '../shared/real_data_widgets.dart';

class StationOverviewPage extends StatelessWidget {
  const StationOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BackendViewModel>().data;
    final station = data?.station;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _DetailHeader(
              title: '电站总览',
              subtitle: station?.displayName ?? '家庭能源中心',
            ),
            const SizedBox(height: 18),
            StaggeredReveal(child: _StationTopology(station: station)),
            const SizedBox(height: 20),
            const _Title('今日表现', '数据由服务器持续采样，不依赖手机保持打开'),
            const SizedBox(height: 12),
            _MetricGrid(today: data?.today),
            const SizedBox(height: 20),
            const _Title('数据可信度', '缺失值不会被静默替换为 0'),
            const SizedBox(height: 12),
            _QualityCard(station: station),
          ],
        ),
      ),
    );
  }
}

class BatteryDetailPage extends StatelessWidget {
  const BatteryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BackendViewModel>().data;
    final insight = data?.batteryInsight;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            const _DetailHeader(title: '储能详情', subtitle: '容量、保护边界与备电能力'),
            const SizedBox(height: 18),
            StaggeredReveal(child: _BatteryHero(insight: insight)),
            const SizedBox(height: 20),
            const _Title('能量分层', '区分当前电量、保护电量与可用电量'),
            const SizedBox(height: 12),
            _BatteryMetrics(insight: insight),
            const SizedBox(height: 20),
            _CriticalLoadEntry(insight: insight, config: data?.criticalLoads),
            const SizedBox(height: 20),
            const _Title('估算依据', '结果带假设，不制造虚假的精确感'),
            const SizedBox(height: 12),
            _AssumptionCard(insight: insight),
          ],
        ),
      ),
    );
  }
}

class EnergyNodeDetailPage extends StatelessWidget {
  const EnergyNodeDetailPage({super.key, required this.nodeKey});
  final String nodeKey;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<BackendViewModel>().data;
    final node = data?.station?.node(nodeKey);
    final meta = _nodeMeta(nodeKey);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _DetailHeader(title: meta.$1, subtitle: meta.$2),
            const SizedBox(height: 18),
            StaggeredReveal(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [meta.$4.withValues(alpha: .14), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: meta.$4.withValues(alpha: .2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(meta.$3, size: 34, color: meta.$4),
                    const SizedBox(height: 20),
                    Text(
                      _power(node?.powerW),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node?.available == true
                          ? _direction(node!.direction)
                          : '当前数据不可用',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _Title('今日数据', '来自服务端历史聚合'),
            const SizedBox(height: 12),
            _NodeHistory(nodeKey: nodeKey, today: data?.today),
          ],
        ),
      ),
    );
  }
}

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({super.key, required this.device});
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final current =
        vm.data?.devices.cast<DiscoveredDevice?>().firstWhere(
          (item) => item?.deviceId == device.deviceId,
          orElse: () => device,
        ) ??
        device;
    final meter = vm.data?.meterInsights[current.deviceId];
    final solarArray = vm.data?.solarArrays[current.deviceId];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _DetailHeader(title: '设备详情', subtitle: current.model),
            const SizedBox(height: 18),
            _DeviceIdentity(device: current),
            if (current.deviceType == 'storage') ...[
              const SizedBox(height: 20),
              _SolarArrayEntry(device: current, insight: solarArray),
              const SizedBox(height: 20),
              _StorageControlPanel(device: current),
            ],
            if (current.deviceType == 'smart_plug') ...[
              const SizedBox(height: 20),
              _SmartPlugControl(device: current),
            ],
            if (current.deviceType == 'smart_meter') ...[
              const SizedBox(height: 20),
              _MeterEntry(device: current, insight: meter),
            ],
            const SizedBox(height: 20),
            const _Title('实时数据', '不可用的字段不会显示为 0'),
            const SizedBox(height: 12),
            ...current.telemetry.map((item) => _CapabilityRow(item: item)),
            if (current.controls.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _Title('控制能力', '只有已验证能力才可进入安全执行链'),
              const SizedBox(height: 12),
              ...current.controls.map(
                (item) => _CapabilityRow(item: item, control: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SolarArrayPage extends StatelessWidget {
  const SolarArrayPage({super.key, required this.device});
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    final insight = context
        .watch<BackendViewModel>()
        .data
        ?.solarArrays[device.deviceId];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _DetailHeader(title: '光伏阵列', subtitle: device.model),
            const SizedBox(height: 18),
            StaggeredReveal(child: _SolarArrayHero(insight: insight)),
            const SizedBox(height: 20),
            const _Title('光伏输入通道', '按官方集成实际暴露的通道展示'),
            const SizedBox(height: 12),
            if (insight?.channelsAvailable == true)
              ...insight!.channels.indexed.map(
                (entry) => StaggeredReveal(
                  order: entry.$1,
                  child: _SolarInputCard(channel: entry.$2),
                ),
              )
            else
              const _SolarDataBoundary(kind: '光伏输入通道'),
            const SizedBox(height: 20),
            const _Title('组件级视图', '有独立组件实体时自动呈现，不拆分或估算总功率'),
            const SizedBox(height: 12),
            if (insight?.componentsAvailable == true)
              ...insight!.components.map(
                (item) => _SolarComponentCard(item: item),
              )
            else
              const _SolarDataBoundary(kind: '组件'),
          ],
        ),
      ),
    );
  }
}

class _SolarArrayEntry extends StatelessWidget {
  const _SolarArrayEntry({required this.device, required this.insight});
  final DiscoveredDevice device;
  final SolarArrayInsight? insight;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SolarArrayPage(device: device))),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5DF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.solarOrange.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.solarOrangeSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.solar_power_rounded,
              color: AppColors.solarOrange,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '光伏与输入通道',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  insight?.aggregatePowerW == null
                      ? '光伏数据暂不可用'
                      : '${(insight!.aggregatePowerW! / 1000).toStringAsFixed(2)} kW · ${insight!.channelsAvailable ? '${insight!.channels.length} 路光伏输入' : '聚合数据'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.navInactive),
        ],
      ),
    ),
  );
}

class _StorageControlPanel extends StatelessWidget {
  const _StorageControlPanel({required this.device});
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final busy =
        device.boundDeviceId != null &&
        vm.busyDevices.contains('bound:${device.boundDeviceId}');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '储能控制中心',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(
                Icons.verified_user_outlined,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            device.boundDeviceId == null
                ? '接入后可使用方案、审批、安全检查与回读验证链'
                : !device.controlEnabled
                ? '控制权限关闭，当前保持只读'
                : '仅已完成实机验证的能力可执行',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          if (device.boundDeviceId == null)
            FilledButton.icon(
              onPressed: busy ? null : () => _bind(context),
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('接入此设备'),
            )
          else if (!device.controlEnabled)
            FilledButton.icon(
              onPressed: busy ? null : () => _enable(context),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('开启控制权限'),
            )
          else
            ...device.controls.map(
              (item) => _StorageControlTile(
                device: device,
                capability: item,
                busy: busy,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _bind(BuildContext context) async {
    final ok = await context.read<BackendViewModel>().bindDevice(
      device.deviceId,
    );
    if (context.mounted) {
      _SmartPlugControl._result(context, ok, ok ? '设备已接入，控制权限保持关闭' : null);
    }
  }

  Future<void> _enable(BuildContext context) async {
    final confirmed = await _SmartPlugControl._confirm(
      context,
      title: '开启储能控制权限？',
      message: '开启后也不会直接写设备。每次操作仍需创建方案并通过在线状态、能力验证、范围、审批和回读检查。',
      action: '开启权限',
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<BackendViewModel>().setDeviceControlEnabled(
      device.boundDeviceId!,
      true,
    );
    if (context.mounted) {
      _SmartPlugControl._result(context, ok, ok ? '储能控制权限已开启' : null);
    }
  }
}

class _StorageControlTile extends StatelessWidget {
  const _StorageControlTile({
    required this.device,
    required this.capability,
    required this.busy,
  });
  final DiscoveredDevice device;
  final DeviceCapability capability;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final enabled = capability.available && capability.verified == true;
    return PressableScale(
      onTap: enabled && !busy ? () => _edit(context) : null,
      child: Container(
        margin: const EdgeInsets.only(top: 9),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryBlueSoft : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.tune_rounded : Icons.lock_outline_rounded,
              color: enabled ? AppColors.primaryBlue : AppColors.navInactive,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capabilityLabel(capability.name),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    enabled
                        ? '实时值 · 已完成实机回读验证，点击调整'
                        : _controlVerificationText(capability),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _capabilityValue(capability),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (enabled) const Icon(Icons.chevron_right_rounded, size: 19),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final min = capability.min ?? 0;
    final max = capability.max ?? 100;
    final current =
        (capability.value as num?)?.toDouble().clamp(min, max) ?? min;
    final target = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StorageValueSheet(capability: capability, initial: current),
    );
    if (target == null || !context.mounted) return;
    final confirmed = await _SmartPlugControl._confirm(
      context,
      title: '确认调整${_capabilityLabel(capability.name)}？',
      message:
          '将从 ${capability.value}${capability.unit ?? ''} 调整为 ${target.toStringAsFixed(target == target.roundToDouble() ? 0 : 1)}${capability.unit ?? ''}。确认后创建方案并立即进入审批与安全执行链。',
      action: '确认执行',
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<BackendViewModel>().setStorageControl(
      device,
      capability,
      target,
    );
    if (context.mounted) {
      _SmartPlugControl._result(context, ok, ok ? '设备状态已通过回读验证' : null);
    }
  }
}

class _StorageValueSheet extends StatefulWidget {
  const _StorageValueSheet({required this.capability, required this.initial});
  final DeviceCapability capability;
  final double initial;
  @override
  State<_StorageValueSheet> createState() => _StorageValueSheetState();
}

class _StorageValueSheetState extends State<_StorageValueSheet> {
  late double value = widget.initial;
  @override
  Widget build(BuildContext context) {
    final min = widget.capability.min ?? 0;
    final max = widget.capability.max ?? 100;
    final divisions = ((max - min) / (widget.capability.step ?? 1))
        .round()
        .clamp(1, 200);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _capabilityLabel(widget.capability.name),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '设置目标值后仍需经过审批、安全检查与设备回读',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}${widget.capability.unit ?? ''}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            Slider.adaptive(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (next) => setState(() => value = next),
            ),
            Row(children: [Text('$min'), const Spacer(), Text('$max')]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, value),
                child: const Text('使用此目标值'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolarArrayHero extends StatelessWidget {
  const _SolarArrayHero({required this.insight});
  final SolarArrayInsight? insight;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFB632), Color(0xFFFF8B2C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33FF9C24),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.solar_power_rounded, color: Colors.white, size: 46),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight?.aggregatePowerW == null
                    ? '--'
                    : '${(insight!.aggregatePowerW! / 1000).toStringAsFixed(2)} kW',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                insight?.deviceOnline == true ? '设备在线 · 光伏聚合功率' : '设备离线或数据不可用',
                style: const TextStyle(color: Color(0xFFFFF2D4), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SolarInputCard extends StatelessWidget {
  const _SolarInputCard({required this.channel});
  final SolarInputChannel channel;
  @override
  Widget build(BuildContext context) => _SolarMetricCard(
    title: channel.label,
    primary: channel.powerW == null
        ? '--'
        : '${channel.powerW!.toStringAsFixed(0)} W',
    secondary:
        '${channel.voltageV?.toStringAsFixed(1) ?? '--'} V · ${channel.currentA?.toStringAsFixed(2) ?? '--'} A',
  );
}

class _SolarComponentCard extends StatelessWidget {
  const _SolarComponentCard({required this.item});
  final SolarComponent item;
  @override
  Widget build(BuildContext context) => _SolarMetricCard(
    title: item.label,
    primary: item.powerW == null
        ? '--'
        : '${item.powerW!.toStringAsFixed(0)} W',
    secondary: item.energyKwh == null
        ? '累计电量未提供'
        : '${item.energyKwh!.toStringAsFixed(2)} kWh',
  );
}

class _SolarMetricCard extends StatelessWidget {
  const _SolarMetricCard({
    required this.title,
    required this.primary,
    required this.secondary,
  });
  final String title, primary, secondary;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(Icons.electric_bolt_rounded, color: AppColors.solarOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                secondary,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(primary, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _SolarDataBoundary extends StatelessWidget {
  const _SolarDataBoundary({required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.warningSoft,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '当前 Anker SOLIX 官方集成未暴露独立$kind实体。这里保留真实数据边界；后续实体出现时会自动展示，不会用总功率伪造分路数据。',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class AreaLoadPage extends StatelessWidget {
  const AreaLoadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.watch<BackendViewModel>().data?.areaLoads;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            const _DetailHeader(
              title: '家庭负载',
              subtitle: '按 Home Assistant Area 定位耗电来源',
            ),
            const SizedBox(height: 18),
            _AreaHero(view: view),
            const SizedBox(height: 20),
            const _Title('空间用电', '功率来自本次 HA 实时状态，不在手机本地累计'),
            const SizedBox(height: 12),
            if (view == null || !view.available || view.areas.isEmpty)
              _AreaEmpty(diagnostic: view?.diagnostic)
            else
              ...view.areas.indexed.map(
                (entry) => StaggeredReveal(
                  order: entry.$1,
                  child: _AreaCard(area: entry.$2),
                ),
              ),
            if (view?.unassigned.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              const _Title('未分配实体', '在 Home Assistant 中分配 Area 后会自动归位'),
              const SizedBox(height: 10),
              _UnassignedCard(entities: view!.unassigned),
            ],
          ],
        ),
      ),
    );
  }
}

class SmartMeterPage extends StatelessWidget {
  const SmartMeterPage({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final insight = context
        .watch<BackendViewModel>()
        .data
        ?.meterInsights[deviceId];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            _DetailHeader(
              title: '电表计量',
              subtitle: insight?.model ?? 'Smart Meter Gen 2',
            ),
            const SizedBox(height: 18),
            _MeterHero(insight: insight),
            const SizedBox(height: 20),
            const _Title('CT 通道', '分别查看总功率、功率因数和三相测量'),
            const SizedBox(height: 12),
            if (insight == null || insight.channels.isEmpty)
              _AreaEmpty(diagnostic: insight?.diagnostic)
            else
              ...insight.channels.map(
                (channel) => _MeterChannelCard(channel: channel),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileCatalogPage extends StatelessWidget {
  const ProfileCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles =
        context.watch<BackendViewModel>().data?.profiles ??
        const <DeviceProfile>[];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            const _DetailHeader(
              title: '设备能力档案',
              subtitle: '能力按设备型号动态匹配，不绑定固定 Entity ID',
            ),
            const SizedBox(height: 18),
            ...profiles.indexed.map(
              (entry) => StaggeredReveal(
                order: entry.$1,
                child: _ProfileCard(profile: entry.$2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final DeviceProfile profile;
  @override
  Widget build(BuildContext context) {
    final pending = profile.supportStatus.contains('coming_soon');
    final needsHardware = profile.supportStatus.contains(
      'hardware_verification',
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (pending ? AppColors.navInactive : AppColors.primaryGreen)
                  .withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              profile.deviceType == 'smart_meter'
                  ? Icons.electric_meter_outlined
                  : profile.deviceType == 'smart_plug'
                  ? Icons.power_rounded
                  : Icons.battery_charging_full_rounded,
              color: pending ? AppColors.navInactive : AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  pending
                      ? '官方集成尚未开放'
                      : needsHardware
                      ? '已适配 · 控制等待实机验证'
                      : '已适配',
                  style: TextStyle(
                    color: pending
                        ? AppColors.textSecondary
                        : AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${profile.telemetry.length} 项观测 · ${profile.controls.length} 项控制'
                  '${profile.firmwareRequirement == null ? '' : ' · 固件 ${profile.firmwareRequirement}'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartPlugControl extends StatelessWidget {
  const _SmartPlugControl({required this.device});
  final DiscoveredDevice device;

  DeviceCapability? get control => device.controls
      .cast<DeviceCapability?>()
      .firstWhere((item) => item?.name == 'power_switch', orElse: () => null);

  bool get isOn {
    final value = '${control?.value ?? ''}'.toLowerCase();
    return {'on', 'connected', 'enabled', 'true', '1'}.contains(value);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final busy =
        vm.busyDevices.contains(device.deviceId) ||
        (device.boundDeviceId != null &&
            vm.busyDevices.contains('bound:${device.boundDeviceId}'));
    final capability = control;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102B4D), Color(0xFF1A5275)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26112F52),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.power_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '负载控制',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '方案、审批、安全检查与回读验证',
                      style: TextStyle(color: Color(0xFFBBD0E4), fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (device.boundDeviceId != null &&
                  device.controlEnabled &&
                  capability?.verified == true)
                Switch.adaptive(
                  value: isOn,
                  activeTrackColor: AppColors.primaryGreen,
                  onChanged: busy
                      ? null
                      : (value) => _requestSwitch(context, value),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (device.boundDeviceId == null)
            _ControlAction(
              label: busy ? '正在接入…' : '接入设备',
              detail: '先建立本地权限记录，不会立即控制设备',
              onTap: busy ? null : () => _bind(context),
            )
          else if (!device.controlEnabled)
            _ControlAction(
              label: busy ? '正在更新…' : '开启控制权限',
              detail: '开启后仍需逐次确认，不能绕过安全检查',
              onTap: busy ? null : () => _enableControl(context),
            )
          else if (capability?.verified != true)
            const _ControlAction(
              label: '等待实机验证',
              detail: '当前设备能力档案保持只读；完成开关与状态回读验证后才能开放',
            )
          else
            Text(
              isOn ? '插座当前已开启' : '插座当前已关闭',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _bind(BuildContext context) async {
    final ok = await context.read<BackendViewModel>().bindDevice(
      device.deviceId,
    );
    if (context.mounted) _result(context, ok, ok ? '设备已接入，控制权限保持关闭' : null);
  }

  Future<void> _enableControl(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: '开启设备控制权限？',
      message: '仅允许该设备进入受控执行链。每次开关仍需你的确认，并执行在线、能力、审批与回读检查。',
      action: '开启权限',
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<BackendViewModel>().setDeviceControlEnabled(
      device.boundDeviceId!,
      true,
    );
    if (context.mounted) _result(context, ok, ok ? '控制权限已开启' : null);
  }

  Future<void> _requestSwitch(BuildContext context, bool value) async {
    final confirmed = await _confirm(
      context,
      title: value ? '开启智能插座？' : '关闭智能插座？',
      message: '系统将创建一条待审批方案。确认后才会执行，并以 Home Assistant 状态回读作为成功依据。',
      action: value ? '确认开启' : '确认关闭',
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<BackendViewModel>().setSmartPlugPower(
      device.boundDeviceId!,
      value,
    );
    if (context.mounted) _result(context, ok, ok ? '设备状态已通过回读验证' : null);
  }

  static Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.verified_user_outlined,
        color: AppColors.primaryBlue,
      ),
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );

  static void _result(BuildContext context, bool ok, String? success) {
    final vm = context.read<BackendViewModel>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? (success ?? '操作完成') : (vm.error ?? '操作失败'))),
    );
  }
}

class _ControlAction extends StatelessWidget {
  const _ControlAction({required this.label, required this.detail, this.onTap});
  final String label, detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFBBD0E4),
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      if (onTap != null)
        IconButton.filled(
          onPressed: onTap,
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          icon: const Icon(
            Icons.arrow_forward_rounded,
            color: Color(0xFF173D61),
          ),
        ),
    ],
  );
}

class _MeterEntry extends StatelessWidget {
  const _MeterEntry({required this.device, required this.insight});
  final DiscoveredDevice device;
  final SmartMeterInsight? insight;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartMeterPage(deviceId: device.deviceId),
      ),
    ),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.electric_meter_outlined,
            color: AppColors.primaryBlue,
            size: 30,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '查看分项计量',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${insight?.channels.length ?? 0} 个 CT 通道 · 三相功率、电流与电压',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

class _AreaHero extends StatelessWidget {
  const _AreaHero({required this.view});
  final AreaLoadView? view;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF112D50), Color(0xFF2470A3)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        const Icon(Icons.home_work_outlined, color: Colors.white, size: 36),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                view?.available == true
                    ? '${(view!.totalPowerW / 1000).toStringAsFixed(2)} kW'
                    : '--',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                view?.available == true
                    ? '${view!.areas.length} 个空间正在参与统计'
                    : 'Home Assistant 区域数据暂不可用',
                style: const TextStyle(color: Color(0xFFBCD2E7), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});
  final AreaLoad area;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: ExpansionTile(
      shape: const Border(),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.room_preferences_outlined,
          color: AppColors.primaryGreen,
        ),
      ),
      title: Text(
        area.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${area.entities.length} 个功率实体',
        style: const TextStyle(fontSize: 10),
      ),
      trailing: Text(
        '${area.totalPowerW.toStringAsFixed(0)} W',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
        ),
      ),
      children: area.entities
          .map(
            (entity) => ListTile(
              dense: true,
              title: Text(
                entity.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(entity.includedInTotal ? '计入区域总功率' : '诊断数据，不重复计入'),
              trailing: Text(
                entity.powerW == null
                    ? '--'
                    : '${entity.powerW!.toStringAsFixed(0)} W',
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _UnassignedCard extends StatelessWidget {
  const _UnassignedCard({required this.entities});
  final List<AreaLoadEntity> entities;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Text(
      '${entities.length} 个功率实体尚未分配空间。请在 HA 设备或实体设置中选择 Area。',
      style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
    ),
  );
}

class _AreaEmpty extends StatelessWidget {
  const _AreaEmpty({this.diagnostic});
  final String? diagnostic;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.space_dashboard_outlined,
          color: AppColors.navInactive,
          size: 38,
        ),
        const SizedBox(height: 10),
        const Text('暂无可展示的数据', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          diagnostic ?? '请检查设备在线状态和 Home Assistant 区域分配。',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _MeterHero extends StatelessWidget {
  const _MeterHero({required this.insight});
  final SmartMeterInsight? insight;
  @override
  Widget build(BuildContext context) {
    final power = insight?.channels.fold<double>(
      0,
      (sum, channel) => sum + (channel.activePowerW ?? 0),
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D314D), Color(0xFF176B77)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.electric_meter_outlined,
            color: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  power == null ? '--' : '${power.toStringAsFixed(0)} W',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  insight?.online == true ? '实时计量在线' : '计量数据不可用',
                  style: const TextStyle(
                    color: Color(0xFFBDE0E2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterChannelCard extends StatelessWidget {
  const _MeterChannelCard({required this.channel});
  final MeterChannel channel;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              channel.channel == 'primary' ? '主 CT 通道' : '副 CT 通道',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              channel.activePowerW == null
                  ? '--'
                  : '${channel.activePowerW!.toStringAsFixed(0)} W',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '功率因数 ${channel.powerFactor?.toStringAsFixed(3) ?? '--'} · 正向 ${channel.forwardEnergyKwh?.toStringAsFixed(1) ?? '--'} kWh · 反向 ${channel.reverseEnergyKwh?.toStringAsFixed(1) ?? '--'} kWh',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 14),
        ...channel.phases.map(
          (phase) => Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Text(
                  'L${phase.phase}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('${phase.powerW?.toStringAsFixed(0) ?? '--'} W'),
                const SizedBox(width: 14),
                Text(
                  '${phase.currentA?.toStringAsFixed(2) ?? '--'} A',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 14),
                Text(
                  '${phase.voltageV?.toStringAsFixed(1) ?? '--'} V',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class SystemHealthPage extends StatelessWidget {
  const SystemHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<BackendViewModel>().data?.health;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            const _DetailHeader(title: '健康诊断', subtitle: '连接、数据、能力与控制安全'),
            const SizedBox(height: 18),
            _HealthHero(health: health),
            const SizedBox(height: 20),
            const _Title('检查结果', '阻断项必须恢复后才能执行控制'),
            const SizedBox(height: 12),
            ...(health?.checks ?? const <HealthCheck>[]).map(
              (check) => _HealthCheckCard(check: check),
            ),
            const SizedBox(height: 16),
            const _Title('恢复建议', '按顺序排查，不修改安全检查阈值'),
            const SizedBox(height: 12),
            _RecoveryCard(actions: health?.recoveryActions ?? const []),
          ],
        ),
      ),
    );
  }
}

class CriticalLoadPage extends StatefulWidget {
  const CriticalLoadPage({super.key});

  @override
  State<CriticalLoadPage> createState() => _CriticalLoadPageState();
}

class _CriticalLoadPageState extends State<CriticalLoadPage> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final config = vm.data?.criticalLoads;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            const _DetailHeader(title: '关键负载', subtitle: '只使用你确认的设备和额定功率'),
            const SizedBox(height: 18),
            _CriticalSummary(config: config),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: _Title('负载清单', '启用项参与备电时长计算')),
                FilledButton.icon(
                  onPressed: () => _showAddLoad(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (config == null || config.loads.isEmpty)
              const _EmptyCriticalLoads()
            else
              ...config.loads.map(
                (load) => _CriticalLoadTile(
                  load: load,
                  onChanged: (value) =>
                      vm.setCriticalLoadEnabled(load.id, value),
                  onDelete: () => vm.deleteCriticalLoad(load.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLoad(BuildContext context) async {
    final draft = await showModalBottomSheet<_CriticalLoadDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _AddCriticalLoadSheet(),
    );
    if (draft != null && context.mounted) {
      await context.read<BackendViewModel>().addCriticalLoad(
        draft.name,
        draft.category,
        draft.ratedPowerW,
      );
    }
  }
}

class _CriticalLoadDraft {
  const _CriticalLoadDraft(this.name, this.category, this.ratedPowerW);
  final String name, category;
  final double ratedPowerW;
}

class _AddCriticalLoadSheet extends StatefulWidget {
  const _AddCriticalLoadSheet();

  @override
  State<_AddCriticalLoadSheet> createState() => _AddCriticalLoadSheetState();
}

class _AddCriticalLoadSheetState extends State<_AddCriticalLoadSheet> {
  final name = TextEditingController();
  final power = TextEditingController();
  String category = 'appliance';

  @override
  void dispose() {
    name.dispose();
    power.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = math.min(
      media.viewInsets.bottom,
      media.size.height * .55,
    );
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '添加关键负载',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              '功率必须来自设备铭牌、智能插座或你的实际测量。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '设备名称',
                hintText: '例如：冰箱',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: '类型'),
              items: const [
                DropdownMenuItem(value: 'appliance', child: Text('家用电器')),
                DropdownMenuItem(value: 'network', child: Text('网络通信')),
                DropdownMenuItem(value: 'lighting', child: Text('照明')),
                DropdownMenuItem(value: 'medical', child: Text('医疗设备')),
                DropdownMenuItem(value: 'security', child: Text('安防设备')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (value) =>
                  setState(() => category = value ?? category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: power,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '额定功率',
                suffixText: 'W',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('保存关键负载'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final watts = double.tryParse(power.text.trim());
    if (name.text.trim().isEmpty ||
        watts == null ||
        watts <= 0 ||
        watts > 20000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写设备名称和 0-20000W 的有效功率')));
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pop(
      context,
      _CriticalLoadDraft(name.text.trim(), category, watts),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StationTopology extends StatelessWidget {
  const _StationTopology({required this.station});
  final StationSummary? station;
  @override
  Widget build(BuildContext context) {
    const keys = ['solar', 'home', 'battery', 'grid'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              StatusPulse(
                color: station?.online == true
                    ? AppColors.primaryGreen
                    : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                station?.online == true ? '系统在线' : '系统状态待确认',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              DemoBadge(label: _sourceModeLabel(station?.sourceMode)),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 350;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: compact ? 1.45 : 1.7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: keys.map((key) {
                  final node = station?.node(key);
                  final meta = _nodeMeta(key);
                  return PressableScale(
                    onTap: () => _openNode(context, key),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: meta.$4.withValues(alpha: .075),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(meta.$3, color: meta.$4, size: 20),
                              const Spacer(),
                              Icon(
                                Icons.arrow_outward_rounded,
                                color: meta.$4,
                                size: 16,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            meta.$1,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _power(node?.powerW),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.today});
  final EnergyToday? today;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('发电', today?.summary.generationKwh, 'kWh', AppColors.solarOrange),
      ('用电', today?.summary.consumptionKwh, 'kWh', AppColors.primaryBlue),
      ('购电', today?.summary.gridImportKwh, 'kWh', AppColors.textSecondary),
      ('节省', today?.summary.savingsCny, '元', AppColors.primaryGreen),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.75,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.$2 == null
                        ? '--'
                        : '${item.$2!.toStringAsFixed(1)} ${item.$3}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: item.$4,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.station});
  final StationSummary? station;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        _InfoLine('数据质量', _quality(station?.dataQuality)),
        const Divider(height: 24),
        _InfoLine(
          '历史覆盖率',
          '${station?.coveragePercent.toStringAsFixed(0) ?? '--'}%',
        ),
        const Divider(height: 24),
        _InfoLine('最近观测', _time(station?.observedAt)),
        if (station?.diagnostic != null) ...[
          const Divider(height: 24),
          _InfoLine('诊断', station!.diagnostic!),
        ],
      ],
    ),
  );
}

class _BatteryHero extends StatelessWidget {
  const _BatteryHero({required this.insight});
  final BatteryInsight? insight;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102B4D), Color(0xFF1A5A76)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 116,
          height: 116,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (insight?.soc ?? 0) / 100),
            duration: const Duration(milliseconds: 760),
            curve: Curves.easeOutCubic,
            builder: (_, value, child) => CustomPaint(
              painter: _RingPainter(value),
              child: Center(
                child: Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '全屋预计备电',
                style: TextStyle(color: Color(0xFFBFD7E8), fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                insight?.wholeHomeHours == null
                    ? '待计算'
                    : '${insight!.wholeHomeHours!.toStringAsFixed(1)} 小时',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _deviceStatusLabel(insight?.status),
                style: const TextStyle(
                  color: Color(0xFF75E1B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value);
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: .14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF42E49E), Color(0xFF3A8CFF)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(8), -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(
      rect.deflate(8),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}

class _BatteryMetrics extends StatelessWidget {
  const _BatteryMetrics({required this.insight});
  final BatteryInsight? insight;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('额定容量', insight?.capacityKwh, 'kWh'),
      ('当前能量', insight?.currentEnergyKwh, 'kWh'),
      ('保护能量', insight?.protectedEnergyKwh, 'kWh'),
      ('可用能量', insight?.usableEnergyKwh, 'kWh'),
      ('备电目标', insight?.reservePercent, '%'),
      (
        '当前负载',
        insight?.homeLoadW == null ? null : insight!.homeLoadW! / 1000,
        'kW',
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.$2 == null
                        ? '--'
                        : '${item.$2!.toStringAsFixed(1)} ${item.$3}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AssumptionCard extends StatelessWidget {
  const _AssumptionCard({required this.insight});
  final BatteryInsight? insight;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: (insight?.assumptions ?? const ['电池数据暂不可用'])
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 17,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _NodeHistory extends StatelessWidget {
  const _NodeHistory({required this.nodeKey, required this.today});
  final String nodeKey;
  final EnergyToday? today;
  @override
  Widget build(BuildContext context) {
    final points = today?.flow ?? const [];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: points.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  '服务器历史数据暂不可用',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: points.take(8).map((point) {
                final value = switch (nodeKey) {
                  'solar' => point.solarPowerW,
                  'home' => point.homeLoadW,
                  'grid' => point.gridImportW,
                  _ => null,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${point.hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ((value ?? 0) / 6000).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 54,
                        child: Text(
                          _power(value),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _DeviceIdentity extends StatelessWidget {
  const _DeviceIdentity({required this.device});
  final DiscoveredDevice device;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102B4D), Color(0xFF1D4F82)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.battery_charging_full_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.model,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${device.online ? '在线' : '离线'} · ${_sourceModeLabel(device.sourceMode)} · ${device.firmware ?? '固件未知'}',
                style: const TextStyle(color: Color(0xFFBFD1E8), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.item, this.control = false});
  final DeviceCapability item;
  final bool control;
  @override
  Widget build(BuildContext context) {
    final verified = item.verified == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            control ? Icons.tune_rounded : Icons.sensors_rounded,
            color: item.available
                ? AppColors.primaryBlue
                : AppColors.navInactive,
            size: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capabilityLabel(item.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (control)
                  Text(
                    _controlVerificationText(item),
                    style: TextStyle(
                      fontSize: 10,
                      color: verified
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _capabilityValue(item),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CriticalLoadEntry extends StatelessWidget {
  const _CriticalLoadEntry({required this.insight, required this.config});
  final BatteryInsight? insight;
  final CriticalLoadConfig? config;

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CriticalLoadPage())),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: .16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.power_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '关键负载备电',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  config == null || config!.enabledCount == 0
                      ? '尚未配置，点击添加真实设备功率'
                      : '${config!.enabledCount} 项 · ${config!.totalPowerW.toStringAsFixed(0)} W · ${insight?.criticalLoadHours?.toStringAsFixed(1) ?? '--'} 小时',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.navInactive),
        ],
      ),
    ),
  );
}

class _HealthHero extends StatelessWidget {
  const _HealthHero({required this.health});
  final SystemHealth? health;

  @override
  Widget build(BuildContext context) {
    final status = health?.status;
    final color = status == 'critical'
        ? AppColors.danger
        : status == 'warning'
        ? AppColors.warning
        : AppColors.primaryGreen;
    final label = status == 'critical'
        ? '存在阻断项'
        : status == 'warning'
        ? '有项目需要关注'
        : status == 'healthy'
        ? '系统健康'
        : '正在检查';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102B4D), Color(0xFF1B537B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'critical'
                  ? Icons.gpp_bad_outlined
                  : status == 'warning'
                  ? Icons.health_and_safety_outlined
                  : Icons.verified_user_outlined,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${health?.checks.length ?? 0} 项检查 · ${health?.checks.where((item) => item.blocking).length ?? 0} 项阻断',
                  style: const TextStyle(
                    color: Color(0xFFBFD1E8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCheckCard extends StatelessWidget {
  const _HealthCheckCard({required this.check});
  final HealthCheck check;

  @override
  Widget build(BuildContext context) {
    final color = check.status == 'critical'
        ? AppColors.danger
        : check.status == 'warning'
        ? AppColors.warning
        : AppColors.primaryGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          StatusPulse(color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        check.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (check.blocking) const DemoBadge(label: '阻断控制'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  check.detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({required this.actions});
  final List<String> actions;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: actions.isEmpty
        ? const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
              SizedBox(width: 10),
              Expanded(child: Text('当前没有需要执行的恢复操作')),
            ],
          )
        : Column(
            children: actions.indexed
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.primaryBlueSoft,
                          child: Text(
                            '${entry.$1 + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry.$2)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class _CriticalSummary extends StatelessWidget {
  const _CriticalSummary({required this.config});
  final CriticalLoadConfig? config;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102B4D), Color(0xFF1B537B)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.electrical_services_rounded,
          color: Color(0xFF72E3B7),
          size: 35,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${config?.totalPowerW.toStringAsFixed(0) ?? '0'} W',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${config?.enabledCount ?? 0} 项已启用',
                style: const TextStyle(color: Color(0xFFBFD1E8), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CriticalLoadTile extends StatelessWidget {
  const _CriticalLoadTile({
    required this.load,
    required this.onChanged,
    required this.onDelete,
  });
  final CriticalLoad load;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(load.id),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) => showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除关键负载？'),
        content: Text('${load.name} 将不再参与备电时长计算。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    ),
    onDismissed: (_) => onDelete(),
    background: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.only(right: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.white),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(15, 9, 8, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Icon(_categoryIcon(load.category), color: AppColors.primaryBlue),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  load.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${load.ratedPowerW.toStringAsFixed(0)} W · ${_categoryLabel(load.category)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: load.enabled, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class _EmptyCriticalLoads extends StatelessWidget {
  const _EmptyCriticalLoads();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.playlist_add_rounded,
          size: 40,
          color: AppColors.navInactive,
        ),
        SizedBox(height: 10),
        Text('尚未配置关键负载', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 5),
        Text(
          '添加真实设备及功率后，光衡才会计算关键负载备电时长。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

IconData _categoryIcon(String value) => switch (value) {
  'network' => Icons.router_outlined,
  'lighting' => Icons.lightbulb_outline_rounded,
  'medical' => Icons.medical_services_outlined,
  'security' => Icons.security_outlined,
  _ => Icons.kitchen_outlined,
};

String _categoryLabel(String value) =>
    const {
      'appliance': '家用电器',
      'network': '网络通信',
      'lighting': '照明',
      'medical': '医疗设备',
      'security': '安防设备',
      'other': '其他',
    }[value] ??
    '其他';

class _Title extends StatelessWidget {
  const _Title(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      const Spacer(),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

(String, String, IconData, Color) _nodeMeta(String key) => switch (key) {
  'solar' => (
    '光伏发电',
    '实际、预测与发电去向',
    Icons.wb_sunny_rounded,
    AppColors.solarOrange,
  ),
  'battery' => (
    '储能电池',
    '容量、保护边界与备电时长',
    Icons.battery_charging_full_rounded,
    AppColors.primaryGreen,
  ),
  'grid' => (
    '电网',
    '购电、送电与参考电价',
    Icons.electric_bolt_rounded,
    AppColors.primaryBlue,
  ),
  _ => ('家庭负载', '实时负载与服务器历史', Icons.home_rounded, AppColors.primaryBlue),
};

void _openNode(BuildContext context, String key) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => key == 'battery'
          ? const BatteryDetailPage()
          : EnergyNodeDetailPage(nodeKey: key),
    ),
  );
}

String _power(double? value) =>
    value == null ? '--' : '${(value / 1000).toStringAsFixed(1)} kW';
String _direction(String value) => switch (value) {
  'in' => '能量流入',
  'out' => '能量流出',
  _ => '当前无明显能量流动',
};
String _quality(String? value) => switch (value) {
  'good' => '良好',
  'degraded' => '部分数据不足',
  _ => '不可用',
};
String _sourceModeLabel(String? value) => switch (value) {
  'home_assistant' => 'Home Assistant',
  'simulator' => '模拟器',
  null || '' => '无来源',
  _ => value,
};
String _deviceStatusLabel(String? value) => switch (value?.toLowerCase()) {
  'charging' => '充电中',
  'discharging' => '放电中',
  'idle' || 'standby' => '待机',
  'online' => '在线',
  'offline' => '离线',
  null || '' => '状态不可用',
  _ => value!,
};
String _time(DateTime? value) => value == null
    ? '--'
    : '${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}';
String _capabilityLabel(String value) =>
    const {
      'battery_soc': '电池电量',
      'solar_power': '光伏功率',
      'home_load': '家庭负载',
      'battery_charging_power': '充电功率',
      'battery_discharging_power': '放电功率',
      'grid_import_power': '电网购电',
      'grid_export_power': '电网上网',
      'battery_capacity': '电池容量',
      'device_status': '设备状态',
      'backup_reserve': '备用预留',
      'charging_limit': '充电上限',
      'discharge_limit': '放电下限',
      'operating_mode': '运行模式',
      'battery_power_direction': '充放电方向',
      'battery_power_setpoint': '电池功率设定',
      'third_party_solar_power': '第三方光伏功率',
      'ac_output_power': '交流输出功率',
      'total_solar_generation': '累计光伏发电量',
      'battery_charging_energy': '累计充电量',
      'battery_discharge_energy': '累计放电量',
    }[value] ??
    value;

String _capabilityValue(DeviceCapability capability) {
  final value = capability.value;
  if (value == null) return '--';
  final translated = const <String, String>{
    'self_consumption': '自发自用',
    'tou_mode': '分时电价',
    'third_party_control': '第三方控制',
    'custom_mode': '自定义模式',
    'socket_overlay_mode': '插座叠加模式',
    'smart_mode': '智能模式',
    'dynamic_pricing': '动态电价',
    'charge': '充电',
    'charging': '充电中',
    'discharge': '放电',
    'discharging': '放电中',
    'idle': '待机',
    'standby': '待机',
    'online': '在线',
    'offline': '离线',
    'on': '开启',
    'off': '关闭',
    'true': '开启',
    'false': '关闭',
    'grid-to-battery charge power': '电网向电池充电',
    'battery-to-grid discharge power': '电池向电网放电',
  }['$value'.toLowerCase()];
  return '${translated ?? value}${capability.unit ?? ''}';
}

String _controlVerificationText(DeviceCapability capability) {
  if (!capability.available) return '当前实体不可用 · 不允许控制';
  if (capability.access != 'read_write') return '实时值 · 当前能力只读';
  if (capability.verified == true) {
    return capability.verificationNote ?? '实时值 · 已完成实机写入与回读验证';
  }
  if (capability.readbackReliable == false) {
    return '实时值 · 官方实体回读不可靠，暂不开放控制';
  }
  return capability.verificationNote ?? '实时值 · 尚未完成实机写入与回读验证';
}
