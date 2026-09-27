import 'package:flutter_test/flutter_test.dart';
import 'package:guangheng/core/utils/energy_cost_level.dart';

void main() {
  test('daily grid cost is high only from 20 CNY', () {
    expect(isHighDailyGridCost(7.20), isFalse);
    expect(isHighDailyGridCost(19.99), isFalse);
    expect(isHighDailyGridCost(20), isTrue);
    expect(isHighDailyGridCost(20.01), isTrue);
  });
}
