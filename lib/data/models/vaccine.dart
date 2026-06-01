import 'dart:convert';

enum VaccineStatus { administered, needed }

class Vaccine {
  final String id;
  final String name;
  final DateTime dateAdministered;
  final DateTime? nextDueDate;
  final String? veterinarian;
  final String? notes;
  final VaccineStatus status;

  Vaccine({
    required this.id,
    required this.name,
    required this.dateAdministered,
    this.nextDueDate,
    this.veterinarian,
    this.notes,
    this.status = VaccineStatus.administered,
  });

  Vaccine copyWith({
    String? id,
    String? name,
    DateTime? dateAdministered,
    DateTime? nextDueDate,
    String? veterinarian,
    String? notes,
    VaccineStatus? status,
  }) {
    return Vaccine(
      id: id ?? this.id,
      name: name ?? this.name,
      dateAdministered: dateAdministered ?? this.dateAdministered,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      veterinarian: veterinarian ?? this.veterinarian,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateAdministered': dateAdministered.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'veterinarian': veterinarian,
      'notes': notes,
      'status': status.name,
    };
  }

  factory Vaccine.fromMap(Map<String, dynamic> map) {
    return Vaccine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dateAdministered: DateTime.parse(map['dateAdministered']),
      nextDueDate: map['nextDueDate'] != null ? DateTime.parse(map['nextDueDate']) : null,
      veterinarian: map['veterinarian'],
      notes: map['notes'],
      status: VaccineStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VaccineStatus.administered,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Vaccine.fromJson(String source) => Vaccine.fromMap(json.decode(source));
}
