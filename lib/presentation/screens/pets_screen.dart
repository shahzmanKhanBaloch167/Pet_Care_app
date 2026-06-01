import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/add_pet_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/pet_profile_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/bottom_navigation_bar.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/pet_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class PetsScreen extends ConsumerStatefulWidget {
  const PetsScreen({super.key});

  @override
  ConsumerState<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends ConsumerState<PetsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TextEditingController _searchTextController;
  String _searchQuery = '';
  List<Pet> _filteredPets = [];
  bool _isSearching = false;

  // Professional Color Scheme
  static const Color _primaryDark = Color(0xFF090040);
  static const Color _primaryMedium = Color(0xFF471396);
  static const Color _primaryBright = Color(0xFFB13BFF);
  static const Color _accent = Color(0xFFFFCC00);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _cardSurface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _shadow = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _searchTextController = TextEditingController();

    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(petsProvider.notifier).checkDailyResets();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void _filterPets(List<Pet> pets) {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredPets = pets;
        _isSearching = false;
      } else {
        _filteredPets =
            pets.where((pet) {
              return pet.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  pet.breed.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  pet.gender.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
        _isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterPets(pets);
    });

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: pets.isEmpty ? _buildEmptyState() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: const BottomNavigationBarWidget(currentIndex: 1),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      surfaceTintColor: AppColors.white,
      title: const Text(
        'My Pets',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
          letterSpacing: -0.5,
        ),
      ),
      // actions: [
      //   Container(
      //     margin: const EdgeInsets.only(right: 16),
      //     child: IconButton(
      //       onPressed: () {
      //         // Add filter functionality
      //       },
      //       icon: Container(
      //         padding: const EdgeInsets.all(8),
      //         decoration: BoxDecoration(
      //           color: AppColors.surface,
      //           borderRadius: BorderRadius.circular(12),
      //           border: Border.all(color: AppColors.border),
      //         ),
      //         child: const Icon(Icons.tune, color: AppColors.primaryDark, size: 20),
      //       ),
      //     ),
      //   ),
      // ],
    );
  }


  Widget _buildFloatingActionButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryBright.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPetScreen()),
              ),
          backgroundColor: _primaryBright,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: _white, size: 24),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildSearchSection(),
          _buildStatsSection(),
          _buildPetsList(),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        child: SearchBar(
          controller: _searchTextController,
          onChanged: (value) {
            _searchQuery = value;
            _filterPets(ref.read(petsProvider));
          },
          hintText: 'Search pets by name, breed...',
          leading: const Icon(Icons.search, color: AppColors.primaryPurple),
          trailing: [
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchTextController.clear();
                  _searchQuery = '';
                  _filterPets(ref.read(petsProvider));
                },
              ),
          ],
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: AppStyles.inputRadius,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStatsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryMedium, _primaryBright],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryMedium.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                    'Total Pets',
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_filteredPets.length}',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.pets, color: _white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsList() {
    if (_filteredPets.isEmpty && _isSearching) {
      return _buildNoResultsView();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSearching ? 'Search Results' : 'Your Pets',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _primaryDark,
                  ),
                ),
                if (_isSearching)
                  Text(
                    '${_filteredPets.length} found',
                    style: const TextStyle(
                      fontSize: 16,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filteredPets.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: PetCard(
                        key: ValueKey(_filteredPets[index].id),
                        pet: _filteredPets[index],
                        index: index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.search_off,
                    size: 48,
                    color: _textSecondary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'No pets found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No pets match "$_searchQuery"\nTry adjusting your search terms',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_primaryMedium, _primaryBright],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryMedium.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.pets, size: 80, color: _white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to Pet Care',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Start your pet\'s health journey by adding\nyour first furry family member',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 50),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_primaryMedium, _primaryBright],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryMedium.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddPetScreen(),
                                ),
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 24, color: _white),
                                SizedBox(width: 16),
                                Text(
                                  'Add Your First Pet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              _buildFeatureCards(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Column(
      children: [
        const Text(
          'What you can do',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _primaryDark,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                Icons.medical_services,
                'Track Health',
                'Monitor medical records and vaccinations',
                _accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                Icons.calendar_today,
                'Schedule Care',
                'Set reminders for appointments',
                _primaryBright,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: _shadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
