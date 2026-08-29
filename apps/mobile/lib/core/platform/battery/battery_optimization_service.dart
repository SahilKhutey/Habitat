// Habitat Android OEM Battery Optimization Exemption Service
import 'package:flutter/foundation.dart';

abstract interface class BatteryOptimizationService {
  Future<bool> isIgnoringBatteryOptimizations();
  Future<bool> requestExemption();

  factory BatteryOptimizationService.create() {
    return DefaultBatteryOptimizationService();
  }
}

class DefaultBatteryOptimizationService implements BatteryOptimizationService {
  bool _isExempt = true;

  @override
  Future<bool> isIgnoringBatteryOptimizations() async {
    // In production on Android, checks PowerManager.isIgnoringBatteryOptimizations()
    return _isExempt;
  }

  @override
  Future<bool> requestExemption() async {
    // In production on Android, triggers ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
    _isExempt = true;
    return true;
  }
}
