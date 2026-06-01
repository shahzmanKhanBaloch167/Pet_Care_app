import 'dart:convert';

enum MealType { breakfast, lunch, dinner, snack }

class MealLog {
  final String id;
  final String petId;
  final String petName;
  final MealType mealType;
  final String foodName;
  final String portionDescription;
  final DateTime timestamp;
  /// Whether this meal has been checked off (pet was fed)
  final bool isChecked;

  MealLog({
    required this.id,
    required this.petId,
    required this.petName,
    required this.mealType,
    required this.foodName,
    this.portionDescription = '',
    required this.timestamp,
    this.isChecked = false,
  });

  MealLog copyWith({
    String? id,
    String? petId,
    String? petName,
    MealType? mealType,
    String? foodName,
    String? portionDescription,
    DateTime? timestamp,
    bool? isChecked,
  }) {
    return MealLog(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      portionDescription: portionDescription ?? this.portionDescription,
      timestamp: timestamp ?? this.timestamp,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'mealType': mealType.name,
      'foodName': foodName,
      'portionDescription': portionDescription,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isChecked': isChecked,
    };
  }

  factory MealLog.fromMap(Map<String, dynamic> map) {
    return MealLog(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == map['mealType'],
        orElse: () => MealType.snack,
      ),
      foodName: map['foodName'] ?? '',
      portionDescription: map['portionDescription'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isChecked: map['isChecked'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory MealLog.fromJson(String source) =>
      MealLog.fromMap(json.decode(source));

  /// Human-readable meal type label
  String get mealTypeLabel {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}
