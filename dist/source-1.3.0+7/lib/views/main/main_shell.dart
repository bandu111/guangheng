import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_durations.dart';
import '../../viewmodels/main_view_model.dart';
import '../../viewmodels/backend_view_model.dart';
import '../../services/local_notification_service.dart';
import '../device/device_page.dart';
import '../home/home_page.dart';
import '../report/report_page.dart';
import '../shared/motion_widgets.dart';
import '../shared/real_data_widgets.dart';
import '../strategy/strategy_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.enableInteractive3d = true});

  final bool enableInteractive3d;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  late final PageController controller;
  late final NotificationInteractionHandler notificationHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationHandler = _handleNotificationInteraction;
    LocalNotificationService.instance.setInteractionHandler(
      notificationHandler,
    );
    controller = PageController(
      initialPage: context.read<MainViewModel>().currentIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocalNotificationService.instance.requestPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalNotificationService.instance.clearInteractionHandler(
      notificationHandler,
    );
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<BackendViewModel>().refresh();
    }
  }

  Future<void> _handleNotificationInteraction(int? eventId) async {
    if (!mounted) return;
    final backend = context.read<BackendViewModel>();
    if (eventId != null) {
      await LocalNotificationService.instance.cancelEvent(eventId);
      try {
        await backend.markRead(eventId);
      } catch (_) {
        await backend.refresh();
      }
    } else {
      await backend.refresh();
    }
    if (!mounted) return;
    final proposal = backend.data?.autonomy?.pendingProposal;
    await _select(proposal == null ? 0 : 1);
    if (proposal != null && mounted) {
      await showPendingProposalActions(context, proposal);
    }
  }

  Future<void> _select(int index) async {
    final vm = context.read<MainViewModel>();
    if (index == vm.currentIndex) return;
    HapticFeedback.selectionClick();
    vm.changeTab(index);
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpToPage(index);
    } else {
      await controller.animateToPage(
        index,
        duration: AppDurations.page,
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<MainViewModel>().currentIndex;
    return Scaffold(
      extendBody: true,
      body: AmbientPageBackground(
        child: PageView(
          controller: controller,
          // Navigation still slides between pages, while user-driven horizontal
          // paging stays disabled so it never competes with the 3D model orbit.
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            if (index != context.read<MainViewModel>().currentIndex) {
              context.read<MainViewModel>().changeTab(index);
            }
          },
          children: [
            HomePage(enableInteractive3d: widget.enableInteractive3d),
            const StrategyPage(),
            const ReportPage(),
            const DevicePage(),
          ],
        ),
      ),
      bottomNavigationBar: _FloatingNavigationBar(
        selectedIndex: current,
        onSelected: _select,
      ),
    );
  }
}

class _FloatingNavigationBar extends StatelessWidget {
  const _FloatingNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.bolt_outlined, Icons.bolt_rounded, '策略'),
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, '报表'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, '设备'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Container(
      height: 68,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C152D4D),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDurations.spring,
                curve: Curves.easeOutBack,
                left: itemWidth * selectedIndex,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F1FF), Color(0xFFF1F6FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: Semantics(
                        selected: selectedIndex == index,
                        button: true,
                        label: items[index].$3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onSelected(index),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: selectedIndex == index ? 1.08 : .96,
                                duration: AppDurations.normal,
                                child: Icon(
                                  selectedIndex == index
                                      ? items[index].$2
                                      : items[index].$1,
                                  size: 22,
                                  color: selectedIndex == index
                                      ? AppColors.primaryBlue
                                      : AppColors.navInactive,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AnimatedDefaultTextStyle(
                                duration: AppDurations.normal,
                                style: TextStyle(
                                  color: selectedIndex == index
                                      ? AppColors.textPrimary
                                      : AppColors.navInactive,
                                  fontSize: 10,
                                  fontWeight: selectedIndex == index
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                child: Text(items[index].$3),
                              ),
                            ],
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
    ),
  );
}
