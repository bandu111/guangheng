import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../viewmodels/backend_view_model.dart';
import 'motion_widgets.dart';

String agentLabel(String? state) => switch (state) {
  'MONITORING' => '运行中',
  'ACTION_REQUIRED' => '等待确认',
  'DEGRADED' => '部分服务受限',
  'DISABLED' => '自动分析未开启',
  _ => '状态未知',
};
String reasonLabel(String? code) => switch (code) {
  'TARGET_ALREADY_SATISFIED' => '当前目标已满足',
  'FORECAST_CONFIDENCE_INSUFFICIENT' => '当前预测数据有限，暂不动态调整',
  'AUTO_FORECAST_STRONG_SURPLUS' => '预计能源充足',
  'AUTO_FORECAST_BALANCED' => '预计能源供需平衡',
  'AUTO_FORECAST_MODERATE_DEFICIT' => '预计能源存在缺口',
  'AUTO_FORECAST_STRONG_DEFICIT' => '预计能源缺口较大',
  'PENDING_PROPOSAL_CONFLICT' => '已有待确认方案',
  _ => '等待更多数据',
};
String strategyLabel(String? mode) => switch (mode) {
  'SAVE' => '省钱优先',
  'AUTO' => '智能优化',
  'BACKUP' => '备电优先',
  _ => '--',
};
String displayValue(double? v, {String suffix = ''}) =>
    v == null ? '--' : '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)}$suffix';

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key, this.label = '模拟数据'});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.replaySoft,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.replay,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final Widget? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
                height: 1.05,
              ),
            ),
            if (subtitle != null) ...[const SizedBox(height: 7), subtitle!],
          ],
        ),
      ),
      ...actions,
    ],
  );
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: PressableScale(
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            if (badgeCount > 0)
              Positioned(
                right: -5,
                top: -6,
                child: _NumberBadge(count: badgeCount),
              ),
          ],
        ),
      ),
    ),
  );
}

class RealAgentStatusCard extends StatelessWidget {
  const RealAgentStatusCard({super.key, required this.status, this.onTap});
  final AutonomyStatus? status;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final s = status;
    final action = s?.agentState == 'ACTION_REQUIRED';
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: action
                ? const [Color(0xFFFFFBF3), Colors.white]
                : const [Color(0xFFF1FBF8), Color(0xFFF7FAFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: action
                ? AppColors.solarOrange.withValues(alpha: .26)
                : AppColors.primaryGreen.withValues(alpha: .18),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332267E8),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPulse(
                          color: action
                              ? AppColors.solarOrange
                              : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            '光衡智能助手',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: action
                                ? AppColors.warningSoft
                                : AppColors.primaryGreenSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            agentLabel(s?.agentState),
                            style: TextStyle(
                              color: action
                                  ? AppColors.warning
                                  : AppColors.success,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action
                          ? '建议调整备电目标'
                          : s?.autonomyLevel == 'OBSERVE'
                          ? '正在观察家庭能源，不运行优化器'
                          : s?.autonomyLevel == 'SHADOW'
                          ? '正在影子分析，不会创建执行方案'
                          : s?.latestDecision == null
                          ? '等待首次能源分析'
                          : reasonLabel(s!.latestDecision!.reasonCode),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 34,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.textPrimary,
                            size: 17,
                          ),
                        ),
                      ),
                      if ((s?.unreadCount ?? 0) > 0)
                        Positioned(
                          right: -7,
                          top: -8,
                          child: _NumberBadge(count: s!.unreadCount),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: 5),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.danger,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
  );
}

Future<void> showPendingProposalActions(
  BuildContext context,
  PendingProposal proposal,
) async {
  final approve = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        22 + MediaQuery.viewPaddingOf(sheetContext).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '确认备电调整',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '备用预留将从 ${displayValue(proposal.currentValue, suffix: '%')} 调整为 ${displayValue(proposal.targetValue, suffix: '%')}。确认后仍会执行在线状态、能力验证、安全检查和设备回读。',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(sheetContext, true),
              icon: const Icon(Icons.shield_outlined),
              label: const Text('确认执行'),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('暂不执行'),
            ),
          ),
        ],
      ),
    ),
  );
  if (approve == null || !context.mounted) return;
  await resolvePendingProposalAction(context, proposal, approve: approve);
}

Future<void> resolvePendingProposalAction(
  BuildContext context,
  PendingProposal proposal, {
  required bool approve,
}) async {
  final ok = await context.read<BackendViewModel>().resolveProposal(
    proposal.id,
    approve: approve,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? (approve ? '已确认，执行结果将通过安全检查与设备回读确认' : '已暂不执行本次方案')
            : (approve ? '执行未完成，请检查设备状态与安全检查结果' : '暂不执行操作失败，请稍后重试'),
      ),
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
        ),
        // ignore: use_null_aware_elements
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class EmptyDataCard extends StatelessWidget {
  const EmptyDataCard({super.key, required this.title, required this.message});
  final String title, message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, color: AppColors.navInactive),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AmbientPageBackground(
    child: SafeArea(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          for (final height in [88.0, 180.0, 116.0]) ...[
            Container(
              height: height,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    ),
  );
}
