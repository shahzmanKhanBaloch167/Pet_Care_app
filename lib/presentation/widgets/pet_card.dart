import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/diet_plan.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/notification_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/pet_profile_screen.dart';

class PetCard extends ConsumerStatefulWidget {
  final Pet pet;
  final int index;

  const PetCard({
    super.key,
    required this.pet,
    required this.index,
  });

  @override
  ConsumerState<PetCard> createState() => _PetCardState();
}

class _PetCardState extends ConsumerState<PetCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleCard() {
    // If opening back side, check/reset water intake for new day
    if (_isFront) {
      ref.read(petsProvider.notifier).resetWaterIntakeIfNewDay(widget.pet.id);
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi;
        final isFront = angle < math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isFront
              ? _buildFront(context)
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildBack(context, ref),
                ),
        );
      },
    );
  }

  Widget _buildFront(BuildContext context) {
    return Card(
      key: const ValueKey('front'),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: InkWell(
        borderRadius: AppStyles.cardRadius,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetProfileScreen(pet: widget.pet),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppStyles.cardRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _buildPetAvatar(widget.pet, widget.index),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPetInfo(widget.pet),
                    const SizedBox(height: 12),
                    _buildPetTags(widget.pet),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.water_drop_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                      tooltip: 'Track Water',
                      onPressed: toggleCard,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack(BuildContext context, WidgetRef ref) {
    final dietPlan = widget.pet.dietPlan ?? DietPlan(
      dailyWaterTargetMl: 1000,
      waterIntakeMl: 0,
      waterReminderIntervalHours: 2,
      waterRemindersActive: false,
    );

    final progress = dietPlan.dailyWaterTargetMl > 0
        ? (dietPlan.waterIntakeMl / dietPlan.dailyWaterTargetMl).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      key: const ValueKey('back'),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: Colors.blue, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${widget.pet.name}\'s Water Intake',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flip_to_front_rounded, color: AppColors.primaryPurple, size: 20),
                  tooltip: 'Show Details',
                  onPressed: toggleCard,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Intake:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${dietPlan.waterIntakeMl} / ${dietPlan.dailyWaterTargetMl} ml',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.blue.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14, color: Colors.blue),
                  label: const Text('+50ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    final newPlan = dietPlan.copyWith(
                      waterIntakeMl: dietPlan.waterIntakeMl + 50,
                    );
                    ref.read(petsProvider.notifier).updateDietPlan(widget.pet.id, newPlan);
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 14, color: Colors.blue),
                  label: const Text('+100ml', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    final newPlan = dietPlan.copyWith(
                      waterIntakeMl: dietPlan.waterIntakeMl + 100,
                    );
                    ref.read(petsProvider.notifier).updateDietPlan(widget.pet.id, newPlan);
                  },
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_outlined, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    const Text('Reminder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: dietPlan.waterRemindersActive,
                        activeColor: Colors.blue,
                        onChanged: (val) {
                          final newPlan = dietPlan.copyWith(waterRemindersActive: val);
                          ref.read(petsProvider.notifier).updateDietPlan(widget.pet.id, newPlan);
                          if (val) {
                            NotificationService().scheduleWaterReminders(
                              baseId: widget.pet.id.hashCode + 200,
                              title: 'Water Reminder',
                              body: 'Time to check ${widget.pet.name}\'s water bowl!',
                              intervalHours: dietPlan.waterReminderIntervalHours,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Water reminders scheduled for ${widget.pet.name}!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } else {
                            NotificationService().cancelWaterReminders(widget.pet.id.hashCode + 200);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Water reminders canceled for ${widget.pet.name}.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetAvatar(Pet pet, int index) {
    return Hero(
      tag: 'pet_${pet.name}_$index',
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppGradients.mainGradient,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: pet.photoPath != null
              ? Image.file(File(pet.photoPath!), fit: BoxFit.cover)
              : const Icon(Icons.pets, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildPetInfo(Pet pet) {
    return Row(
      children: [
        Icon(
          pet.gender.toLowerCase() == 'male' ? Icons.male : Icons.female,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          pet.gender,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.cake, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          '${pet.age} year${pet.age != 1 ? 's' : ''}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPetTags(Pet pet) {
    return Row(
      children: [
        _buildTag(pet.breed, AppColors.primaryPurple),
        const SizedBox(width: 8),
        _buildTag(
          '${pet.medicalHistory.length} record${pet.medicalHistory.length != 1 ? 's' : ''}',
          AppColors.accentPurple,
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
