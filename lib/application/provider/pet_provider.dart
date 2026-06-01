import 'package:flutter_pet_care_and_veterinary_app/data/datasources/local/storage_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/diet_plan.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/medical_record.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/vaccine.dart';

final petsProvider = StateNotifierProvider<PetsNotifier, List<Pet>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return PetsNotifier(storage);
});

class PetsNotifier extends StateNotifier<List<Pet>> {
  final StorageService _storage;

  PetsNotifier(this._storage) : super([]) {
    state = _storage.getPets();
    checkDailyResets();
  }

  void checkDailyResets() {
    bool changed = false;
    final today = DateTime.now();
    state = state.map((pet) {
      final plan = pet.dietPlan;
      if (plan == null) return pet;

      final lastReset = plan.lastWaterResetDate;
      final isNewDay = lastReset == null ||
          lastReset.year != today.year ||
          lastReset.month != today.month ||
          lastReset.day != today.day;

      if (isNewDay) {
        changed = true;
        final resetPlan = plan.copyWith(
          waterIntakeMl: 0,
          lastWaterResetDate: today,
        );
        return pet.copyWith(dietPlan: resetPlan);
      }
      return pet;
    }).toList();

    if (changed) {
      _storage.savePets(state);
    }
  }

  void addPet(Pet pet) {
    state = [...state, pet];
    _storage.savePets(state);
  }

  void updatePet(Pet updatedPet) {
    state =
        state.map((pet) {
          return pet.id == updatedPet.id ? updatedPet : pet;
        }).toList();
    _storage.savePets(state);
  }

  void deletePet(String petId) {
    state = state.where((pet) => pet.id != petId).toList();
    _storage.savePets(state);
  }

  void addMedicalRecord(String petId, MedicalRecord record) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            return pet.copyWith(
              medicalHistory: [...pet.medicalHistory, record],
            );
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  void updateMedicalRecord(String petId, MedicalRecord updatedRecord) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            final updatedHistory =
                pet.medicalHistory.map((record) {
                  return record.id == updatedRecord.id ? updatedRecord : record;
                }).toList();
            return pet.copyWith(medicalHistory: updatedHistory);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  void deleteMedicalRecord(String petId, String recordId) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            final updatedHistory =
                pet.medicalHistory
                    .where((record) => record.id != recordId)
                    .toList();
            return pet.copyWith(medicalHistory: updatedHistory);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  void updateDietPlan(String petId, DietPlan dietPlan) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            return pet.copyWith(dietPlan: dietPlan);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  /// Resets water intake to 0 for [petId] if the last reset was on a different
  /// calendar day. Returns true if a reset happened.
  bool resetWaterIntakeIfNewDay(String petId) {
    final pet = state.firstWhere((p) => p.id == petId, orElse: () => throw StateError('Pet not found'));
    final plan = pet.dietPlan;
    if (plan == null) return false;

    final today = DateTime.now();
    final lastReset = plan.lastWaterResetDate;
    final isNewDay = lastReset == null ||
        lastReset.year != today.year ||
        lastReset.month != today.month ||
        lastReset.day != today.day;

    if (isNewDay) {
      final resetPlan = plan.copyWith(
        waterIntakeMl: 0,
        lastWaterResetDate: today,
      );
      updateDietPlan(petId, resetPlan);
      return true;
    }
    return false;
  }

  void addVaccination(String petId, Vaccine vaccine) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            return pet.copyWith(vaccinations: [...pet.vaccinations, vaccine]);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  void updateVaccination(String petId, Vaccine updatedVaccine) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            final updatedList =
                pet.vaccinations.map((vac) {
                  return vac.id == updatedVaccine.id ? updatedVaccine : vac;
                }).toList();
            return pet.copyWith(vaccinations: updatedList);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }

  void deleteVaccination(String petId, String vaccineId) {
    state =
        state.map((pet) {
          if (pet.id == petId) {
            final updatedList =
                pet.vaccinations.where((vac) => vac.id != vaccineId).toList();
            return pet.copyWith(vaccinations: updatedList);
          }
          return pet;
        }).toList();
    _storage.savePets(state);
  }
}
