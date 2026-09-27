import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/backend_models.dart';
import '../repositories/backend_repository.dart';

class BackendViewModel extends ChangeNotifier {
  BackendViewModel(this.repository, {this.data, this.notificationSync});
  final BackendRepository repository;
  final Future<void> Function(List<NotificationEventModel>, int)?
  notificationSync;
  BackendSnapshot? data;
  bool loading = false,
      refreshing = false,
      switching = false,
      switchingAutonomy = false,
      resolvingActionSet = false;
  bool pairingCompanion = false;
  String? error;
  List<CompanionTerminal> companions = const [];
  final Set<String> busyDevices = {};
  Timer? _timer;
  Future<void> load() async {
    if (data == null) {
      loading = true;
      notifyListeners();
    } else {
      refreshing = true;
      notifyListeners();
    }
    try {
      final next = await repository.load();
      data = next;
      try {
        companions = await repository.listCompanionTerminals();
      } catch (_) {
        // Companion management is optional and must not hide valid household
        // energy data when an older backend has not deployed the endpoint yet.
      }
      try {
        await notificationSync?.call(
          next.notifications,
          next.autonomy?.unreadCount ?? 0,
        );
      } catch (_) {
        // Notification delivery must never turn valid energy data into a
        // backend loading error.
      }
      error = null;
    } catch (_) {
      error = '部分服务暂不可用';
    } finally {
      loading = false;
      refreshing = false;
      notifyListeners();
      _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => refresh());
    }
  }

  Future<void> refresh() => load();
  Future<bool> setStrategy(String mode) async {
    final old = data?.strategy;
    switching = true;
    notifyListeners();
    try {
      final next = await repository.updateStrategy(mode);
      data = BackendSnapshot(
        energy: data?.energy,
        today: data?.today,
        schedule: data?.schedule,
        report: data?.report,
        weather: data?.weather,
        solar: data?.solar,
        load: data?.load,
        strategy: next,
        autonomy: data?.autonomy,
        notifications: data?.notifications ?? const [],
        decisions: data?.decisions ?? const [],
        proposals: data?.proposals ?? const [],
        executions: data?.executions ?? const [],
        station: data?.station,
        batteryInsight: data?.batteryInsight,
        devices: data?.devices ?? const [],
        health: data?.health,
        criticalLoads: data?.criticalLoads,
        profiles: data?.profiles ?? const [],
        areaLoads: data?.areaLoads,
        meterInsights: data?.meterInsights ?? const {},
        solarArrays: data?.solarArrays ?? const {},
        actionSet: data?.actionSet,
      );
      return true;
    } catch (_) {
      if (old != null) {}
      error = '策略更新失败，当前选择未改变';
      return false;
    } finally {
      switching = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    await repository.markRead(id);
    await refresh();
  }

  Future<bool> setAutonomyLevel(String level) async {
    switchingAutonomy = true;
    notifyListeners();
    try {
      final selected = await repository.updateAutonomyLevel(level);
      final current = data;
      if (current != null) {
        data = BackendSnapshot(
          energy: current.energy,
          today: current.today,
          schedule: current.schedule,
          report: current.report,
          weather: current.weather,
          solar: current.solar,
          load: current.load,
          strategy: current.strategy,
          autonomy: current.autonomy?.copyWith(autonomyLevel: selected),
          notifications: current.notifications,
          decisions: current.decisions,
          proposals: current.proposals,
          executions: current.executions,
          station: current.station,
          batteryInsight: current.batteryInsight,
          devices: current.devices,
          health: current.health,
          criticalLoads: current.criticalLoads,
          profiles: current.profiles,
          areaLoads: current.areaLoads,
          meterInsights: current.meterInsights,
          solarArrays: current.solarArrays,
          actionSet: current.actionSet,
        );
      }
      error = null;
      return true;
    } catch (_) {
      error = '自治级别更新失败，当前权限未改变';
      return false;
    } finally {
      switchingAutonomy = false;
      notifyListeners();
    }
  }

  Future<bool> resolveProposal(int id, {required bool approve}) async {
    try {
      if (approve) {
        await repository.approveProposal(id);
      } else {
        await repository.rejectProposal(id);
      }
      await refresh();
      return true;
    } catch (_) {
      error = approve ? '方案执行失败，请查看安全检查结果' : '方案拒绝失败';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveActionSet(int id, {required bool approve}) async {
    if (resolvingActionSet) return false;
    resolvingActionSet = true;
    notifyListeners();
    try {
      var current = approve
          ? await repository.approveActionSet(id)
          : await repository.rejectActionSet(id);
      if (data != null) data = data!.copyWith(actionSet: current);
      notifyListeners();
      if (approve) {
        final deadline = DateTime.now().add(const Duration(seconds: 45));
        while (!current.isTerminal && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 650));
          current = await repository.getActionSet(id);
          if (data != null) data = data!.copyWith(actionSet: current);
          notifyListeners();
        }
        if (!current.isTerminal) {
          error = '协同方案仍在执行，可稍后在策略页查看进度';
          return false;
        }
      }
      await refresh();
      return approve ? current.status == 'SUCCEEDED' : true;
    } catch (_) {
      error = approve ? '协同执行未完成，请查看分步结果' : '暂不执行操作失败';
      notifyListeners();
      return false;
    } finally {
      resolvingActionSet = false;
      notifyListeners();
    }
  }

  Future<bool> addCriticalLoad(
    String name,
    String category,
    double ratedPowerW,
  ) async {
    try {
      await repository.addCriticalLoad(
        name: name,
        category: category,
        ratedPowerW: ratedPowerW,
      );
      await refresh();
      return true;
    } catch (_) {
      error = '关键负载保存失败';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setCriticalLoadEnabled(int id, bool enabled) async {
    try {
      await repository.setCriticalLoadEnabled(id, enabled);
      await refresh();
      return true;
    } catch (_) {
      error = '关键负载状态更新失败';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCriticalLoad(int id) async {
    try {
      await repository.deleteCriticalLoad(id);
      await refresh();
      return true;
    } catch (_) {
      error = '关键负载删除失败';
      notifyListeners();
      return false;
    }
  }

  Future<bool> bindDevice(String sourceDeviceId) async {
    busyDevices.add(sourceDeviceId);
    notifyListeners();
    try {
      await repository.bindDevice(sourceDeviceId);
      await refresh();
      return true;
    } catch (_) {
      error = '设备接入失败，请检查当前发现结果';
      notifyListeners();
      return false;
    } finally {
      busyDevices.remove(sourceDeviceId);
      notifyListeners();
    }
  }

  Future<bool> setDeviceControlEnabled(int id, bool enabled) async {
    final key = 'bound:$id';
    busyDevices.add(key);
    notifyListeners();
    try {
      await repository.setDeviceControlEnabled(id, enabled);
      await refresh();
      return true;
    } catch (_) {
      error = '设备控制权限更新失败';
      notifyListeners();
      return false;
    } finally {
      busyDevices.remove(key);
      notifyListeners();
    }
  }

  Future<bool> confirmCompanionPairing(String code) async {
    final normalized = code.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(normalized)) {
      error = '请输入设备屏幕显示的 6 位配对码';
      notifyListeners();
      return false;
    }
    pairingCompanion = true;
    notifyListeners();
    try {
      await repository.confirmCompanionPairing(normalized);
      companions = await repository.listCompanionTerminals();
      error = null;
      return true;
    } catch (_) {
      error = '配对失败，请确认设备在线且配对码未过期';
      return false;
    } finally {
      pairingCompanion = false;
      notifyListeners();
    }
  }

  Future<bool> revokeCompanion(String deviceUid) async {
    try {
      await repository.revokeCompanion(deviceUid);
      companions = await repository.listCompanionTerminals();
      notifyListeners();
      return true;
    } catch (_) {
      error = '撤销设备失败，请稍后重试';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setSmartPlugPower(int id, bool targetOn) async {
    final key = 'bound:$id';
    busyDevices.add(key);
    notifyListeners();
    try {
      final status = await repository.setSmartPlugPower(id, targetOn);
      await refresh();
      if (status != 'SUCCEEDED') {
        error = status == 'BLOCKED'
            ? '安全检查已阻断：该控制能力尚未完成实机验证'
            : '设备没有通过执行回读，请查看执行记录';
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      error = '智能插座控制失败，设备状态未被假定修改';
      notifyListeners();
      return false;
    } finally {
      busyDevices.remove(key);
      notifyListeners();
    }
  }

  Future<bool> setStorageControl(
    DiscoveredDevice device,
    DeviceCapability capability,
    double targetValue,
  ) async {
    final id = device.boundDeviceId;
    if (id == null) return false;
    final key = 'bound:$id';
    busyDevices.add(key);
    notifyListeners();
    try {
      final status = await repository.setStorageControl(
        id,
        capability.name,
        targetValue,
      );
      await refresh();
      if (status != 'SUCCEEDED') {
        error = status == 'BLOCKED'
            ? '安全检查已阻断：请检查控制权限、能力验证和实时状态'
            : '设备没有通过执行回读，当前值未被假定修改';
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      error = '储能控制失败，设备状态未被假定修改';
      notifyListeners();
      return false;
    } finally {
      busyDevices.remove(key);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
