enum EnergyFocus { solar, home, battery, saving }

class HomeEnergyData {
  const HomeEnergyData({
    required this.solarPowerKw,
    required this.homePowerKw,
    required this.batterySoc,
    required this.batteryCharging,
  });

  final double solarPowerKw;
  final double homePowerKw;
  final double batterySoc;
  final bool batteryCharging;
}
