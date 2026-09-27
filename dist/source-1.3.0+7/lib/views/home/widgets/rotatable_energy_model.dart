import 'dart:async';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/home_energy_data.dart';

class RotatableEnergyModel extends StatefulWidget {
  const RotatableEnergyModel({
    super.key,
    required this.data,
    required this.selectedFocus,
    required this.onFocusChanged,
    this.onFocusActivated,
    this.enabled = true,
  });

  final HomeEnergyData data;
  final EnergyFocus selectedFocus;
  final ValueChanged<EnergyFocus> onFocusChanged;
  final ValueChanged<EnergyFocus>? onFocusActivated;
  final bool enabled;

  @override
  State<RotatableEnergyModel> createState() => _RotatableEnergyModelState();
}

class _RotatableEnergyModelState extends State<RotatableEnergyModel> {
  dynamic _webViewController;
  bool _isLoaded = false;
  bool _hasError = false;
  bool _interactionEnabled = false;
  Timer? _loadTimeout;
  Timer? _rendererHealthCheck;

  @override
  void initState() {
    super.initState();
    _armLoadTimeout();
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _rendererHealthCheck?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RotatableEnergyModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data ||
        oldWidget.selectedFocus != widget.selectedFocus) {
      _syncHotspots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const _StaticModelPreview();
    }
    if (_hasError) {
      return _ModelFallback(onRetry: _retry);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFF7FBFF)),
          IgnorePointer(
            ignoring: !_interactionEnabled,
            child: ModelViewer(
              key: const ValueKey('guangheng-home-3d'),
              id: 'guangheng-home-model',
              src: 'assets/models/solar_house_360.glb',
              alt: '可旋转的家庭光伏与储能三维模型',
              backgroundColor: const Color(0xFFF7FBFF),
              loading: Loading.eager,
              reveal: Reveal.auto,
              cameraControls: true,
              disablePan: true,
              disableTap: true,
              disableZoom: false,
              touchAction: TouchAction.panY,
              orbitSensitivity: 1,
              autoRotate: false,
              interactionPrompt: InteractionPrompt.none,
              interactionPromptStyle: InteractionPromptStyle.basic,
              orientation: '0deg -90deg 0deg',
              cameraOrbit: '25deg 67deg 20.5m',
              cameraTarget: '0m 3.5m 0m',
              minCameraOrbit: 'auto 48deg 15m',
              maxCameraOrbit: 'auto 82deg 28m',
              minFieldOfView: '24deg',
              maxFieldOfView: '42deg',
              shadowIntensity: 0.75,
              shadowSoftness: 0.9,
              exposure: 1.05,
              minHotspotOpacity: 0,
              maxHotspotOpacity: 1,
              innerModelViewerHtml: _hotspotHtml,
              relatedCss: _hotspotCss,
              relatedJs: _viewerJavaScript,
              debugLogging: false,
              javascriptChannels: {
                JavascriptChannel(
                  'EnergyChannel',
                  onMessageReceived: (message) {
                    switch (message.message) {
                      case 'solar':
                        widget.onFocusChanged(EnergyFocus.solar);
                        widget.onFocusActivated?.call(EnergyFocus.solar);
                      case 'home':
                        widget.onFocusChanged(EnergyFocus.home);
                        widget.onFocusActivated?.call(EnergyFocus.home);
                      case 'battery':
                        widget.onFocusChanged(EnergyFocus.battery);
                        widget.onFocusActivated?.call(EnergyFocus.battery);
                    }
                  },
                ),
                JavascriptChannel(
                  'ModelChannel',
                  onMessageReceived: (message) {
                    if (!mounted) return;
                    if (message.message == 'loaded') {
                      setState(() => _isLoaded = true);
                      _loadTimeout?.cancel();
                      _startRendererHealthCheck();
                      _syncHotspots();
                    } else if (message.message == 'error') {
                      _showFallback();
                    }
                  },
                ),
              },
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
            ),
          ),
          if (!_isLoaded) const IgnorePointer(child: _ModelLoading()),
          Positioned(left: 10, top: 8, child: _FlowStatus(data: widget.data)),
          if (_isLoaded && !_interactionEnabled)
            Positioned(
              right: 10,
              bottom: 8,
              child: _InteractionButton(
                icon: Icons.threed_rotation_rounded,
                label: '旋转 3D',
                onPressed: _enableInteraction,
              ),
            ),
          if (_isLoaded && _interactionEnabled) ...[
            const Positioned(left: 10, bottom: 8, child: _GestureHint()),
            Positioned(
              right: 10,
              bottom: 8,
              child: _InteractionButton(
                icon: Icons.lock_outline_rounded,
                label: '恢复滚动',
                onPressed: _disableInteraction,
                active: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _hotspotHtml =>
      '''
<button class="hotspot solar" slot="hotspot-solar"
  data-position="0m 6.7m 2m" data-normal="0m 0.86m 0.5m"
  data-focus="solar" data-selected="${widget.selectedFocus == EnergyFocus.solar}">
  <span class="hotspot-title"><i></i>光伏</span>
  <strong id="solar-value">${widget.data.solarPowerKw.toStringAsFixed(1)} kW</strong>
  <small>点击查看</small>
</button>
<button class="hotspot home" slot="hotspot-home"
  data-position="2.6m 3.9m 3.45m" data-normal="0m 0m 1m"
  data-focus="home" data-selected="${widget.selectedFocus == EnergyFocus.home}">
  <span class="hotspot-title"><i></i>家庭</span>
  <strong id="home-value">${widget.data.homePowerKw.toStringAsFixed(1)} kW</strong>
  <small>点击查看</small>
</button>
<button class="hotspot battery" slot="hotspot-battery"
  data-position="5.1m 1.2m 2.1m" data-normal="0m 0m 1m"
  data-focus="battery" data-selected="${widget.selectedFocus == EnergyFocus.battery}">
  <span class="hotspot-title"><i></i>电池</span>
  <strong id="battery-value">${widget.data.batterySoc.toStringAsFixed(0)}%</strong>
  <small id="battery-status">${widget.data.batteryCharging ? '充电中' : '待机'}</small>
</button>
''';

  String get _hotspotCss => '''
model-viewer { --poster-color: transparent; }
.hotspot {
  --accent: #2377E8;
  position: relative;
  min-width: 76px;
  padding: 7px 9px;
  border: 1px solid color-mix(in srgb, var(--accent) 42%, #ffffff);
  border-radius: 11px;
  background: rgba(255,255,255,.94);
  color: #14243A;
  box-shadow: 0 4px 14px rgba(20,36,58,.13);
  font-family: system-ui, -apple-system, sans-serif;
  text-align: left;
  line-height: 1.12;
  cursor: pointer;
}
.hotspot[data-selected="true"] {
  border-width: 2px;
  box-shadow: 0 4px 16px color-mix(in srgb, var(--accent) 22%, transparent);
}
.hotspot::after {
  content: '';
  position: absolute;
  width: 16px;
  height: 1.5px;
  background: var(--accent);
  opacity: .72;
}
.hotspot::before {
  content: '';
  position: absolute;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--accent);
}
.hotspot-title { display: block; color: #728096; font-size: 9px; }
.hotspot-title i {
  display: inline-block;
  width: 6px;
  height: 6px;
  margin-right: 4px;
  border-radius: 50%;
  background: var(--accent);
}
.hotspot strong { display: block; margin-top: 2px; font-size: 13px; }
.hotspot small { display: block; margin-top: 2px; color: var(--accent); font-size: 8px; }
.solar {
  --accent: #F5A623;
  transform: translate(-95%, 8%);
}
.solar::after { left: 100%; top: 5px; transform: rotate(-22deg); transform-origin: left; }
.solar::before { left: calc(100% + 14px); top: -1px; }
.home {
  --accent: #2377E8;
  transform: translate(12%, -102%);
}
.home::after { right: 100%; top: calc(100% - 5px); transform: rotate(-22deg); transform-origin: right; }
.home::before { right: calc(100% + 14px); top: calc(100% - 2px); }
.battery {
  --accent: #2DBE7F;
  transform: translate(-112%, -102%);
}
.battery::after { left: 100%; top: calc(100% - 5px); transform: rotate(22deg); transform-origin: left; }
.battery::before { left: calc(100% + 14px); top: calc(100% - 2px); }
''';

  String get _viewerJavaScript => '''
const viewer = document.querySelector('#guangheng-home-model');
document.querySelectorAll('.hotspot').forEach((hotspot) => {
  hotspot.addEventListener('click', () => {
    EnergyChannel.postMessage(hotspot.dataset.focus);
  });
});
viewer.addEventListener('load', () => ModelChannel.postMessage('loaded'));
viewer.addEventListener('error', () => ModelChannel.postMessage('error'));
''';

  Future<void> _syncHotspots() async {
    final controller = _webViewController;
    if (controller == null || !_isLoaded) return;
    final selected = widget.selectedFocus.name;
    final script =
        '''
document.getElementById('solar-value').textContent = '${widget.data.solarPowerKw.toStringAsFixed(1)} kW';
document.getElementById('home-value').textContent = '${widget.data.homePowerKw.toStringAsFixed(1)} kW';
document.getElementById('battery-value').textContent = '${widget.data.batterySoc.toStringAsFixed(0)}%';
document.getElementById('battery-status').textContent = '${widget.data.batteryCharging ? '充电中' : '待机'}';
document.querySelectorAll('.hotspot').forEach((item) => {
  item.dataset.selected = String(item.dataset.focus === '$selected');
});
''';
    try {
      await controller.runJavaScript(script);
    } catch (_) {
      _showFallback();
    }
  }

  void _armLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 15), () {
      if (mounted && !_isLoaded) _showFallback();
    });
  }

  void _startRendererHealthCheck() {
    _rendererHealthCheck?.cancel();
    _rendererHealthCheck = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) async {
      final controller = _webViewController;
      if (!mounted || controller == null || !_isLoaded) return;
      try {
        await controller.runJavaScriptReturningResult(
          'document.querySelector("#guangheng-home-model")?.loaded === true',
        );
      } catch (_) {
        _showFallback();
      }
    });
  }

  void _showFallback() {
    if (!mounted || _hasError) return;
    _loadTimeout?.cancel();
    _rendererHealthCheck?.cancel();
    setState(() {
      _hasError = true;
      _interactionEnabled = false;
    });
  }

  void _retry() {
    _rendererHealthCheck?.cancel();
    setState(() {
      _hasError = false;
      _isLoaded = false;
      _webViewController = null;
      _interactionEnabled = false;
    });
    _armLoadTimeout();
  }

  void _enableInteraction() {
    setState(() => _interactionEnabled = true);
  }

  void _disableInteraction() {
    setState(() => _interactionEnabled = false);
  }
}

class _FlowStatus extends StatelessWidget {
  const _FlowStatus({required this.data});

  final HomeEnergyData data;

  @override
  Widget build(BuildContext context) {
    final isActive = data.solarPowerKw >= 0.05;
    final label = data.batteryCharging ? '光伏供电 · 储能充电' : '光伏优先供电';
    return Semantics(
      label: isActive ? label : '当前无明显能量流动',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: Container(
          key: ValueKey('$isActive-${data.batteryCharging}'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryGreen
                      : AppColors.navInactive,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? label : '能量流已停止',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelLoading extends StatelessWidget {
  const _ModelLoading();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF7FBFF)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/home_energy_house.png',
              fit: BoxFit.contain,
              opacity: const AlwaysStoppedAnimation(0.62),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticModelPreview extends StatelessWidget {
  const _StaticModelPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: const Color(0xFFF7FBFF),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/home_energy_house.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _GestureHint extends StatelessWidget {
  const _GestureHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_rounded, size: 14, color: AppColors.primaryBlue),
          SizedBox(width: 5),
          Text(
            '3D 交互中 · 左右旋转 · 双指缩放',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: active ? '退出三维模型交互并恢复页面滚动' : '进入三维模型旋转模式',
    child: Material(
      color: active
          ? AppColors.primaryBlue
          : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.primaryBlue : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ModelFallback extends StatelessWidget {
  const _ModelFallback({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF7FBFF)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/home_energy_house.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.home_work_rounded,
              size: 88,
              color: Color(0xFFB9CAD9),
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('重试 3D'),
          ),
        ),
      ],
    );
  }
}
