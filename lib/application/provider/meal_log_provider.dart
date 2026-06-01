import 'package:flutter_pet_care_and_veterinary_app/data/datasources/local/storage_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/meal_log.dart';
import 'package:flutter_pet_care_and_veterinary_app/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

final mealLogsProvider =
    StateNotifierProvider<MealLogsNotifier, List<MealLog>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MealLogsNotifier(storage);
});

class MealLogsNotifier extends StateNotifier<List<MealLog>> {
  final StorageService _storage;

  MealLogsNotifier(this._storage) : super([]) {
    state = _storage.getMealLogs();
    checkDailyMealReset();
  }

  void addMealLog(MealLog log) {
    state = [...state, log];
    _storage.saveMealLogs(state);
  }

  void deleteMealLog(String logId) {
    state = state.where((log) => log.id != logId).toList();
    _storage.saveMealLogs(state);
  }

  void toggleMealCheck(String logId) {
    state = state.map((log) {
      if (log.id == logId) {
        return log.copyWith(isChecked: !log.isChecked);
      }
      return log;
    }).toList();
    _storage.saveMealLogs(state);
  }

  void updateMealLog(MealLog updatedLog) {
    state = state.map((log) => log.id == updatedLog.id ? updatedLog : log).toList();
    _storage.saveMealLogs(state);
  }

  void checkDailyMealReset() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

    List<MealLog> currentLogs = List.from(state);
    bool changed = false;

    // 1. Cleanup logs older than 7 days
    final initialCount = currentLogs.length;
    currentLogs.removeWhere((log) => log.timestamp.isBefore(sevenDaysAgo));
    if (currentLogs.length != initialCount) {
      changed = true;
    }

    // 2. Group logs by pet to handle cloning per pet
    final Map<String, List<MealLog>> logsByPet = {};
    for (final log in currentLogs) {
      logsByPet.putIfAbsent(log.petId, () => []).add(log);
    }

    List<MealLog> newLogs = [];
    for (final petId in logsByPet.keys) {
      final petLogs = logsByPet[petId]!;

      // Separate today's logs from historical logs
      final todaysLogs = petLogs.where((log) =>
          log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day).toList();

      final historicalLogs = petLogs.where((log) =>
          log.timestamp.isBefore(todayStart)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // If we have history but some/all typical meals are missing today, clone them
      if (historicalLogs.isNotEmpty) {
        final lastLogDate = historicalLogs.first.timestamp;
        final lastDayLogs = historicalLogs.where((log) =>
            log.timestamp.year == lastLogDate.year &&
            log.timestamp.month == lastLogDate.month &&
            log.timestamp.day == lastLogDate.day).toList();

        // Use a temporary list to track what we've already matched for today
        List<MealLog> tempTodaysLogs = List.from(todaysLogs);

        for (final oldLog in lastDayLogs) {
          // Check if this meal (by type and name) already exists today
          final existingIndex = tempTodaysLogs.indexWhere((l) =>
              l.mealType == oldLog.mealType && l.foodName == oldLog.foodName);

          if (existingIndex != -1) {
            // Found a match, remove it so it's not used for the next check
            tempTodaysLogs.removeAt(existingIndex);
          } else {
            final mealTime = DateTime(
              now.year,
              now.month,
              now.day,
              oldLog.timestamp.hour,
              oldLog.timestamp.minute,
            );

            newLogs.add(oldLog.copyWith(
              id: const Uuid().v4(),
              timestamp: mealTime,
              isChecked: false,
            ));
          }
        }
      }
    }

    if (newLogs.isNotEmpty || changed) {
      state = [...currentLogs, ...newLogs];
      _storage.saveMealLogs(state);
    }
  }

  /// Get all meal logs for a specific pet
  List<MealLog> getMealLogsForPet(String petId) {
    return state.where((log) => log.petId == petId).toList();
  }

  /// Get today's meal logs for a specific pet
  List<MealLog> getTodaysMealsForPet(String petId) {
    final now = DateTime.now();
    return state.where((log) {
      return log.petId == petId &&
          log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day;
    }).toList();
  }
}
