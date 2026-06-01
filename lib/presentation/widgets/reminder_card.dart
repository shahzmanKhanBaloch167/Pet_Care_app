import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/add_reminder_screen.dart';
import 'package:intl/intl.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final typeVisual = _getTypeVisual(reminder.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: typeVisual.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                typeVisual.icon,
                color: typeVisual.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Pet name + type
                  Text(
                    '${reminder.petName} • ${_formatTypeName(reminder.type)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Date/time
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(reminder.dateTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Frequency + Alarm badges
                  Row(
                    children: [
                      _FrequencyBadge(frequency: reminder.frequency),
                      if (reminder.isAlarm) ...[
                        const SizedBox(width: 6),
                        const _AlarmBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.accentPurple, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReminderScreen(reminder: reminder),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTypeName(ReminderType type) {
    // Capitalize first letter
    final name = type.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  _TypeVisual _getTypeVisual(ReminderType type) {
    switch (type) {
      case ReminderType.medication:
        return _TypeVisual(Icons.medication_rounded, const Color(0xFFE91E63));
      case ReminderType.feeding:
        return _TypeVisual(Icons.restaurant_rounded, const Color(0xFFFF9800));
      case ReminderType.grooming:
        return _TypeVisual(Icons.content_cut_rounded, const Color(0xFF9C27B0));
      case ReminderType.exercise:
        return _TypeVisual(Icons.directions_run_rounded, const Color(0xFF4CAF50));
      case ReminderType.veterinary:
        return _TypeVisual(Icons.local_hospital_rounded, const Color(0xFFF44336));
      case ReminderType.vaccination:
        return _TypeVisual(Icons.vaccines_rounded, const Color(0xFF00BCD4));
      case ReminderType.checkup:
        return _TypeVisual(Icons.health_and_safety_rounded, const Color(0xFF3F51B5));
      case ReminderType.appointment:
        return _TypeVisual(Icons.calendar_month_rounded, const Color(0xFF607D8B));
      case ReminderType.other:
        return _TypeVisual(Icons.notifications_rounded, AppColors.accentYellow);
    }
  }
}

/// Badge showing the reminder frequency (Daily, Weekly, etc.)
class _FrequencyBadge extends StatelessWidget {
  final ReminderFrequency frequency;
  const _FrequencyBadge({required this.frequency});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getIcon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
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

  IconData _getIcon() {
    switch (frequency) {
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

  Color _getColor() {
    switch (frequency) {
      case ReminderFrequency.once:
        return const Color(0xFF607D8B);
      case ReminderFrequency.daily:
        return const Color(0xFF4CAF50);
      case ReminderFrequency.weekly:
        return const Color(0xFF2196F3);
      case ReminderFrequency.monthly:
        return const Color(0xFF9C27B0);
    }
  }
}

/// Small alarm badge indicator
class _AlarmBadge extends StatelessWidget {
  const _AlarmBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.25)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_rounded, size: 12, color: Color(0xFFF44336)),
          SizedBox(width: 4),
          Text(
            'Alarm',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF44336),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeVisual {
  final IconData icon;
  final Color color;
  const _TypeVisual(this.icon, this.color);
}
