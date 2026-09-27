import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_durations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../viewmodels/backend_view_model.dart';
import '../shared/real_data_widgets.dart';
import '../shared/motion_widgets.dart';

class StrategyPage extends StatelessWidget {
  const StrategyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final data = vm.data;
    if (vm.loading && data == null) return const PageSkeleton(title: '策略');
    final mode = data?.strategy?.mode;
    final proposal = data?.autonomy?.pendingProposal;
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
                title: '策略',
                actions: [
                  RoundIconButton(
                    icon: Icons.settings_outlined,
                    onPressed: () => _strategySettings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StaggeredReveal(
              order: 1,
              child: RealAgentStatusCard(
                status: data?.autonomy,
                onTap: proposal == null
                    ? null
                    : () => showPendingProposalActions(context, proposal),
              ),
            ),
            if (proposal != null) ...[
              const SizedBox(height: 16),
              StaggeredReveal(order: 2, child: _StrategyProposal(proposal)),
            ],
            const SizedBox(height: 20),
            const _Title('当前策略'),
            const SizedBox(height: 10),
            StaggeredReveal(order: 2, child: _CurrentStrategy(mode: mode)),
            const SizedBox(height: 12),
            const StaggeredReveal(
              order: 3,
              child: SizedBox(
                height: 126,
                child: Row(
                  children: [
                    Expanded(
                      child: _Factor(
                        Icons.show_chart_rounded,
                        '电价策略',
                        '居民参考均价',
                        AppColors.primaryBlue,
                        AppColors.primaryBlueSoft,
                      ),
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: _Factor(
                        Icons.wb_sunny_outlined,
                        '天气预测',
                        '真实天气与光伏',
                        AppColors.primaryGreen,
                        AppColors.primaryGreenSoft,
                      ),
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: _Factor(
                        Icons.assignment_outlined,
                        '负载管理',
                        '预测家庭负载',
                        AppColors.primaryGreen,
                        AppColors.primaryGreenSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _Title('策略要点'),
            const SizedBox(height: 10),
            const _StrategyPoints(),
            const SizedBox(height: 22),
            const _Title('24 小时计划'),
            const SizedBox(height: 10),
            _ScheduleCard(
              schedule: data?.schedule,
              reserveTarget: data?.strategy?.backupReserveTarget,
            ),
            const SizedBox(height: 22),
            const _Title('策略偏好', subtitle: '模式是优化边界，不是单次执行入口'),
            const SizedBox(height: 10),
            _ModeSelector(mode: mode, vm: vm),
            const SizedBox(height: 22),
            const _Title('自治级别', subtitle: '像权限控制一样，明确光衡可以做到哪一步'),
            const SizedBox(height: 10),
            _AutonomyLevel(
              currentLevel: data?.autonomy?.autonomyLevel ?? 'CONFIRM',
              vm: vm,
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.title, {this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -.35,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(
          subtitle!,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ],
  );
}

class _CurrentStrategy extends StatelessWidget {
  const _CurrentStrategy({required this.mode});
  final String? mode;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEDF4FF), Colors.white],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 22,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategyLabel(mode),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _strategyDescription(mode),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGreenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '● 运行中',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Factor extends StatelessWidget {
  const _Factor(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.softColor,
  );
  final IconData icon;
  final String title, subtitle;
  final Color color, softColor;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .85),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white),
    ),
    child: Padding(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _StrategyPoints extends StatelessWidget {
  const _StrategyPoints();
  @override
  Widget build(BuildContext context) => const Card(
    child: Column(
      children: [
        _Point(1, '预测能源供需', '结合未来光伏与家庭负载预测判断能源趋势'),
        Divider(height: 1, indent: 56, endIndent: 16),
        _Point(2, '动态调整备电目标', '由 Optimizer V2 根据策略与预测计算目标'),
        Divider(height: 1, indent: 56, endIndent: 16),
        _Point(3, '保持备用电量', '在策略约束范围内维持家庭所需备用电量'),
      ],
    ),
  );
}

class _Point extends StatelessWidget {
  const _Point(this.number, this.title, this.subtitle);
  final int number;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primaryBlueSoft,
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.reserveTarget});
  final EnergySchedule? schedule;
  final double? reserveTarget;

  Color _color(String action) => switch (action) {
    'STORE_SURPLUS' => const Color(0xFF56A1EC),
    'SOLAR_ASSIST' => const Color(0xFF35BE85),
    'COVER_DEFICIT' => const Color(0xFFFFAF32),
    'PRESERVE_RESERVE' => const Color(0xFFB8C7D8),
    _ => const Color(0xFFE3E9F0),
  };

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '今日调度',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '备用电量 ${displayValue(reserveTarget, suffix: '%')}',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (schedule?.points.isNotEmpty == true)
            _AnimatedScheduleBar(
              points: schedule!.points,
              colorForAction: _color,
            )
          else
            const EmptyDataCard(
              title: '暂无可用调度预测',
              message: '光伏或负载预测恢复后会自动生成未来 24 小时建议',
            ),
          if (schedule?.points.isNotEmpty == true)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _DotLabel(Color(0xFF56A1EC), '电池充电'),
                  _DotLabel(Color(0xFF35BE85), '光伏供电'),
                  _DotLabel(Color(0xFFFFAF32), '电池放电'),
                  _DotLabel(Color(0xFFB8C7D8), '备用时段'),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _AnimatedScheduleBar extends StatelessWidget {
  const _AnimatedScheduleBar({
    required this.points,
    required this.colorForAction,
  });

  final List<EnergySchedulePoint> points;
  final Color Function(String action) colorForAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              key: const Key('schedule-segment-bar'),
              height: 32,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppDurations.chart,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: SizedBox(width: constraints.maxWidth, child: child),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final point in points)
                      Expanded(
                        child: ColoredBox(color: colorForAction(point.action)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('00:00', style: _timeStyle),
            Text('06:00', style: _timeStyle),
            Text('12:00', style: _timeStyle),
            Text('18:00', style: _timeStyle),
            Text('24:00', style: _timeStyle),
          ],
        ),
      ],
    );
  }

  static const _timeStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 9,
  );
}

class _DotLabel extends StatelessWidget {
  const _DotLabel(this.color, this.label);
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
    ],
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.vm});
  final String? mode;
  final BackendViewModel vm;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final item in const [
        ('SAVE', Icons.eco_outlined),
        ('AUTO', Icons.sync_rounded),
        ('BACKUP', Icons.shield_outlined),
      ]) ...[
        Expanded(
          child: _ModeButton(
            label: strategyLabel(item.$1),
            icon: item.$2,
            selected: mode == item.$1,
            enabled: !vm.switching,
            onTap: () async {
              final ok = await vm.setStrategy(item.$1);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? '策略已更新' : '策略更新失败，已保留原设置')),
              );
            },
          ),
        ),
        if (item.$1 != 'BACKUP') const SizedBox(width: 8),
      ],
    ],
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryBlueSoft : Colors.white,
        border: Border.all(
          color: selected ? AppColors.primaryBlue : AppColors.divider,
          width: selected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AutonomyLevel extends StatelessWidget {
  const _AutonomyLevel({required this.currentLevel, required this.vm});

  final String currentLevel;
  final BackendViewModel vm;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '控制权限',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: vm.switchingAutonomy
                  ? const SizedBox(
                      key: ValueKey('saving'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Container(
                      key: ValueKey(currentLevel),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreenSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _autonomyTitle(currentLevel),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AccessLevelTile(
          title: '观察模式',
          subtitle: '仅查看能源状态',
          selected: currentLevel == 'OBSERVE',
          onTap: () => _selectAutonomyLevel(context, vm, 'OBSERVE'),
        ),
        const SizedBox(height: 8),
        _AccessLevelTile(
          title: '影子模式',
          subtitle: '分析并模拟，不创建方案',
          selected: currentLevel == 'SHADOW',
          onTap: () => _selectAutonomyLevel(context, vm, 'SHADOW'),
        ),
        const SizedBox(height: 8),
        _AccessLevelTile(
          title: '确认模式',
          subtitle: '主动提案，执行前询问',
          badge: '推荐',
          selected: currentLevel == 'CONFIRM',
          onTap: () => _selectAutonomyLevel(context, vm, 'CONFIRM'),
        ),
        const SizedBox(height: 8),
        _AccessLevelTile(
          title: '完全访问',
          subtitle: '开放完整分析与控制流程',
          badge: '高权限',
          selected: currentLevel == 'AUTO',
          critical: true,
          onTap: () => _selectAutonomyLevel(context, vm, 'AUTO'),
        ),
      ],
    ),
  );
}

class _AccessLevelTile extends StatelessWidget {
  const _AccessLevelTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.critical = false,
  });

  final String title, subtitle;
  final String? badge;
  final bool selected, critical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? critical
                  ? AppColors.warningSoft
                  : AppColors.primaryBlueSoft
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? critical
                    ? AppColors.solarOrange.withValues(alpha: .55)
                    : AppColors.primaryBlue.withValues(alpha: .6)
              : Colors.transparent,
          width: 1.25,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected
                ? critical
                      ? AppColors.warning
                      : AppColors.primaryBlue
                : AppColors.navInactive,
            size: 20,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: critical
                              ? AppColors.solarOrangeSoft
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            color: critical
                                ? AppColors.warning
                                : AppColors.primaryBlue,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Text(
              '当前',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> _selectAutonomyLevel(
  BuildContext context,
  BackendViewModel vm,
  String level,
) async {
  if (vm.switchingAutonomy) return;
  if (level == 'AUTO') {
    final confirmed = await _confirmFullAccess(context);
    if (confirmed != true || !context.mounted) return;
  }
  final ok = await vm.setAutonomyLevel(level);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok ? '已切换到${_autonomyTitle(level)}' : '切换失败，已保留原权限'),
    ),
  );
}

Future<bool?> _confirmFullAccess(BuildContext context) =>
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '完全访问确认',
      barrierColor: AppColors.textPrimary.withValues(alpha: .48),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, _) => SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: _FullAccessDialog(
                onCancel: () => Navigator.pop(dialogContext, false),
                onConfirm: () => Navigator.pop(dialogContext, true),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .035),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween(begin: .96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );

class _FullAccessDialog extends StatelessWidget {
  const _FullAccessDialog({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel, onConfirm;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33102238),
            blurRadius: 40,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF172A43), Color(0xFF285486)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '关闭',
                onPressed: onCancel,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceMuted,
                ),
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '开启完全访问？',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            '光衡将获得最高级别权限，可以持续分析、主动提案并进入设备控制流程。',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '将允许光衡',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 11),
                _FullAccessLine('持续分析能源状态'),
                SizedBox(height: 9),
                _FullAccessLine('主动生成优化方案'),
                SizedBox(height: 9),
                _FullAccessLine('发起设备控制请求'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.warning, size: 18),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '安全检查、设备在线检查、能力校验和执行回读仍然有效。',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: onConfirm,
              child: const Text('开启完全访问'),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: onCancel, child: const Text('取消')),
          ),
        ],
      ),
    ),
  );
}

class _FullAccessLine extends StatelessWidget {
  const _FullAccessLine(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.check_rounded, color: AppColors.primaryGreen, size: 16),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

String _autonomyTitle(String level) => switch (level) {
  'OBSERVE' => '观察模式',
  'SHADOW' => '影子模式',
  'AUTO' => '完全访问',
  _ => '确认模式',
};

class _StrategyProposal extends StatelessWidget {
  const _StrategyProposal(this.proposal);
  final PendingProposal proposal;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.solarOrange.withValues(alpha: .6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Expanded(
              child: Text(
                '需要你的确认',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DemoBadge(label: '等待确认'),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '建议调整备电计划',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              displayValue(proposal.currentValue, suffix: '%'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            Text(
              displayValue(proposal.targetValue, suffix: '%'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => resolvePendingProposalAction(
                  context,
                  proposal,
                  approve: false,
                ),
                child: const Text('暂不执行'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () => showPendingProposalActions(context, proposal),
                child: const Text('确认执行'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

String _strategyDescription(String? mode) => switch (mode) {
  'SAVE' => '优先降低家庭能源成本，结合参考电价与预测优化用能。',
  'BACKUP' => '优先保持家庭备用电量，在安全约束内安排能源。',
  _ => '基于电价、天气、当前负载与用户模式，动态优化家庭能源计划。',
};

Future<void> _strategySettings(BuildContext context) => showModalBottomSheet(
  context: context,
  useSafeArea: true,
  builder: (_) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.tune_rounded),
          title: Text('策略设置'),
          subtitle: Text('当前策略由真实 GuangHeng Backend 管理'),
        ),
      ],
    ),
  ),
);
