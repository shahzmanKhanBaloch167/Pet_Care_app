import 'dart:convert';

import 'package:flutter_pet_care_and_veterinary_app/data/models/diet_plan.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/medical_record.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/vaccine.dart';

class Pet {
  final String id;
  final String name;
  final int age;
  final String breed;
  final String gender;
  final String? photoPath;
  final double? weight;
  final String? notes;
  final List<String> allergies;
  final List<MedicalRecord> medicalHistory;
  final List<Vaccine> vaccinations;
  final DietPlan? dietPlan;

  Pet({
    required this.id,
    required this.name,
    required this.age,
    required this.breed,
    required this.gender,
    this.photoPath,
    this.weight,
    this.notes,
    this.allergies = const [],
    required this.medicalHistory,
    this.vaccinations = const [],
    this.dietPlan,
  });

  Pet copyWith({
    String? id,
    String? name,
    int? age,
    String? breed,
    String? gender,
    String? photoPath,
    double? weight,
    String? notes,
    List<String>? allergies,
    List<MedicalRecord>? medicalHistory,
    List<Vaccine>? vaccinations,
    DietPlan? dietPlan,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      photoPath: photoPath ?? this.photoPath,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      vaccinations: vaccinations ?? this.vaccinations,
      dietPlan: dietPlan ?? this.dietPlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'breed': breed,
      'gender': gender,
      'photoPath': photoPath,
      'weight': weight,
      'notes': notes,
      'allergies': allergies,
      'medicalHistory': medicalHistory.map((x) => x.toMap()).toList(),
      'vaccinations': vaccinations.map((x) => x.toMap()).toList(),
      'dietPlan': dietPlan?.toMap(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      breed: map['breed'] ?? '',
      gender: map['gender'] ?? '',
      photoPath: map['photoPath'],
      weight: map['weight']?.toDouble(),
      notes: map['notes'],
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalHistory: List<MedicalRecord>.from(
        map['medicalHistory']?.map((x) => MedicalRecord.fromMap(x)) ?? [],
      ),
      vaccinations: List<Vaccine>.from(
        map['vaccinations']?.map((x) => Vaccine.fromMap(x)) ?? [],
      ),
      dietPlan: map['dietPlan'] != null ? DietPlan.fromMap(map['dietPlan']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Pet.fromJson(String source) => Pet.fromMap(json.decode(source));
}
