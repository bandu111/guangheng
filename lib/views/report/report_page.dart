import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../core/utils/energy_cost_level.dart';
import '../../models/backend_models.dart';
import '../../models/demo_metrics.dart';
import '../../viewmodels/backend_view_model.dart';
import '../shared/real_data_widgets.dart';
import '../shared/motion_widgets.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int period = 0;
  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackendViewModel>();
    final data = vm.data;
    if (vm.loading && data == null) return const PageSkeleton(title: '报表');
    final periodData =
        data?.report?.periods[['today', 'week', 'month'][period]];
    final metrics = periodData?.metrics;
    final coverage = periodData?.coveragePercent;
    final coverageLabel = coverage == null
        ? '暂无历史数据'
        : '数据覆盖 ${coverage.toStringAsFixed(0)}%';
    final records = <(DateTime?, String, String, Color)>[
      ...data?.decisions.map(
            (x) => (
              x.completedAt,
              '光衡完成能源分析',
              x.actionRequired == true
                  ? '建议 ${displayValue(x.currentValue, suffix: '%')} → ${displayValue(x.targetValue, suffix: '%')}'
                  : reasonLabel(x.reasonCode),
              AppColors.primaryBlue,
            ),
          ) ??
          [],
      ...data?.proposals.map(
            (x) => (x.time, x.title, x.detail, AppColors.solarOrange),
          ) ??
          [],
      ...data?.executions.map(
            (x) => (x.time, x.title, x.detail, AppColors.primaryGreen),
          ) ??
          [],
    ]..sort((a, b) => (b.$1 ?? DateTime(1970)).compareTo(a.$1 ?? DateTime(1970)));
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
                title: '报表',
                actions: [
                  RoundIconButton(
                    icon: Icons.calendar_month_outlined,
                    onPressed: () => _showCalendar(context, data?.report),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StaggeredReveal(
              order: 1,
              child: _PeriodSelector(
                value: period,
                onChanged: (value) => setState(() => period = value),
              ),
            ),
            const SizedBox(height: 24),
            const _ReportTitle('能源概览'),
            const SizedBox(height: 12),
            StaggeredReveal(
              order: 2,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.05,
                children: [
                  _OverviewMetric(
                    '总用电',
                    _metric(metrics?.consumptionKwh, ' kWh'),
                    coverageLabel,
                    Icons.home_rounded,
                    AppColors.primaryBlue,
                    AppColors.primaryBlueSoft,
                  ),
                  _OverviewMetric(
                    '光伏自用率',
                    _metric(metrics?.solarSelfUsePercent, '%'),
                    coverageLabel,
                    Icons.wb_sunny_rounded,
                    AppColors.solarOrange,
                    AppColors.solarOrangeSoft,
                  ),
                  _OverviewMetric(
                    '电网购电',
                    _metric(metrics?.gridImportKwh, ' kWh'),
                    coverageLabel,
                    Icons.bolt_rounded,
                    Color(0xFF315C8E),
                    Color(0xFFEDF2F8),
                  ),
                  _OverviewMetric(
                    '智能节省',
                    _money(metrics?.savingsCny),
                    coverageLabel,
                    Icons.eco_rounded,
                    AppColors.primaryGreen,
                    AppColors.primaryGreenSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _ReportTitle('参考基线 vs 实际购电', subtitle: '同一统计周期 · 全国居民参考平均价'),
            const SizedBox(height: 12),
            StaggeredReveal(
              order: 3,
              child: _ComparisonCard(
                metrics: metrics,
                tariff: data?.report?.tariffPricePerKwh,
              ),
            ),
            const SizedBox(height: 24),
            const _ReportTitle('节省趋势'),
            const SizedBox(height: 12),
            _SavingChart(
              period: ['today', 'week', 'month'][period],
              points: periodData?.daily ?? const [],
            ),
            const SizedBox(height: 14),
            _InsightCard(
              metrics: metrics,
              carbonProvider: data?.report?.carbonProvider,
              carbonReferenceYear: data?.report?.carbonReferenceYear,
            ),
            const SizedBox(height: 24),
            const _ReportTitle('决策与执行记录', subtitle: '证据、批准、执行与回读在同一时间线'),
            const SizedBox(height: 12),
            _Timeline(records: records),
            const SizedBox(height: 16),
            const _ResilienceCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _showCalendar(BuildContext context, EnergyReport? report) async {
    var focused = selectedDay;
    final daily =
        report?.periods['month']?.daily ?? const <EnergyReportDailyPoint>[];
    EnergyReportDailyPoint? pointFor(DateTime day) {
      for (final point in daily) {
        if (isSameDay(point.date, day)) return point;
      }
      return null;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '选择日期',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              TableCalendar<void>(
                locale: 'zh_CN',
                firstDay: DateTime(2024),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: focused,
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                onDaySelected: (selected, focus) {
                  setState(() => selectedDay = selected);
                  setSheetState(() => focused = focus);
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: .2),
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders<void>(
                  markerBuilder: (context, day, events) {
                    final cost = pointFor(day)?.actualGridCostCny;
                    if (cost == null) return null;
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isHighDailyGridCost(cost)
                              ? AppColors.danger
                              : AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedDay.month}月${selectedDay.day}日购电支出',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _calendarCostExplanation(
                              pointFor(selectedDay),
                              report?.tariffPricePerKwh,
                            ),
                            style: const TextStyle(
                              color: AppColors.navInactive,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(pointFor(selectedDay)?.actualGridCostCny),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CalendarLegend(AppColors.primaryGreen, '支出较低（<¥20）'),
                  SizedBox(width: 16),
                  _CalendarLegend(AppColors.danger, '支出较高（≥¥20）'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EFF7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth / 3;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 340),
              curve: Curves.easeOutBack,
              left: value * width,
              top: 0,
              bottom: 0,
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: value == i
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: value == i
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                          child: Text(['今日', '本周', '本月'][i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _ReportTitle extends StatelessWidget {
  const _ReportTitle(this.title, {this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
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
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ],
  );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric(
    this.title,
    this.value,
    this.trend,
    this.icon,
    this.color,
    this.softColor,
  );
  final String title, value, trend;
  final IconData icon;
  final Color color, softColor;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.metrics, required this.tariff});
  final EnergyReportMetrics? metrics;
  final double? tariff;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Cost('参考基线', _money(metrics?.referenceBaselineCostCny)),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textSecondary,
              ),
              _Cost('实际购电', _money(metrics?.actualGridCostCny), blue: true),
              _Cost('节省', _money(metrics?.savingsCny), green: true),
            ],
          ),
          const SizedBox(height: 20),
          _CostBar(
            '参考基线',
            metrics?.referenceBaselineCostCny == null ? 0 : 1,
            const Color(0xFFB9C9DA),
          ),
          const SizedBox(height: 10),
          _CostBar(
            '实际购电',
            _ratio(
              metrics?.actualGridCostCny,
              metrics?.referenceBaselineCostCny,
            ),
            AppColors.primaryBlue,
          ),
          const SizedBox(height: 13),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              tariff == null
                  ? '参考电价暂不可用'
                  : '参考基线：全部家庭用电按 ¥${tariff!.toStringAsFixed(2)}/kWh 计算',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Cost extends StatelessWidget {
  const _Cost(this.label, this.value, {this.blue = false, this.green = false});
  final String label, value;
  final bool blue, green;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: blue
              ? AppColors.primaryBlue
              : green
              ? AppColors.success
              : AppColors.textPrimary,
        ),
      ),
    ],
  );
}

class _CostBar extends StatelessWidget {
  const _CostBar(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 58,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            color: color,
            backgroundColor: AppColors.divider,
          ),
        ),
      ),
    ],
  );
}

class _SavingChart extends StatefulWidget {
  const _SavingChart({required this.period, required this.points});

  final String period;
  final List<EnergyReportDailyPoint> points;

  @override
  State<_SavingChart> createState() => _SavingChartState();
}

class _SavingChartState extends State<_SavingChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: AppDurations.timeline,
  );
  bool visible = false;

  @override
  void didUpdateWidget(covariant _SavingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (visible &&
        (oldWidget.period != widget.period ||
            oldWidget.points != widget.points)) {
      controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _label(EnergyReportDailyPoint point) => switch (widget.period) {
    'today' => '今日',
    'week' =>
      '周${const ['一', '二', '三', '四', '五', '六', '日'][point.date.weekday - 1]}',
    _ => '${point.date.day}日',
  };

  @override
  Widget build(BuildContext context) {
    final recorded = widget.points
        .where((point) => point.savingsCny != null)
        .toList();
    final visiblePoints = recorded.length > 7
        ? recorded.sublist(recorded.length - 7)
        : recorded;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return VisibilityDetector(
      key: ValueKey('saving-chart-${widget.period}'),
      onVisibilityChanged: (info) {
        if (visible || info.visibleFraction < .18) return;
        visible = true;
        if (reduceMotion) {
          controller.value = 1;
        } else {
          controller.forward(from: 0);
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '最近节省表现',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '累计节省',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _money(
                          recorded.fold<double>(
                            0,
                            (sum, item) => sum + item.savingsCny!,
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                key: const Key('saving-trend-chart'),
                height: 184,
                width: double.infinity,
                child: recorded.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无节省历史',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : CustomPaint(
                        painter: _SavingPainter(
                          values: visiblePoints
                              .map((item) => item.savingsCny!)
                              .toList(),
                          animation: CurvedAnimation(
                            parent: controller,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
              ),
              DefaultTextStyle(
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
                child: Row(
                  children: visiblePoints
                      .map(
                        (item) => Expanded(
                          child: Text(
                            _label(item),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              if (recorded.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '滑动到此处自动展示 · 金额为参考电价估算',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
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

class _SavingPainter extends CustomPainter {
  _SavingPainter({required this.values, required this.animation})
    : super(repaint: animation);

  final List<double> values;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const chartTop = 29.0;
    final chartBottom = size.height - 6;
    final chartHeight = chartBottom - chartTop;
    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartTop + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Path();
    final points = <Offset>[];
    final maximum = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final progress = animation.value;
    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i + .5) / values.length;
      final targetY = maximum <= 0
          ? chartBottom
          : chartBottom - values[i] / maximum * chartHeight * .82;
      final y = chartBottom + (targetY - chartBottom) * progress;
      points.add(Offset(x, targetY));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 10, y, 20, chartBottom - y),
          const Radius.circular(5),
        ),
        Paint()..color = AppColors.primaryBlue.withValues(alpha: .13),
      );
      if (i == 0) {
        line.moveTo(x, targetY);
      } else {
        line.lineTo(x, targetY);
      }
    }
    canvas.save();
    final revealWidth = values.length == 1
        ? size.width * progress
        : size.width * progress;
    canvas.clipRect(Rect.fromLTWH(0, 0, revealWidth, size.height));
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, 3.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        point,
        3.5,
        Paint()
          ..color = AppColors.primaryBlue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final label = TextPainter(
        text: TextSpan(
          text: '¥${values[i].toStringAsFixed(2)}',
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (point.dx - label.width / 2).clamp(0, size.width - label.width),
          (point.dy - label.height - 7).clamp(0, chartBottom - label.height),
        ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SavingPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.animation != animation;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.metrics,
    this.carbonProvider,
    this.carbonReferenceYear,
  });

  final EnergyReportMetrics? metrics;
  final String? carbonProvider;
  final int? carbonReferenceYear;

  @override
  Widget build(BuildContext context) => PressableScale(
    borderRadius: BorderRadius.circular(20),
    onTap: () => _showCarbonDetails(context),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FAF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metrics?.savingsPercent == null
                      ? '本期节省暂不可计算'
                      : '相比参考基线，本期节省 ${metrics!.savingsPercent!.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metrics?.carbonReductionKg == null
                      ? '碳减排数据仍在积累'
                      : '预计减少约 ${metrics!.carbonReductionKg!.toStringAsFixed(2)} kg 碳排放',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );

  Future<void> _showCarbonDetails(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '碳减排估算',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            metrics?.carbonReductionKg == null
                ? '当前有效历史数据不足，暂时无法计算。'
                : '本期预计减少 ${metrics!.carbonReductionKg!.toStringAsFixed(2)} kg CO₂。该结果根据减少的电网购电量与公开排放因子估算。',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '数据来源：${carbonProvider ?? '--'} · ${carbonReferenceYear ?? '--'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.records});
  final List<(DateTime?, String, String, Color)> records;
  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const EmptyDataCard(title: '暂无记录', message: '真实决策、方案与执行发生后将在这里显示');
    }
    final visible = records.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: visible[i].$4,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visible[i].$2,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            visible[i].$3,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _date(visible[i].$1),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
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
}

class _ResilienceCard extends StatelessWidget {
  const _ResilienceCard();
  @override
  Widget build(BuildContext context) => const Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryGreenSoft,
        child: Icon(Icons.shield_outlined, color: AppColors.primaryGreen),
      ),
      title: Text('家庭能源韧性', style: TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('按冰箱、路由器与基础照明估算 · 模拟'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${DemoMetrics.resilienceHours} 小时',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '预计备电',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend(this.color, this.label);
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
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    ],
  );
}

String _date(DateTime? date) {
  if (date == null) return '--';
  final local = date.toLocal();
  final now = DateTime.now();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (isToday) return time;
  return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} $time';
}

String _metric(double? value, String suffix) =>
    value == null ? '--' : '${value.toStringAsFixed(1)}$suffix';

String _money(double? value) =>
    value == null ? '--' : '¥${value.toStringAsFixed(2)}';

String _calendarCostExplanation(EnergyReportDailyPoint? point, double? tariff) {
  if (point == null || point.gridImportKwh == null) return '该日期暂无有效购电记录';
  final price = tariff == null
      ? ''
      : ' · 参考价 ¥${tariff.toStringAsFixed(2)}/kWh';
  if (point.gridImportKwh! <= 0) return '当日未从电网购电$price';
  return '购电 ${point.gridImportKwh!.toStringAsFixed(2)} kWh$price';
}

double _ratio(double? value, double? baseline) {
  if (value == null || baseline == null || baseline <= 0) return 0;
  return (value / baseline).clamp(0, 1);
}
