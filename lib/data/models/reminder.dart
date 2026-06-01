import 'dart:convert';

import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';

/// Frequency at which a reminder repeats
enum ReminderFrequency { once, daily, weekly, monthly }

class Reminder {
  final String id;
  final String petId;
  final String petName;
  final String title;
  final String description;
  final DateTime dateTime;
  final ReminderType type;
  final bool isCompleted;
  final ReminderFrequency frequency;
  final bool isAlarm;

  Reminder({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    required this.isCompleted,
    this.frequency = ReminderFrequency.once,
    this.isAlarm = false,
  });

  Reminder copyWith({
    String? id,
    String? petId,
    String? petName,
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderType? type,
    bool? isCompleted,
    ReminderFrequency? frequency,
    bool? isAlarm,
  }) {
    return Reminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      frequency: frequency ?? this.frequency,
      isAlarm: isAlarm ?? this.isAlarm,
    );
  }

  /// Human-readable frequency label
  String get frequencyLabel {
    switch (frequency) {
      case ReminderFrequency.once:
        return 'Once';
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'title': title,
      'description': description,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'type': type.name,
      'isCompleted': isCompleted,
      'frequency': frequency.name,
      'isAlarm': isAlarm,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.medication,
      ),
      isCompleted: map['isCompleted'] ?? false,
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ReminderFrequency.once,
      ),
      isAlarm: map['isAlarm'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Reminder.fromJson(String source) =>
      Reminder.fromMap(json.decode(source));
}
