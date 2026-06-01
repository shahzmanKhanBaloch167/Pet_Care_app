import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/meal_log_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/meal_log.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Meal Check screen for a specific pet.
/// Shows today's meals as a checkable list (from AI diet plan or manual logs).
/// Users can check meals off when the pet has been fed, and view history.
class MealCheckScreen extends ConsumerWidget {
  final Pet pet;

  const MealCheckScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mealLogsProvider.notifier).checkDailyMealReset();
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allMealLogs = ref.watch(mealLogsProvider);

    final now = DateTime.now();
    final todaysMeals = allMealLogs.where((log) {
      return log.petId == pet.id &&
          log.timestamp.year == now.year &&
          log.timestamp.month == now.month &&
          log.timestamp.day == now.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final checkedCount = todaysMeals.where((m) => m.isChecked).length;

    final olderMeals = allMealLogs.where((log) {
      return log.petId == pet.id &&
          !(log.timestamp.year == now.year &&
              log.timestamp.month == now.month &&
              log.timestamp.day == now.day);
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1F) : AppColors.surface,
      appBar: AppBar(
        title: Text('${pet.name}\'s Meals',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: todaysMeals.isEmpty && olderMeals.isEmpty
          ? _buildEmptyState(isDark)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Progress header
                if (todaysMeals.isNotEmpty)
                  _buildProgressCard(
                      todaysMeals.length, checkedCount, isDark),
                const SizedBox(height: 20),

                // Today's meals
                if (todaysMeals.isNotEmpty) ...[
                  _buildSectionLabel("Today's Meals", isDark),
                  const SizedBox(height: 10),
                  ...todaysMeals.map(
                    (meal) => _buildMealCheckCard(context, ref, meal, isDark),
                  ),
                ],

                // History
                if (olderMeals.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionLabel('History (Last 7 Days)', isDark),
                  const SizedBox(height: 10),
                  ...olderMeals.map(
                    (meal) => _buildHistoryCard(ref, meal, isDark),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context, ref),
        backgroundColor: AppColors.accentPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Meal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProgressCard(int total, int checked, bool isDark) {
    final progress = total > 0 ? checked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Feeding Progress',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$checked / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                checked == total && total > 0
                    ? const Color(0xFF4CAF50)
                    : AppColors.accentPurple,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            checked == total && total > 0
                ? '✅ All meals completed for today!'
                : '${total - checked} meal${total - checked == 1 ? '' : 's'} remaining',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white70 : AppColors.primaryDark,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildMealCheckCard(
      BuildContext context, WidgetRef ref, MealLog meal, bool isDark) {
    final _MealVisual visual = _getMealVisual(meal.mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: meal.isChecked
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.06) : AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => ref.read(mealLogsProvider.notifier).toggleMealCheck(meal.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: meal.isChecked
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: meal.isChecked
                        ? const Color(0xFF4CAF50)
                        : (isDark ? Colors.white30 : AppColors.textSecondary),
                    width: 2,
                  ),
                ),
                child: meal.isChecked
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                    : null,
              ),
              const SizedBox(width: 14),
              // Meal icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visual.color.withOpacity(meal.isChecked ? 0.06 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon,
                    color: meal.isChecked
                        ? visual.color.withOpacity(0.4)
                        : visual.color,
                    size: 20),
              ),
              const SizedBox(width: 14),
              // Meal info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.foodName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: meal.isChecked
                            ? (isDark ? Colors.white38 : AppColors.textSecondary)
                            : (isDark ? Colors.white : AppColors.primaryDark),
                        decoration:
                            meal.isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${meal.mealTypeLabel}${meal.portionDescription.isNotEmpty ? ' • ${meal.portionDescription}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white38 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Time
              Text(
                DateFormat('h:mm a').format(meal.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white30 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.primaryPurple,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showEditMealDialog(context, ref, meal),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: Colors.red.shade400,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showDeleteConfirmation(context, ref, meal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(WidgetRef ref, MealLog meal, bool isDark) {
    final visual = _getMealVisual(meal.mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => ref.read(mealLogsProvider.notifier).toggleMealCheck(meal.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: meal.isChecked
                      ? const Color(0xFF4CAF50).withOpacity(0.7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: meal.isChecked
                        ? const Color(0xFF4CAF50).withOpacity(0.7)
                        : (isDark ? Colors.white24 : Colors.grey.shade400),
                    width: 1.5,
                  ),
                ),
                child: meal.isChecked
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Icon(visual.icon,
                  color: visual.color.withOpacity(0.5), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${meal.mealTypeLabel}: ${meal.foodName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    decoration: meal.isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(meal.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white30 : AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded,
              size: 64,
              color: isDark
                  ? Colors.white24
                  : AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use Dr. PetPal AI to generate a meal plan\nor tap + to add meals manually',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white24
                  : AppColors.textSecondary.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foodController = TextEditingController();
    final portionController = TextEditingController();
    MealType selectedType = MealType.breakfast;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Log Meal for ${pet.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: MealType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type.name[0].toUpperCase() +
                            type.name.substring(1)),
                        selected: isSelected,
                        selectedColor: AppColors.accentPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: foodController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Food Name',
                      hintText: 'e.g. Kibble, Chicken, Wet food...',
                      prefixIcon: const Icon(Icons.restaurant_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: portionController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Portion (optional)',
                      hintText: 'e.g. Half cup, 200g...',
                      prefixIcon: const Icon(Icons.scale_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (foodController.text.trim().isEmpty) return;
                        ref.read(mealLogsProvider.notifier).addMealLog(
                              MealLog(
                                id: const Uuid().v4(),
                                petId: pet.id,
                                petName: pet.name,
                                mealType: selectedType,
                                foodName: foodController.text.trim(),
                                portionDescription:
                                    portionController.text.trim(),
                                timestamp: DateTime.now(),
                              ),
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal logged! ✅'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Add Meal',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, MealLog meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete this meal log for "${meal.foodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(mealLogsProvider.notifier).deleteMealLog(meal.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Meal deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditMealDialog(BuildContext context, WidgetRef ref, MealLog meal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foodController = TextEditingController(text: meal.foodName);
    final portionController = TextEditingController(text: meal.portionDescription);
    MealType selectedType = meal.mealType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Meal Log',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: MealType.values.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type.name[0].toUpperCase() +
                            type.name.substring(1)),
                        selected: isSelected,
                        selectedColor: AppColors.accentPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() => selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: foodController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Food Name',
                      hintText: 'e.g. Kibble, Chicken, Wet food...',
                      prefixIcon: const Icon(Icons.restaurant_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: portionController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Portion (optional)',
                      hintText: 'e.g. Half cup, 200g...',
                      prefixIcon: const Icon(Icons.scale_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (foodController.text.trim().isEmpty) return;
                        ref.read(mealLogsProvider.notifier).updateMealLog(
                              meal.copyWith(
                                mealType: selectedType,
                                foodName: foodController.text.trim(),
                                portionDescription:
                                    portionController.text.trim(),
                              ),
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal updated! ✅'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Update Meal',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _MealVisual _getMealVisual(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return _MealVisual(Icons.wb_sunny_rounded, const Color(0xFFFF9800));
      case MealType.lunch:
        return _MealVisual(Icons.wb_cloudy_rounded, const Color(0xFF4CAF50));
      case MealType.dinner:
        return _MealVisual(Icons.nightlight_round, const Color(0xFF3F51B5));
      case MealType.snack:
        return _MealVisual(Icons.cookie_rounded, const Color(0xFFE91E63));
    }
  }
}

class _MealVisual {
  final IconData icon;
  final Color color;
  const _MealVisual(this.icon, this.color);
}
