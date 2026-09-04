// Battery Optimization & Native Capability Service Abstraction (Milestone C2 / C3)
import 'dart:io';
import 'package:flutter/services.dart';

abstract class IBatteryOptimizationService {
  Future<bool> isOptimizationIgnored();
  Future<void> openBatterySettings();
  Future<bool> canScheduleExactAlarms();
  Future<void> openExactAlarmSettings();
  Future<String> getDeviceManufacturer();
}

class BatteryOptimizationService implements IBatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('habitat/native_alarm');

  static final BatteryOptimizationService instance =
      BatteryOptimizationService._internal();
  BatteryOptimizationService._internal();

  @override
  Future<bool> isOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (e) {
      // Ignored
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openExactAlarmSettings');
    } catch (e) {
      // Ignored
    }
  }

  @override
  Future<String> getDeviceManufacturer() async {
    if (Platform.isIOS) return 'Apple';
    if (!Platform.isAndroid) return 'Generic';
    try {
      final result =
          await _channel.invokeMethod<String>('getDeviceManufacturer');
      return result ?? 'Android';
    } catch (_) {
      return 'Android';
    }
  }
}
