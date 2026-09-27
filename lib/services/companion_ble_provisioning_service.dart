import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CompanionBleProvisioningService {
  static final Guid serviceUuid = Guid('7f510001-8f7c-4a92-b9ce-8c0d5f472a10');
  static final Guid credentialsUuid = Guid(
    '7f510002-8f7c-4a92-b9ce-8c0d5f472a10',
  );
  static final Guid statusUuid = Guid('7f510003-8f7c-4a92-b9ce-8c0d5f472a10');

  Future<void> provision({
    required String ssid,
    required String password,
    void Function(String message)? onProgress,
  }) async {
    final network = ssid.trim();
    if (network.isEmpty || utf8.encode(network).length > 32) {
      throw const FormatException('Wi-Fi 名称不能为空且不能超过 32 字节');
    }
    if (utf8.encode(password).length > 64) {
      throw const FormatException('Wi-Fi 密码不能超过 64 字节');
    }
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('当前手机不支持蓝牙低功耗连接');
    }
    onProgress?.call('等待手机蓝牙开启');
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('请开启手机蓝牙后重试'),
        );

    BluetoothDevice? device;
    try {
      onProgress?.call('正在查找光衡随身终端');
      final resultFuture = FlutterBluePlus.onScanResults
          .expand((results) => results)
          .firstWhere(
            (result) =>
                result.advertisementData.serviceUuids.contains(serviceUuid) ||
                result.advertisementData.advName == 'GuangHeng Companion',
          )
          .timeout(const Duration(seconds: 18));
      await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        timeout: const Duration(seconds: 18),
      );
      device = (await resultFuture).device;
      await FlutterBluePlus.stopScan();

      onProgress?.call('正在建立加密连接');
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 20),
      );
      final services = await device.discoverServices();
      final service = services
          .where((item) => item.serviceUuid == serviceUuid)
          .firstOrNull;
      if (service == null) throw StateError('设备未提供光衡配网服务');
      final credentials = service.characteristics
          .where((item) => item.characteristicUuid == credentialsUuid)
          .firstOrNull;
      final status = service.characteristics
          .where((item) => item.characteristicUuid == statusUuid)
          .firstOrNull;
      if (credentials == null || status == null) {
        throw StateError('设备配网服务版本不兼容');
      }

      onProgress?.call('请核对设备屏幕上的蓝牙安全码');
      final payload = utf8.encode(
        jsonEncode({'ssid': network, 'password': password}),
      );
      await credentials.write(payload, allowLongWrite: true);

      onProgress?.call('设备正在连接 Wi-Fi');
      final deadline = DateTime.now().add(const Duration(seconds: 35));
      while (DateTime.now().isBefore(deadline)) {
        final value = utf8.decode(await status.read(), allowMalformed: true);
        if (value == 'connected') {
          onProgress?.call('Wi-Fi 配置成功');
          return;
        }
        if (value == 'failed' ||
            value == 'storage_error' ||
            value == 'invalid') {
          throw StateError('设备未能连接 Wi-Fi，请检查名称和密码');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      throw TimeoutException('设备连接 Wi-Fi 超时，请检查路由器信号');
    } on TimeoutException catch (error) {
      throw StateError(error.message ?? '未找到设备，请让终端保持亮屏并靠近手机');
    } finally {
      await FlutterBluePlus.stopScan();
      if (device != null) {
        try {
          await device.disconnect();
        } catch (_) {}
      }
    }
  }
}
