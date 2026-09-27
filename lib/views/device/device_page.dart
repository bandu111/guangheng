import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../services/companion_ble_provisioning_service.dart';
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
              child: _CompanionPanel(terminals: vm.companions),
            ),
            const SizedBox(height: 12),
            StaggeredReveal(
              order: 2,
              child: _HealthSummary(devices: devices, health: vm.data?.health),
            ),
            const SizedBox(height: 12),
            StaggeredReveal(
              order: 3,
              child: _PlatformEntry(
                areas: vm.data?.areaLoads,
                profiles: vm.data?.profiles ?? const [],
              ),
            ),
            const SizedBox(height: 24),
            const StaggeredReveal(
              order: 4,
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

class _CompanionPanel extends StatelessWidget {
  const _CompanionPanel({required this.terminals});
  final List<CompanionTerminal> terminals;

  @override
  Widget build(BuildContext context) {
    final active = terminals
        .where((item) => item.paired && !item.revoked)
        .toList();
    final online = active.where((item) => item.onlineRecently).length;
    return PressableScale(
      onTap: () => _openCompanionSheet(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A7068), Color(0xFF2878D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x292168A9),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.watch_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '光衡随身终端',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    active.isEmpty
                        ? '点击配对你的能源伙伴'
                        : '${active.length} 台已配对 · $online 台最近在线',
                    style: const TextStyle(
                      color: Color(0xFFD9F5F2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCompanionSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CompanionPairingSheet(terminals: terminals),
    );
  }
}

class _CompanionPairingSheet extends StatefulWidget {
  const _CompanionPairingSheet({required this.terminals});

  final List<CompanionTerminal> terminals;

  @override
  State<_CompanionPairingSheet> createState() => _CompanionPairingSheetState();
}

class _CompanionPairingSheetState extends State<_CompanionPairingSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DAE3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  '连接随身终端',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  '输入设备屏幕显示的 6 位配对码。终端只连接光衡服务器，不保存 Home Assistant 或 AI 密钥。',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _BleProvisioningSheet(),
                    ),
                    icon: const Icon(Icons.bluetooth_rounded),
                    label: const Text(
                      '通过蓝牙配置 Wi-Fi',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF216FED),
                      side: const BorderSide(color: Color(0xFFD5E3FA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                ),
                if (widget.terminals.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ...widget.terminals.map(
                    (terminal) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: terminal.revoked
                            ? const Color(0xFFF1F3F6)
                            : const Color(0xFFE8F8F3),
                        child: Icon(
                          terminal.revoked
                              ? Icons.link_off_rounded
                              : Icons.watch_outlined,
                          color: terminal.revoked
                              ? AppColors.textSecondary
                              : const Color(0xFF17A879),
                        ),
                      ),
                      title: Text(
                        terminal.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        terminal.revoked
                            ? '授权已撤销'
                            : (terminal.onlineRecently ? '最近在线' : '已配对'),
                      ),
                      trailing: terminal.revoked
                          ? null
                          : TextButton(
                              onPressed: vm.pairingCompanion
                                  ? null
                                  : () async {
                                      final ok = await vm.revokeCompanion(
                                        terminal.deviceUid,
                                      );
                                      if (context.mounted) {
                                        if (ok) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '授权已撤销，请等待终端显示新的 6 位配对码',
                                              ),
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                              child: const Text('撤销'),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: _controller,
                  enabled: !vm.pairingCompanion,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    filled: true,
                    fillColor: const Color(0xFFF4F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: vm.pairingCompanion
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            final ok = await vm.confirmCompanionPairing(
                              _controller.text,
                            );
                            if (ok && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF216FED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: vm.pairingCompanion
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '确认配对',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BleProvisioningSheet extends StatefulWidget {
  const _BleProvisioningSheet();

  @override
  State<_BleProvisioningSheet> createState() => _BleProvisioningSheetState();
}

class _BleProvisioningSheetState extends State<_BleProvisioningSheet> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  final _service = CompanionBleProvisioningService();
  bool _obscure = true;
  bool _working = false;
  String _status = '让终端保持亮屏，并放在手机附近';

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await _service.provision(
        ssid: _ssid.text,
        password: _password.text,
        onProgress: (message) {
          if (mounted) setState(() => _status = message);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wi-Fi 配置成功，终端正在连接光衡服务器')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DAE3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bluetooth_rounded,
                        color: Color(0xFF216FED),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '配置终端网络',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '凭据通过加密蓝牙连接写入终端',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _ssid,
                  enabled: !_working,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Wi-Fi 名称', Icons.wifi_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  enabled: !_working,
                  obscureText: _obscure,
                  onSubmitted: (_) => _submit(),
                  decoration:
                      _inputDecoration(
                        'Wi-Fi 密码',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (_working)
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.shield_outlined, size: 20),
                        ),
                      Expanded(child: Text(_status)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _working ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF216FED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      _working ? '正在配置' : '开始安全配网',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '不会通过蓝牙传输 Home Assistant 或 AI 密钥',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
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
  Widget build(BuildContext context) => SizedBox(
    height: 108,
    child: Container(
      key: Key('platform-tile-$title'),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.navInactive,
                size: 17,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
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
