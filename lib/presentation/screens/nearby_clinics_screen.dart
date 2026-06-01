import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class NearbyClinicsScreen extends StatelessWidget {
  const NearbyClinicsScreen({Key? key}) : super(key: key);

  Future<void> _searchNearbyOnMaps() async {
    final query = Uri.encodeComponent("veterinary clinic near me");
    
    // Fallback to Apple Maps search if iOS and Google Maps is unavailable
    final appleMapsUrl = Uri.parse('http://maps.apple.com/?q=$query');
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    try {
      if (Platform.isIOS && await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Nearby Clinics'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: AppColors.accentPurple,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Find Vets Near You',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We can quickly search for the best veterinary clinics and animal hospitals near your current location using your device\'s native Maps app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _searchNearbyOnMaps,
                  icon: const Icon(Icons.explore, size: 24),
                  label: const Text(
                    'Search on Maps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
