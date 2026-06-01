import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/reminder_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/add_reminder_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/reminder_card.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/notification_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../application/services/notification_service.dart';


class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isBatteryOptimizationIgnored = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    _checkBatteryOptimization();
  }

  Future<void> _checkBatteryOptimization() async {
    final ignored = await NotificationService().isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _isBatteryOptimizationIgnored = ignored;
      });
    }
  }

  Future<void> _requestDisableOptimization() async {
    await NotificationService().requestIgnoreBatteryOptimizations();
    // Wait a brief moment and check again
    await Future.delayed(const Duration(seconds: 1));
    await _checkBatteryOptimization();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final pendingReminders = reminders.where((r) => !r.isCompleted).toList();
    final completedReminders = reminders.where((r) => r.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              expandedHeight: 160,
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              title: const Text('Reminders'),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.mainGradient,
                  ),
                ),
              ),
              bottom: const TabBar(
                indicatorColor: AppColors.accentYellow,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  _RemindersList(
                    reminders: pendingReminders,
                    isPending: true,
                    isBatteryOptimizationIgnored: _isBatteryOptimizationIgnored,
                    onRequestDisableOptimization: _requestDisableOptimization,
                  ),
                  _RemindersList(
                    reminders: completedReminders,
                    onRequestDisableOptimization: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddReminderScreen()),
        ),
        backgroundColor: AppColors.accentPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white)),
      ),
    );
  }


  Widget _buildTabContent(
    List<Reminder> pendingReminders,
    List<Reminder> completedReminders,
  ) {
    return Container(); // Placeholder as it's handled in CustomScrollView now
  }
}


class _EmptyRemindersView extends StatelessWidget {
  const _EmptyRemindersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 1200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF471396).withOpacity(0.1),
                        Color(0xFFB13BFF).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Color(0xFF471396).withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 80,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'No reminders yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your first reminder to keep\nyour pet care schedule organized',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 201, 201, 201).withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB13BFF), Color(0xFFFFCC00)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFB13BFF).withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const AddReminderScreen(),
                            transitionDuration: Duration(milliseconds: 300),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: Icon(Icons.add_rounded, color: Colors.white),
                    label: Text(
                      'Create Reminder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BatteryOptimizationWarning extends StatelessWidget {
  final VoidCallback onTap;

  const _BatteryOptimizationWarning({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade900.withOpacity(0.25),
            Colors.orange.shade800.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Precise Alarms & Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Battery saver is delaying notifications. Enable unrestricted background activity.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Fix',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemindersList extends ConsumerWidget {
  final List<Reminder> reminders;
  final bool isPending;
  final bool isBatteryOptimizationIgnored;
  final VoidCallback onRequestDisableOptimization;

  const _RemindersList({
    required this.reminders,
    this.isPending = false,
    this.isBatteryOptimizationIgnored = true,
    required this.onRequestDisableOptimization,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showWarning = isPending && !isBatteryOptimizationIgnored;

    if (reminders.isEmpty) {
      if (showWarning) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _BatteryOptimizationWarning(onTap: onRequestDisableOptimization),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending reminders',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 60,
              color: Color.fromARGB(255, 228, 228, 228).withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders in this category',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final displayCount = reminders.length + (showWarning ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: displayCount,
      itemBuilder: (context, index) {
        if (showWarning && index == 0) {
          return _BatteryOptimizationWarning(onTap: onRequestDisableOptimization);
        }

        final reminderIndex = showWarning ? index - 1 : index;
        final reminder = reminders[reminderIndex];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (reminderIndex * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Dismissible(
                  key: Key(reminder.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Delete Reminder'),
                          content: const Text('Are you sure you want to delete this reminder?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(remindersProvider.notifier).deleteReminder(reminder.id);
                    NotificationService().cancelReminder(reminder.id.hashCode.abs());
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder deleted')),
                    );
                  },
                  child: ReminderCard(reminder: reminder),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
