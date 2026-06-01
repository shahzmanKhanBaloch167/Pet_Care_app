import 'dart:convert';

enum RecordStatus { completed, needed }

class MedicalRecord {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String veterinarian;
  final RecordStatus status;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.veterinarian,
    this.status = RecordStatus.completed,
  });

  MedicalRecord copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? veterinarian,
    RecordStatus? status,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      veterinarian: veterinarian ?? this.veterinarian,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'veterinarian': veterinarian,
      'status': status.name,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      veterinarian: map['veterinarian'] ?? '',
      status: RecordStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RecordStatus.completed,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory MedicalRecord.fromJson(String source) =>
      MedicalRecord.fromMap(json.decode(source));
}
