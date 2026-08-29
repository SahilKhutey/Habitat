// Habitat Domain Event System & Event Bus
import 'dart:async';
import 'package:flutter/foundation.dart';

@immutable
sealed class HabitatEvent {
  final DateTime timestamp;
  HabitatEvent() : timestamp = DateTime.now();
}

class TaskCompletedEvent extends HabitatEvent {
  final String taskId;
  final int earnedXp;

  TaskCompletedEvent({required this.taskId, this.earnedXp = 10});
}

class AlarmTriggeredEvent extends HabitatEvent {
  final String alarmId;
  final String taskId;

  AlarmTriggeredEvent({required this.alarmId, required this.taskId});
}

class AlarmCompletedEvent extends HabitatEvent {
  final String alarmId;
  final String taskId;

  AlarmCompletedEvent({required this.alarmId, required this.taskId});
}

class WaterLoggedEvent extends HabitatEvent {
  final int amountMl;

  WaterLoggedEvent({required this.amountMl});
}

class MealLoggedEvent extends HabitatEvent {
  final String slot;
  final String name;

  MealLoggedEvent({required this.slot, required this.name});
}

class NapCompletedEvent extends HabitatEvent {
  final int durationMinutes;

  NapCompletedEvent({required this.durationMinutes});
}

class AchievementUnlockedEvent extends HabitatEvent {
  final String achievementKey;

  AchievementUnlockedEvent({required this.achievementKey});
}

class HabitatEventBus {
  static final HabitatEventBus instance = HabitatEventBus._();
  HabitatEventBus._();

  final _controller = StreamController<HabitatEvent>.broadcast();

  Stream<HabitatEvent> get stream => _controller.stream;

  void publish(HabitatEvent event) {
    _controller.add(event);
  }
}
