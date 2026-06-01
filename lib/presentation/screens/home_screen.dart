import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/reminder_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/add_pet_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/ai_chat_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/pets_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/reminders_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/nearby_clinics_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/bottom_navigation_bar.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/reminder_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _staggerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);
    final reminders = ref.watch(remindersProvider);

    final upcomingReminders = reminders
        .where(
          (reminder) =>
              !reminder.isCompleted &&
              reminder.dateTime.isAfter(DateTime.now()),
        )
        .take(3)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // M3 Large App Bar
          SliverAppBar.large(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'PetPal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.mainGradient,
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Section
                _buildWelcomeSection(pets.length),
                const SizedBox(height: 32),

                // Quick Actions
                _buildQuickActionsSection(pets, reminders),
                const SizedBox(height: 32),

                // Upcoming Reminders
                if (upcomingReminders.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Upcoming Reminders',
                    Icons.notification_important_outlined,
                  ),
                  const SizedBox(height: 16),
                  ...upcomingReminders.asMap().entries.map((entry) {
                    return _buildAnimatedCard(
                      entry.key,
                      ReminderCard(reminder: entry.value),
                    );
                  }),
                  const SizedBox(height: 32),
                ],

                // Empty State
                if (pets.isEmpty) _buildEmptyState(),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAiFab(pets),
      bottomNavigationBar: const BottomNavigationBarWidget(currentIndex: 0),
    );
  }

  Widget _buildAiFab(List<Pet> pets) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _onAiFabTapped(pets),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
      ),
    );
  }

  void _onAiFabTapped(List<Pet> pets) {
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a pet first to use Dr. PetPal! 🐾'),
          backgroundColor: AppColors.accentPurple,
        ),
      );
      return;
    }

    if (pets.length == 1) {
      _navigateWithAnimation(AiChatScreen(pet: pets.first));
      return;
    }

    // Show pet selection bottom sheet
    _showPetSelectionSheet(pets);
  }

  void _showPetSelectionSheet(List<Pet> pets) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28)),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ask Dr. PetPal about...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a pet to get personalized advice',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ...pets.map((pet) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _navigateWithAnimation(AiChatScreen(pet: pet));
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : AppColors.primaryPurple.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.primaryPurple.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: pet.photoPath != null
                                  ? ClipOval(
                                      child: Image.asset(
                                        pet.photoPath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.pets_rounded,
                                                color: AppColors.accentPurple),
                                      ),
                                    )
                                  : const Icon(Icons.pets_rounded,
                                      color: AppColors.accentPurple),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pet.breed} • ${pet.age} years',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white54
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: isDark
                                  ? Colors.white30
                                  : AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(int petCount) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppGradients.mainGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have $petCount pet${petCount != 1 ? 's' : ''} to care for',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: AppColors.accentYellow,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Caring with love',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 85,
                    height: 85,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection(List pets, List reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', Icons.grid_view_rounded),
        const SizedBox(height: 16),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedQuickAction(
                    0,
                    _QuickActionCard(
                      icon: Icons.pets_rounded,
                      title: 'My Pets',
                      subtitle: '${pets.length} pets',
                      color: AppColors.primaryPurple,
                      onTap: () => _navigateWithAnimation(const PetsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnimatedQuickAction(
                    1,
                    _QuickActionCard(
                      icon: Icons.notifications_active_rounded,
                      title: 'Reminders',
                      subtitle:
                          '${reminders.where((r) => !r.isCompleted).length} pending',
                      color: AppColors.accentPurple,
                      onTap: () => _navigateWithAnimation(const RemindersScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnimatedQuickAction(
                    2,
                    _QuickActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Add Pet',
                      subtitle: 'Register new pet',
                      color: Colors.teal,
                      onTap: () => _navigateWithAnimation(const AddPetScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnimatedQuickAction(
                    3,
                    _QuickActionCard(
                      icon: Icons.local_hospital_rounded,
                      title: 'Nearby Clinics',
                      subtitle: 'Find vets nearby',
                      color: Colors.blueAccent,
                      onTap: () =>
                          _navigateWithAnimation(const NearbyClinicsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedQuickAction(int index, Widget child) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              index * 0.1,
              0.6 + (index * 0.1),
              curve: Curves.easeOutBack,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryPurple, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(
              index * 0.1,
              0.8 + (index * 0.1),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pets_rounded, size: 64, color: AppColors.accentYellow),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No pets registered yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first pet to get started on their health journey!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: () => _navigateWithAnimation(const AddPetScreen()),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Add Your First Pet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateWithAnimation(Widget destination) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
