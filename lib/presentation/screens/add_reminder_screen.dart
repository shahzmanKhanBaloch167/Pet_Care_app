import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/reminder_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../application/services/notification_service.dart';


class AddReminderScreen extends HookConsumerWidget {
  final Reminder? reminder;
  const AddReminderScreen({super.key, this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final pets = ref.watch(petsProvider);
    final selectedPet = useState<String?>(reminder?.petId);
    final titleController = useTextEditingController(text: reminder?.title);
    final descriptionController = useTextEditingController(text: reminder?.description);
    final selectedType = useState(reminder?.type ?? ReminderType.medication);
    final selectedDate = useState<DateTime?>(reminder?.dateTime);
    final selectedTime = useState<TimeOfDay?>(
      reminder != null ? TimeOfDay.fromDateTime(reminder!.dateTime) : null,
    );
    final isLoading = useState(false);
    final selectedFrequency = useState(reminder?.frequency ?? ReminderFrequency.once);
    final isAlarm = useState(reminder?.isAlarm ?? false);

    // Animation controllers
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final slideAnimation = useMemoized(
      () =>
          Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOutCubic,
            ),
          ),
      [animationController],
    );

    final fadeAnimation = useMemoized(
      () => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      ),
      [animationController],
    );

    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    Future<void> selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accentPurple,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        selectedDate.value = picked;
      }
    }

    Future<void> selectTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accentPurple,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        selectedTime.value = picked;
      }
    }

    Future<void> saveReminder() async {
      if (!formKey.currentState!.validate()) return;

      if (selectedPet.value == null) {
        _showErrorSnackBar(context, 'Please select a pet');
        return;
      }

      if (selectedDate.value == null || selectedTime.value == null) {
        _showErrorSnackBar(context, 'Please select date and time');
        return;
      }

      isLoading.value = true;

      try {
        final pet = pets.firstWhere((p) => p.id == selectedPet.value);
        final reminderDateTime = DateTime(
          selectedDate.value!.year,
          selectedDate.value!.month,
          selectedDate.value!.day,
          selectedTime.value!.hour,
          selectedTime.value!.minute,
        );

        if (reminder != null) {
          final updatedReminder = reminder!.copyWith(
            petId: pet.id,
            petName: pet.name,
            title: titleController.text.trim(),
            type: selectedType.value,
            dateTime: reminderDateTime,
            description: descriptionController.text.trim(),
            frequency: selectedFrequency.value,
            isAlarm: isAlarm.value,
          );

          ref.read(remindersProvider.notifier).updateReminder(updatedReminder);

          // Cancel old and reschedule with correct frequency
          await NotificationService().cancelReminder(reminder!.id.hashCode.abs());
          await NotificationService().scheduleFromReminder(updatedReminder);

          if (context.mounted) {
            _showSuccessSnackBar(context, 'Reminder updated successfully!');
            Navigator.of(context).pop();
          }
        } else {
          final newReminder = Reminder(
            id: const Uuid().v4(),
            petId: pet.id,
            petName: pet.name,
            title: titleController.text.trim(),
            type: selectedType.value,
            dateTime: reminderDateTime,
            isCompleted: false,
            description: descriptionController.text.trim(),
            frequency: selectedFrequency.value,
            isAlarm: isAlarm.value,
          );

          ref.read(remindersProvider.notifier).addReminder(newReminder);

          // Schedule notification/alarm based on frequency
          await NotificationService().scheduleFromReminder(newReminder);

          if (context.mounted) {
            _showSuccessSnackBar(context, 'Reminder created successfully!');
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (context.mounted) {
          _showErrorSnackBar(
            context,
            'Error saving reminder: ${e.toString()}',
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(
          reminder == null ? 'Add Reminder' : 'Edit Reminder',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          if (isLoading.value)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  const SizedBox(height: 24),

                  // Pet Selection Card
                  _buildPetSelectionCard(pets, selectedPet),
                  const SizedBox(height: 20),

                  // Reminder Details Card
                  _buildReminderDetailsCard(
                    titleController,
                    descriptionController,
                    selectedType,
                  ),
                  const SizedBox(height: 20),

                  // Date & Time Card
                  _buildDateTimeCard(
                    selectedDate,
                    selectedTime,
                    selectDate,
                    selectTime,
                    context,
                  ),
                  const SizedBox(height: 20),

                  // Advanced Options Card
                  _buildAdvancedOptionsCard(selectedFrequency, isAlarm),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(isLoading, saveReminder),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppGradients.mainGradient,
          borderRadius: AppStyles.cardRadius,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.add_alert, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              reminder == null ? 'Create New Reminder' : 'Edit Reminder',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reminder == null
                  ? 'Never miss important pet care activities'
                  : 'Update your pet care activity details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelectionCard(List pets, ValueNotifier<String?> selectedPet) {
    return _buildCard(
      title: 'Select Pet',
      icon: Icons.pets,
      child: DropdownButtonFormField<String>(
        value: selectedPet.value,
        hint: const Text('Choose a pet'),
        decoration: _buildInputDecoration('Select your pet'),
        items:
            pets.map((pet) {
              return DropdownMenuItem<String>(
                value: pet.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accentPurple.withOpacity(0.1),
                      child: const Icon(
                        Icons.pets,
                        size: 16,
                        color: AppColors.accentPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(pet.name),
                  ],
                ),
              );
            }).toList(),
        onChanged: (value) {
          selectedPet.value = value;
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a pet';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildReminderDetailsCard(
    TextEditingController titleController,
    TextEditingController descriptionController,
    ValueNotifier<ReminderType> selectedType,
  ) {
    return _buildCard(
      title: 'Reminder Details',
      icon: Icons.edit_note,
      child: Column(
        children: [
          TextFormField(
            style: const TextStyle(color: Colors.black),
            controller: titleController,
            decoration: _buildInputDecoration('Enter reminder title'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(color: Colors.black),
            controller: descriptionController,
            decoration: _buildInputDecoration('Add description (optional)'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReminderType>(
            value: selectedType.value,
            decoration: _buildInputDecoration('Type'),
            items:
                ReminderType.values.map((type) {
                  return DropdownMenuItem<ReminderType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(
                          _getTypeIcon(type),
                          size: 16,
                          color: AppColors.accentPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(type.name.toUpperCase()),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedType.value = value;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard(
    ValueNotifier<DateTime?> selectedDate,
    ValueNotifier<TimeOfDay?> selectedTime,
    VoidCallback selectDate,
    VoidCallback selectTime,
    BuildContext context,
  ) {
    return _buildCard(
      title: 'Date & Time',
      icon: Icons.schedule,
      child: Row(
        children: [
          Expanded(
            child: _buildDateTimeSelector(
              label: 'Date',
              value:
                  selectedDate.value == null
                      ? 'Select date'
                      : DateFormat('MMM dd, yyyy').format(selectedDate.value!),
              icon: Icons.calendar_today,
              onTap: selectDate,
              isSelected: selectedDate.value != null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateTimeSelector(
              label: 'Time',
              value:
                  selectedTime.value == null
                      ? 'Select time'
                      : selectedTime.value!.format(context),
              icon: Icons.access_time,
              onTap: selectTime,
              isSelected: selectedTime.value != null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsCard(
    ValueNotifier<ReminderFrequency> selectedFrequency,
    ValueNotifier<bool> isAlarm,
  ) {
    return _buildCard(
      title: 'Advanced Options',
      icon: Icons.tune,
      child: Column(
        children: [
          // Frequency selector
          DropdownButtonFormField<ReminderFrequency>(
            value: selectedFrequency.value,
            decoration: _buildInputDecoration('Frequency'),
            items: ReminderFrequency.values.map((freq) {
              return DropdownMenuItem<ReminderFrequency>(
                value: freq,
                child: Row(
                  children: [
                    Icon(_getFrequencyIcon(freq), size: 16, color: AppColors.accentPurple),
                    const SizedBox(width: 8),
                    Text(freq.name[0].toUpperCase() + freq.name.substring(1)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                selectedFrequency.value = value;
              }
            },
          ),
          const SizedBox(height: 16),
          // Alarm toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm_rounded,
                        size: 20,
                        color: isAlarm.value ? const Color(0xFFF44336) : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set as Alarm',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Rings native phone alarm + full-screen alert',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isAlarm.value,
                  onChanged: (value) {
                    isAlarm.value = value;
                  },
                  activeColor: const Color(0xFFF44336),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFrequencyIcon(ReminderFrequency freq) {
    switch (freq) {
      case ReminderFrequency.once:
        return Icons.looks_one_rounded;
      case ReminderFrequency.daily:
        return Icons.replay_rounded;
      case ReminderFrequency.weekly:
        return Icons.date_range_rounded;
      case ReminderFrequency.monthly:
        return Icons.calendar_month_rounded;
    }
  }

  Widget _buildSaveButton(
    ValueNotifier<bool> isLoading,
    VoidCallback saveReminder,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppGradients.mainGradient,
        borderRadius: AppStyles.buttonRadius,
      ),
      child: FilledButton(
        onPressed: isLoading.value ? null : saveReminder,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.buttonRadius,
          ),
        ),
        child:
            isLoading.value
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(reminder == null ? Icons.save : Icons.check, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      reminder == null ? 'Save Reminder' : 'Update Reminder',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:  Icon(icon, size: 20, color: AppColors.accentPurple),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppColors.accentPurple : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color:
                  isSelected
                      ? AppColors.accentPurple.withOpacity(0.05)
                      : Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isSelected ? AppColors.primaryDark : Colors.grey[600],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Icon(
                  icon,
                  color:
                      isSelected ? AppColors.accentPurple : Colors.grey[600],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.feeding:
        return Icons.restaurant;
      case ReminderType.grooming:
        return Icons.content_cut;
      case ReminderType.exercise:
        return Icons.directions_run;
      case ReminderType.veterinary:
        return Icons.local_hospital;
      default:
        return Icons.notifications;
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
