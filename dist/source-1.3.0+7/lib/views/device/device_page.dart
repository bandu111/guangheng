import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../viewmodels/backend_view_model.dart';
import '../shared/motion_widgets.dart';
import '../shared/real_data_widgets.dart';
import '../station/station_pages.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final devices = vm.data?.devices ?? const <DiscoveredDevice>[];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
          children: [
            const StaggeredReveal(
              child: PageHeader(
                title: '设备',
                subtitle: Text(
                  '真实设备、能力与健康状态',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 22),
            StaggeredReveal(
              order: 1,
              child: _HealthSummary(devices: devices, health: vm.data?.health),
            ),
            const SizedBox(height: 12),
            StaggeredReveal(
              order: 2,
              child: _PlatformEntry(
                areas: vm.data?.areaLoads,
                profiles: vm.data?.profiles ?? const [],
              ),
            ),
            const SizedBox(height: 24),
            const StaggeredReveal(
              order: 3,
              child: _SectionHeading('能源设备', '控制入口只对已验证能力开放'),
            ),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              const _EmptyDevices()
            else
              ...devices.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StaggeredReveal(
                    order: entry.$1 + 4,
                    child: _DeviceCard(device: entry.$2),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const _SectionHeading('连接说明', '设备能力来自 Home Assistant 本次实时发现'),
            const SizedBox(height: 12),
            const _SourceNotice(),
          ],
        ),
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.devices, required this.health});
  final List<DiscoveredDevice> devices;
  final SystemHealth? health;

  @override
  Widget build(BuildContext context) {
    final online = devices.where((device) => device.online).length;
    final verified = devices
        .expand((device) => device.controls)
        .where((capability) => capability.verified == true)
        .length;
    return PressableScale(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SystemHealthPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF112A4A), Color(0xFF1D5684)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35142F55),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.hub_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const Spacer(),
                DemoBadge(label: _healthLabel(health?.status)),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              '家庭能源设备',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${devices.length} 台设备 · $online 台在线 · $verified 项控制已验证',
              style: const TextStyle(color: Color(0xFFBED1E8), fontSize: 12),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Text(
                  '查看健康诊断与恢复建议',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _healthLabel(String? status) => switch (status) {
  'healthy' => '健康',
  'warning' => '需关注',
  'critical' => '已阻断',
  _ => '检查中',
};

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    final soc = _value('battery_soc');
    final verified = device.controls
        .where((item) => item.verified == true)
        .length;
    return PressableScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DeviceDetailPage(device: device)),
      ),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                _deviceIcon(device.deviceType),
                color: AppColors.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.model,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      StatusPulse(
                        color: device.online
                            ? AppColors.primaryGreen
                            : AppColors.warning,
                      ),
                      Text(
                        device.online ? '在线' : '离线',
                        style: TextStyle(
                          color: device.online
                              ? AppColors.primaryGreen
                              : AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_deviceTypeLabel(device.deviceType)} · ${device.telemetry.length} 项数据 · $verified 项已验证',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  soc == null
                      ? '--'
                      : '${(soc as num).toDouble().toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navInactive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  dynamic _value(String name) {
    for (final item in device.telemetry) {
      if (item.name == name && item.available) return item.value;
    }
    return null;
  }
}

class _PlatformEntry extends StatelessWidget {
  const _PlatformEntry({required this.areas, required this.profiles});
  final AreaLoadView? areas;
  final List<DeviceProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final supported = profiles
        .where((profile) => !profile.supportStatus.contains('coming_soon'))
        .length;
    final planned = profiles.length - supported;
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AreaLoadPage())),
            child: _PlatformTile(
              icon: Icons.home_work_outlined,
              title: '家庭负载',
              value: areas?.available == true
                  ? '${areas!.areas.length} 个区域'
                  : '等待 Home Assistant 区域',
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressableScale(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileCatalogPage()),
            ),
            child: _PlatformTile(
              icon: Icons.view_in_ar_outlined,
              title: '设备能力档案',
              value: planned > 0
                  ? '$supported 已支持 · $planned 计划中'
                  : '$supported 类设备',
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
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

IconData _deviceIcon(String type) => switch (type) {
  'smart_plug' => Icons.power_rounded,
  'smart_meter' => Icons.electric_meter_outlined,
  _ => Icons.battery_charging_full_rounded,
};

String _deviceTypeLabel(String type) => switch (type) {
  'smart_plug' => '智能插座',
  'smart_meter' => '智能电表',
  'storage' => '储能设备',
  _ => '能源设备',
};

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.portable_wifi_off_rounded,
          size: 42,
          color: AppColors.navInactive,
        ),
        SizedBox(height: 12),
        Text('未发现能源设备', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text(
          '请检查 Home Assistant 与 Anker SOLIX 官方集成。系统不会用模拟卡片伪装设备在线。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _SourceNotice extends StatelessWidget {
  const _SourceNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: .12)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: AppColors.primaryBlue,
          size: 20,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            '页面按实时设备能力渲染。未验证控制保持只读；设备离线、能力变化或数据不可用时，安全检查会阻断写入。',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, this.subtitle);
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
