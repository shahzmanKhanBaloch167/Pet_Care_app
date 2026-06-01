import 'dart:convert';

class DietPlan {
  final List<String> feedingSchedule; // e.g., ["08:00", "18:00"]
  final List<String> recommendedFoods;
  final List<String> restrictedFoods;
  final int dailyWaterTargetMl;
  final int waterIntakeMl;
  final int waterReminderIntervalHours;
  /// Tracks the date when waterIntakeMl was last reset, used for daily reset
  final DateTime? lastWaterResetDate;
  final bool waterRemindersActive;

  DietPlan({
    this.feedingSchedule = const [],
    this.recommendedFoods = const [],
    this.restrictedFoods = const [],
    this.dailyWaterTargetMl = 0,
    this.waterIntakeMl = 0,
    this.waterReminderIntervalHours = 2,
    this.lastWaterResetDate,
    this.waterRemindersActive = false,
  });

  DietPlan copyWith({
    List<String>? feedingSchedule,
    List<String>? recommendedFoods,
    List<String>? restrictedFoods,
    int? dailyWaterTargetMl,
    int? waterIntakeMl,
    int? waterReminderIntervalHours,
    DateTime? lastWaterResetDate,
    bool? waterRemindersActive,
  }) {
    return DietPlan(
      feedingSchedule: feedingSchedule ?? this.feedingSchedule,
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      restrictedFoods: restrictedFoods ?? this.restrictedFoods,
      dailyWaterTargetMl: dailyWaterTargetMl ?? this.dailyWaterTargetMl,
      waterIntakeMl: waterIntakeMl ?? this.waterIntakeMl,
      waterReminderIntervalHours: waterReminderIntervalHours ?? this.waterReminderIntervalHours,
      lastWaterResetDate: lastWaterResetDate ?? this.lastWaterResetDate,
      waterRemindersActive: waterRemindersActive ?? this.waterRemindersActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feedingSchedule': feedingSchedule,
      'recommendedFoods': recommendedFoods,
      'restrictedFoods': restrictedFoods,
      'dailyWaterTargetMl': dailyWaterTargetMl,
      'waterIntakeMl': waterIntakeMl,
      'waterReminderIntervalHours': waterReminderIntervalHours,
      'lastWaterResetDate': lastWaterResetDate?.millisecondsSinceEpoch,
      'waterRemindersActive': waterRemindersActive,
    };
  }

  factory DietPlan.fromMap(Map<String, dynamic> map) {
    return DietPlan(
      feedingSchedule: List<String>.from(map['feedingSchedule'] ?? []),
      recommendedFoods: List<String>.from(map['recommendedFoods'] ?? []),
      restrictedFoods: List<String>.from(map['restrictedFoods'] ?? []),
      dailyWaterTargetMl: map['dailyWaterTargetMl']?.toInt() ?? 0,
      waterIntakeMl: map['waterIntakeMl']?.toInt() ?? 0,
      waterReminderIntervalHours: map['waterReminderIntervalHours']?.toInt() ?? 2,
      lastWaterResetDate: map['lastWaterResetDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWaterResetDate'])
          : null,
      waterRemindersActive: map['waterRemindersActive'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory DietPlan.fromJson(String source) => DietPlan.fromMap(json.decode(source));
}

