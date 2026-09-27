import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../models/home_energy_data.dart';
import '../../viewmodels/backend_view_model.dart';
import '../shared/real_data_widgets.dart';
import '../shared/motion_widgets.dart';
import 'widgets/rotatable_energy_model.dart';
import '../station/station_pages.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.enableInteractive3d = true});
  final bool enableInteractive3d;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final data = vm.data;
    if (vm.loading && data == null) return const PageSkeleton(title: '首页');
    final energy = data?.energy;
    final today = data?.today;
    final weather = data?.weather;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
          children: [
            StaggeredReveal(
              child: PageHeader(
                title: '首页',
                subtitle: Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 19,
                      color: AppColors.solarOrange,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      weather == null
                          ? '天气暂不可用'
                          : '${_weather(weather.condition)}  ${displayValue(weather.temperature, suffix: '°C')}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                actions: [
                  RoundIconButton(
                    icon: Icons.notifications_none_rounded,
                    badgeCount: data?.autonomy?.unreadCount ?? 0,
                    onPressed: () => _notifications(context, vm),
                  ),
                  RoundIconButton(
                    icon: Icons.settings_outlined,
                    onPressed: () => _settings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StaggeredReveal(
              order: 1,
              child: RealAgentStatusCard(
                status: data?.autonomy,
                onTap: data?.autonomy?.pendingProposal == null
                    ? null
                    : () => showPendingProposalActions(
                        context,
                        data!.autonomy!.pendingProposal!,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            StaggeredReveal(
              order: 2,
              child: _EnergyHouseCard(
                energy: energy,
                today: today,
                enableInteractive3d: enableInteractive3d,
              ),
            ),
            if (data?.autonomy?.pendingProposal != null) ...[
              const SizedBox(height: 18),
              StaggeredReveal(
                order: 3,
                child: _ProposalCard(data!.autonomy!.pendingProposal!),
              ),
            ],
            const SizedBox(height: 20),
            StaggeredReveal(
              order: 4,
              child: Row(
                children: [
                  Expanded(
                    child: _DailyMetric(
                      title: '今日发电',
                      value: _kwh(today?.summary.generationKwh),
                      changePercent: today?.summary.generationChangePercent,
                      icon: Icons.solar_power_rounded,
                      color: AppColors.solarOrange,
                      softColor: AppColors.solarOrangeSoft,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DailyMetric(
                      title: '今日用电',
                      value: _kwh(today?.summary.consumptionKwh),
                      changePercent: today?.summary.consumptionChangePercent,
                      icon: Icons.bolt_rounded,
                      color: AppColors.primaryBlue,
                      softColor: AppColors.primaryBlueSoft,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            StaggeredReveal(
              order: 5,
              child: _EnergyChartCard(flow: today?.flow ?? const []),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyHouseCard extends StatefulWidget {
  const _EnergyHouseCard({
    required this.energy,
    required this.today,
    required this.enableInteractive3d,
  });
  final EnergyState? energy;
  final EnergyToday? today;
  final bool enableInteractive3d;
  @override
  State<_EnergyHouseCard> createState() => _EnergyHouseCardState();
}

class _EnergyHouseCardState extends State<_EnergyHouseCard> {
  EnergyFocus focus = EnergyFocus.solar;
  @override
  Widget build(BuildContext context) {
    final e = widget.energy;
    final model = HomeEnergyData(
      solarPowerKw: (e?.solarW ?? 0) / 1000,
      homePowerKw: (e?.homeLoadW ?? 0) / 1000,
      batterySoc: e?.soc ?? 0,
      batteryCharging: e?.batteryStatus == 'charging',
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _LiveMetric(
                    title: '光伏',
                    value: _kw(e?.solarW),
                    icon: Icons.wb_sunny_outlined,
                    color: AppColors.solarOrange,
                    selected: focus == EnergyFocus.solar,
                    onTap: () {
                      setState(() => focus = EnergyFocus.solar);
                      _openNode(context, EnergyFocus.solar);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LiveMetric(
                    title: '家庭用电',
                    value: _kw(e?.homeLoadW),
                    icon: Icons.home_rounded,
                    color: AppColors.primaryBlue,
                    selected: focus == EnergyFocus.home,
                    onTap: () {
                      setState(() => focus = EnergyFocus.home);
                      _openNode(context, EnergyFocus.home);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 336,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF1F7FE), Color(0xFFFBFDFE)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: RotatableEnergyModel(
                data: model,
                selectedFocus: focus,
                onFocusChanged: (value) => setState(() => focus = value),
                onFocusActivated: (value) => _openNode(context, value),
                enabled: widget.enableInteractive3d,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StationOverviewPage(),
                  ),
                ),
                icon: const Icon(Icons.hub_outlined, size: 17),
                label: const Text('查看电站总览'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _BottomMetric(
                    icon: Icons.battery_charging_full_rounded,
                    title: '电池 · ${_battery(e?.batteryStatus)}',
                    value: displayValue(e?.soc, suffix: '%'),
                    color: AppColors.primaryGreen,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BatteryDetailPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BottomMetric(
                    icon: Icons.eco_rounded,
                    title: '今日节省 · 参考估算',
                    value: _currency(widget.today?.summary.savingsCny),
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: .075)
            : AppColors.surfaceMuted,
        border: Border.all(
          color: selected ? color.withValues(alpha: .65) : Colors.transparent,
          width: selected ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _BottomMetric extends StatelessWidget {
  const _BottomMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String title, value;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    child: Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard(this.proposal);
  final PendingProposal proposal;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.solarOrange.withValues(alpha: .65)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.solarOrangeSoft,
              child: Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.solarOrange,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '需要你的确认',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '建议调整备电计划',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const DemoBadge(label: '等待确认'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ProposalValue(
                '原目标',
                displayValue(proposal.currentValue, suffix: '%'),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryBlue,
              ),
              _ProposalValue(
                '新目标',
                displayValue(proposal.targetValue, suffix: '%'),
                blue: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _resolve(context, approve: false),
                child: const Text('暂不执行'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => _confirm(context),
                child: const Text('允许执行'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              '确认执行这次调整？',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 9),
            Text(
              '备用预留将从 ${displayValue(proposal.currentValue, suffix: '%')} 调整为 ${displayValue(proposal.targetValue, suffix: '%')}。执行前后端仍会重新读取设备状态并完成安全检查，写入后必须回读验证。',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('返回'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('确认并执行'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await _resolve(context, approve: true);
    }
  }

  Future<void> _resolve(BuildContext context, {required bool approve}) async {
    final ok = await context.read<BackendViewModel>().resolveProposal(
      proposal.id,
      approve: approve,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve ? '已完成审批，请在执行时间线查看安全检查与回读结果' : '已拒绝本次方案')
              : (approve ? '执行未完成，请查看安全检查或设备状态' : '拒绝失败，请稍后重试'),
        ),
      ),
    );
  }
}

void _openNode(BuildContext context, EnergyFocus focus) {
  final page = switch (focus) {
    EnergyFocus.battery => const BatteryDetailPage(),
    EnergyFocus.solar => const EnergyNodeDetailPage(nodeKey: 'solar'),
    EnergyFocus.home => const EnergyNodeDetailPage(nodeKey: 'home'),
    EnergyFocus.saving => const StationOverviewPage(),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _ProposalValue extends StatelessWidget {
  const _ProposalValue(this.label, this.value, {this.blue = false});
  final String label, value;
  final bool blue;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: blue ? AppColors.primaryBlue : AppColors.textPrimary,
        ),
      ),
    ],
  );
}

class _DailyMetric extends StatelessWidget {
  const _DailyMetric({
    required this.title,
    required this.value,
    required this.changePercent,
    required this.icon,
    required this.color,
    required this.softColor,
  });
  final String title, value;
  final double? changePercent;
  final IconData icon;
  final Color color, softColor;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _trend(changePercent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: changePercent == null
                        ? AppColors.textSecondary
                        : AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const DemoBadge(label: '服务器历史'),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EnergyChartCard extends StatelessWidget {
  const _EnergyChartCard({required this.flow});
  final List<EnergyFlowPoint> flow;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  '今日能源流向 (kW)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              _Legend(AppColors.solarOrange, '光伏'),
              SizedBox(width: 10),
              _Legend(AppColors.primaryBlue, '家庭'),
              SizedBox(width: 8),
              DemoBadge(label: '服务器历史'),
            ],
          ),
          const SizedBox(height: 18),
          if (flow.isEmpty)
            const SizedBox(
              height: 205,
              child: Center(
                child: Text(
                  '今日历史数据暂不可用',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 205,
              width: double.infinity,
              child: CustomPaint(painter: _EnergyCurvePainter(flow)),
            ),
          const DefaultTextStyle(
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00:00'),
                Text('06:00'),
                Text('12:00'),
                Text('18:00'),
                Text('24:00'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    ],
  );
}

class _EnergyCurvePainter extends CustomPainter {
  const _EnergyCurvePainter(this.flow);
  final List<EnergyFlowPoint> flow;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maximumW = flow.fold<double>(
      1000,
      (maximum, point) => [
        point.solarPowerW ?? 0,
        point.homeLoadW ?? 0,
        maximum,
      ].reduce((a, b) => a > b ? a : b),
    );
    _draw(
      canvas,
      size,
      (point) => point.homeLoadW,
      maximumW,
      AppColors.primaryBlue.withValues(alpha: .55),
    );
    _draw(
      canvas,
      size,
      (point) => point.solarPowerW,
      maximumW,
      AppColors.solarOrange,
    );
  }

  void _draw(
    Canvas canvas,
    Size size,
    double? Function(EnergyFlowPoint) valueOf,
    double maximumW,
    Color color,
  ) {
    final path = Path();
    var started = false;
    for (final point in flow) {
      final value = valueOf(point);
      if (value == null) continue;
      final x = size.width * point.hour / 24;
      final y = size.height - (value / maximumW) * size.height * .9;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EnergyCurvePainter oldDelegate) =>
      oldDelegate.flow != flow;
}

String _kw(double? watts) =>
    watts == null ? '--' : '${(watts / 1000).toStringAsFixed(1)} kW';
String _kwh(double? value) =>
    value == null ? '--' : '${value.toStringAsFixed(1)} kWh';
String _currency(double? value) =>
    value == null ? '--' : '¥${value.toStringAsFixed(2)}';
String _trend(double? value) {
  if (value == null) return '暂无昨日同期';
  final arrow = value >= 0 ? '↑' : '↓';
  return '$arrow ${value.abs().toStringAsFixed(1)}% 较昨日同期';
}

String _battery(String? status) => switch (status) {
  'charging' => '充电中',
  'discharging' => '放电中',
  _ => '待机',
};
String _weather(String? condition) => switch (condition) {
  'partly_cloudy' => '多云',
  'clear' => '晴',
  'rain' => '雨',
  _ => condition ?? '--',
};

Future<void> _settings(BuildContext context) => showModalBottomSheet(
  context: context,
  useSafeArea: true,
  builder: (_) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.settings_outlined),
          title: Text('家庭能源设置'),
          subtitle: Text('更多设置将在设备接入后开放'),
        ),
      ],
    ),
  ),
);

Future<void> _notifications(BuildContext context, BackendViewModel vm) =>
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '通知',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (vm.data?.notifications.isEmpty ?? true)
            const EmptyDataCard(title: '暂无通知', message: '光衡会在需要确认或系统受限时提醒你')
          else
            for (final n in vm.data!.notifications)
              ListTile(
                title: Text(n.type == 'ACTION_REQUIRED' ? '需要你的确认' : '系统提示'),
                subtitle: Text(n.message),
                trailing: n.status == 'UNREAD'
                    ? TextButton(
                        onPressed: () {
                          vm.markRead(n.id);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('标为已读'),
                      )
                    : const Icon(Icons.done),
              ),
        ],
      ),
    );
