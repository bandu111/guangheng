import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/backend_models.dart';
import '../../viewmodels/backend_view_model.dart';
import 'motion_widgets.dart';

String _capabilityLabel(String value) => switch (value) {
  'battery_power_direction' => '充放电方向',
  'battery_power_setpoint' => '储能功率',
  'power_switch' => '柔性负载',
  'backup_reserve' => '备用预留',
  _ => value,
};

String _actionValue(CoordinatedActionItem item, double value) =>
    switch (item.capability) {
      'battery_power_direction' => value == 0 ? '充电' : '放电',
      'power_switch' => value >= .5 ? '开启' : '关闭',
      'battery_power_setpoint' => '${value.toStringAsFixed(0)} W',
      'backup_reserve' => '${value.toStringAsFixed(0)}%',
      _ => value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
    };

String _statusLabel(String value) => switch (value) {
  'PENDING' => '等待确认',
  'APPROVED' => '已批准',
  'EXECUTING' => '执行中',
  'SUCCEEDED' => '已验证',
  'PARTIAL' => '部分完成',
  'BLOCKED' => '已阻断',
  'SKIPPED' => '已停止',
  'REJECTED' => '暂不执行',
  'FAILED' => '未完成',
  _ => value,
};

Color _statusColor(String value) => switch (value) {
  'SUCCEEDED' => AppColors.success,
  'EXECUTING' || 'APPROVED' => AppColors.primaryBlue,
  'PARTIAL' || 'BLOCKED' || 'FAILED' => AppColors.danger,
  'SKIPPED' || 'REJECTED' => AppColors.textSecondary,
  _ => AppColors.warning,
};

class CoordinatedActionSetCard extends StatelessWidget {
  const CoordinatedActionSetCard({super.key, required this.actionSet});

  final CoordinatedActionSet actionSet;

  @override
  Widget build(BuildContext context) {
    final devices = actionSet.items.map((e) => e.deviceName).toSet().length;
    final running = actionSet.isRunning;
    return PressableScale(
      onTap: () => showCoordinatedActionSet(context, actionSet.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _statusColor(actionSet.status).withValues(alpha: .35),
          ),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryBlue],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    running ? Icons.sync_rounded : Icons.hub_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        actionSet.isPending ? '跨设备协同建议' : '协同执行结果',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actionSet.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: actionSet.status),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SummaryChip(icon: Icons.devices_other, label: '$devices 台设备'),
                _SummaryChip(
                  icon: Icons.account_tree_outlined,
                  label: '${actionSet.items.length} 个步骤',
                ),
                if (actionSet.expectedGridDeltaW != null)
                  _SummaryChip(
                    icon: Icons.south_east_rounded,
                    label:
                        '少反送 ${actionSet.expectedGridDeltaW!.toStringAsFixed(0)} W',
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                for (var i = 0; i < actionSet.items.length; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 220 + i * 70),
                      height: 5,
                      decoration: BoxDecoration(
                        color: _statusColor(actionSet.items[i].status),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (i != actionSet.items.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    actionSet.isPending
                        ? '一次确认，系统按顺序执行并用总表统一验证'
                        : actionSet.verificationMessage ?? '点击查看每一步结果',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCoordinatedActionSet(BuildContext context, int actionSetId) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSetSheet(actionSetId: actionSetId),
    );

class _ActionSetSheet extends StatelessWidget {
  const _ActionSetSheet({required this.actionSetId});
  final int actionSetId;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final latest = vm.data?.actionSet;
    final value = latest?.id == actionSetId ? latest : null;
    if (value == null) return const SizedBox.shrink();
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: .82,
      minChildSize: .58,
      maxChildSize: .94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 18 + bottom),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.hub_outlined,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              value.reason,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(status: value.status),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _ImpactPanel(actionSet: value),
                  const SizedBox(height: 22),
                  const Text(
                    '执行步骤',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '每一步都独立经过在线、权限、安全与状态回读检查',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 13),
                  for (var i = 0; i < value.items.length; i++)
                    _ActionStep(
                      item: value.items[i],
                      isLast: i == value.items.length - 1,
                    ),
                  if (value.isTerminal) ...[
                    const SizedBox(height: 18),
                    _VerificationPanel(actionSet: value),
                  ],
                  if (value.isPending) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: AppColors.primaryBlue,
                            size: 19,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              '一次确认仅授权本方案。若某一步未通过，后续动作会自动停止；系统不会对已完成动作进行未经验证的反向操作。',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: vm.resolvingActionSet
                                ? null
                                : () => _resolve(context, value, false),
                            child: const Text('暂不执行'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: vm.resolvingActionSet
                                ? null
                                : () => _resolve(context, value, true),
                            icon: const Icon(Icons.verified_user_outlined),
                            label: const Text('确认全部步骤'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (value.isRunning || vm.resolvingActionSet) ...[
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(minHeight: 4),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        '正在按顺序执行，请保持网络连接',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    CoordinatedActionSet value,
    bool approve,
  ) async {
    HapticFeedback.mediumImpact();
    final ok = await context.read<BackendViewModel>().resolveActionSet(
      value.id,
      approve: approve,
    );
    if (!context.mounted) return;
    if (!approve) {
      Navigator.pop(context);
      return;
    }
    final result = context.read<BackendViewModel>().data?.actionSet;
    if (ok && result?.status == 'SUCCEEDED') {
      HapticFeedback.heavyImpact();
    }
  }
}

class _ActionStep extends StatelessWidget {
  const _ActionStep({required this.item, required this.isLast});
  final CoordinatedActionItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: .45)),
                ),
                child: item.status == 'EXECUTING'
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        item.status == 'SUCCEEDED'
                            ? Icons.check_rounded
                            : item.status == 'PENDING'
                            ? Icons.more_horiz_rounded
                            : Icons.priority_high_rounded,
                        size: 15,
                        color: color,
                      ),
              ),
              if (!isLast)
                Container(width: 1.5, height: 54, color: AppColors.divider),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .055),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _statusLabel(item.status),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${_capabilityLabel(item.capability)}  ${_actionValue(item, item.currentValue)} → ${_actionValue(item, item.targetValue)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (item.resultMessage != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.resultMessage!,
                    style: TextStyle(color: color, fontSize: 10, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpactPanel extends StatelessWidget {
  const _ImpactPanel({required this.actionSet});
  final CoordinatedActionSet actionSet;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF1FBF8), Color(0xFFF2F7FF)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.electric_meter_outlined,
          color: AppColors.primaryGreen,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Smart Meter 统一验证',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                actionSet.expectedGridDeltaW == null
                    ? '执行前后比较家庭与电网之间的真实功率'
                    : '预计电网反送减少约 ${actionSet.expectedGridDeltaW!.toStringAsFixed(0)} W',
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

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({required this.actionSet});
  final CoordinatedActionSet actionSet;

  String _grid(double? value) {
    if (value == null) return '--';
    final label = value < 0 ? '反送' : '购电';
    return '$label ${value.abs().toStringAsFixed(0)} W';
  }

  @override
  Widget build(BuildContext context) {
    final verified = actionSet.verificationStatus == 'VERIFIED';
    final color = verified ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified_rounded : Icons.info_outline_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verified ? '总表验证通过' : '总表验证未完成',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _MeterValue('执行前', _grid(actionSet.beforeGridPowerW)),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryBlue,
              ),
              Expanded(
                child: _MeterValue(
                  '执行后',
                  _grid(actionSet.afterGridPowerW),
                  end: true,
                ),
              ),
            ],
          ),
          if (actionSet.verificationMessage != null) ...[
            const SizedBox(height: 11),
            Text(
              actionSet.verificationMessage!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MeterValue extends StatelessWidget {
  const _MeterValue(this.label, this.value, {this.end = false});
  final String label, value;
  final bool end;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primaryBlue),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
