import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/emergency_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/home_screen.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/screens/pets_screen.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavigationBarWidget({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onItemTapped(context, index),
      backgroundColor: AppColors.primaryDark,
      indicatorColor: AppColors.accentPurple,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.pets_rounded, color: Colors.white),
          label: 'Pets',
        ),
        NavigationDestination(
          icon: Icon(Icons.emergency_outlined, color: Colors.white70),
          selectedIcon: Icon(Icons.emergency_rounded, color: Colors.white),
          label: 'Emergency',
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const PetsScreen();
        break;
      case 2:
        screen = const EmergencyScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
