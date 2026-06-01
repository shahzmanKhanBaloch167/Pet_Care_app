import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/ai_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/notification_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/diet_plan.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/reminder_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/meal_log_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;


class DietScreen extends ConsumerStatefulWidget {
  final Pet pet;

  const DietScreen({super.key, required this.pet});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isGenerating = false;

  // Professional Color Scheme
  static const Color _primaryDark = Color(0xFF090040);
  static const Color _primaryPurple = Color(0xFF471396);
  static const Color _accentPurple = Color(0xFFB13BFF);
  static const Color _accentYellow = Color(0xFFFFCC00);
  static const Color _surface = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateAiDietPlan(Pet currentPet) async {
    setState(() {
      _isGenerating = true;
    });

    final aiService = ref.read(aiServiceProvider);
    
    final prompt = '''
      You are an expert veterinary nutritionist.
      Create a diet plan for my pet with the following details:
      Name: ${currentPet.name}
      Species/Breed: ${currentPet.breed}
      Age: ${currentPet.age} years
      Weight: ${currentPet.weight ?? 'Unknown'} kg
      Allergies: ${currentPet.allergies.isNotEmpty ? currentPet.allergies.join(', ') : 'None'}
      
      Provide a list of 3-5 recommended foods, 3-5 strictly restricted foods (things they must avoid), a feeding schedule in 24-hour format (e.g. ["08:00", "18:00"]), a daily water target in ml, and an interval in hours for water reminders (e.g., 2 or 3).
    ''';

    final schema = Schema.object(
      properties: {
        'recommendedFoods': Schema.array(items: Schema.string()),
        'restrictedFoods': Schema.array(items: Schema.string()),
        'feedingSchedule': Schema.array(items: Schema.string()),
        'dailyWaterTargetMl': Schema.integer(),
        'waterReminderIntervalHours': Schema.integer(),
      },
    );

    try {
      final result = await aiService.generateStructuredData(prompt, schema);
      
      if (result != null && mounted) {
        final recommended = List<String>.from(result['recommendedFoods'] ?? []);
        final restricted = List<String>.from(result['restrictedFoods'] ?? []);
        final feedingTimes = List<String>.from(result['feedingSchedule'] ?? []);
        final waterTarget = (result['dailyWaterTargetMl'] as num?)?.toInt() ?? 0;
        final waterInterval = (result['waterReminderIntervalHours'] as num?)?.toInt() ?? 2;
        
        final existingPlan = currentPet.dietPlan ?? DietPlan();

        final newPlan = existingPlan.copyWith(
          recommendedFoods: recommended,
          restrictedFoods: restricted,
          feedingSchedule: feedingTimes,
          dailyWaterTargetMl: waterTarget,
          waterReminderIntervalHours: waterInterval,
        );

        ref.read(petsProvider.notifier).updateDietPlan(currentPet.id, newPlan);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Diet Plan Generated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate diet plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch petsProvider to get the latest pet data
    final currentPet = ref.watch(petsProvider).firstWhere(
      (p) => p.id == widget.pet.id,
      orElse: () => widget.pet,
    );
    final dietPlan = currentPet.dietPlan;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Diet & Nutrition', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isGenerating
          ? _buildLoadingState()
          : SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(currentPet),
                      const SizedBox(height: 24),
                      if (dietPlan == null || (dietPlan.recommendedFoods.isEmpty && dietPlan.restrictedFoods.isEmpty))
                        _buildEmptyDietState(currentPet)
                      else
                        _buildDietPlanDetails(dietPlan),
                      if (dietPlan != null) ...[
                        const SizedBox(height: 24),
                        _buildMealCheckButton(currentPet),
                      ],
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: (!_isGenerating && dietPlan != null) 
          ? FloatingActionButton.extended(
              onPressed: () => _generateAiDietPlan(currentPet),
              backgroundColor: AppColors.accentPurple,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text('Refresh AI Plan', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }


  Widget _buildMealCheckButton(Pet pet) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => MealCheckScreen(pet: pet),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 250),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.08),
              const Color(0xFF4CAF50).withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: Color(0xFF4CAF50),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meal Check',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track daily feeding — check off meals',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _accentPurple),
          const SizedBox(height: 24),
          Text(
            'Analyzing nutritional needs...',
            style: TextStyle(
              color: _primaryDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Firebase AI is generating a tailored diet plan.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryDark, _primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.restaurant, color: _accentYellow, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.name}\'s Nutrition',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalized diet & water tracking',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDietState(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 64, color: _accentPurple.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text(
            'No Diet Plan Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use our AI assistant to generate a personalized diet plan including recommended foods and restrictions based on age, breed, and allergies.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _generateAiDietPlan(pet),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'Generate AI Diet Plan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncFeedingReminders(List<String> feedingTimes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sync to Reminders'),
          content: const Text(
            'This will create app reminders and schedule notifications for each feeding time in the AI plan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final currentPet = ref.read(petsProvider).firstWhere(
                  (p) => p.id == widget.pet.id,
                  orElse: () => widget.pet,
                );
                
                int syncedCount = 0;
                final now = tz.TZDateTime.now(tz.local);
                
                for (final timeStr in feedingTimes) {
                  final parts = timeStr.split(':');
                  if (parts.length == 2) {
                    final hour = int.tryParse(parts[0]) ?? 8;
                    final minute = int.tryParse(parts[1]) ?? 0;
                    
                    final scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
                    
                    final reminder = Reminder(
                      id: const Uuid().v4(),
                      petId: currentPet.id,
                      petName: currentPet.name,
                      title: 'Feeding Time: ${currentPet.name}',
                      description: 'AI suggested feeding time.',
                      dateTime: scheduledDate,
                      type: ReminderType.feeding,
                      isCompleted: false,
                      frequency: ReminderFrequency.daily,
                    );
                    
                    // Add to Reminders state
                    ref.read(remindersProvider.notifier).addReminder(reminder);
                    
                    // Schedule daily notification
                    await NotificationService().scheduleFromReminder(reminder);
                    
                    syncedCount++;
                  }
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Synced $syncedCount reminders successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _accentPurple),
              child: const Text('Sync Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDietPlanDetails(DietPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.feedingSchedule.isNotEmpty) ...[
          _buildFeedingScheduleSection(plan.feedingSchedule),
          const SizedBox(height: 20),
        ],
        _buildListSection(
          title: 'Recommended Foods',
          icon: Icons.check_circle,
          iconColor: Colors.green,
          items: plan.recommendedFoods,
        ),
        const SizedBox(height: 20),
        _buildListSection(
          title: 'Restricted Foods (Avoid)',
          icon: Icons.cancel,
          iconColor: Colors.red,
          items: plan.restrictedFoods,
        ),
      ],
    );
  }

  Widget _buildFeedingScheduleSection(List<String> items) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: AppColors.accentYellow),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Feeding Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _syncFeedingReminders(items),
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accentYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }


  Widget _buildListSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text('No items listed.', style: TextStyle(color: Colors.grey.shade600))
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
}
}

