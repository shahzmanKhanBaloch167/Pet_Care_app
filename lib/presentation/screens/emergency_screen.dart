import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/emergency_contact_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/first_aid_guide.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/bottom_navigation_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergencyContacts = ref.watch(emergencyContactsProvider);
    final firstAidGuides = ref.watch(firstAidGuidesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonized colors depending on Theme Mode
    final Color cardBackground = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final Color cardBorder = isDark ? Colors.white.withOpacity(0.08) : AppColors.border;
    final Color titleColor = isDark ? Colors.white : AppColors.primaryDark;
    final Color subtitleColor = isDark ? Colors.white.withOpacity(0.7) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Emergency Support',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Premium Floating Emergency Card (Matches Home Screen Welcome card design)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB71C1C).withOpacity(0.3),
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
                            'Emergency Center',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quick access to professional support and immediate care instructions.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                              height: 1.4,
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
                                  Icons.lock_clock,
                                  color: AppColors.accentYellow,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Available 24/7',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency_share_outlined,
                        color: AppColors.accentYellow,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Emergency Contacts Section
            _buildSection(
              context: context,
              title: 'Emergency Hotlines',
              icon: Icons.phone_in_talk_rounded,
              child: Column(
                children: emergencyContacts.map((contact) {
                  return _buildContactCard(
                    context: context,
                    contact: contact,
                    backgroundColor: cardBackground,
                    borderColor: cardBorder,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // First Aid Guides Section
            _buildSection(
              context: context,
              title: 'First Aid Manual',
              icon: Icons.medical_services_rounded,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemCount: firstAidGuides.length,
                itemBuilder: (context, index) {
                  return _buildFirstAidCard(
                    context: context,
                    guide: firstAidGuides[index],
                    backgroundColor: cardBackground,
                    borderColor: cardBorder,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                  );
                },
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(currentIndex: 2),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sectionHeaderColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:  Icon(icon, color: Color(0xFFD32F2F), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: sectionHeaderColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required EmergencyContact contact,
    required Color backgroundColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = contact.isDefault ? const Color(0xFFD32F2F) : AppColors.primaryPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: contact.isDefault 
            ? (isDark ? const Color(0xFF2D1414) : const Color(0xFFFFF5F5))
            : backgroundColor,
        borderRadius: AppStyles.cardRadius,
        border: Border.all(
          color: contact.isDefault 
              ? const Color(0xFFD32F2F).withOpacity(0.3) 
              : borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppStyles.cardRadius,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  contact.isDefault ? Icons.emergency_rounded : Icons.person_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              title: Text(
                contact.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: contact.isDefault && !isDark ? const Color(0xFFB71C1C) : titleColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (contact.address.isNotEmpty)
                    Text(
                      contact.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  if (contact.email.isNotEmpty)
                    Text(
                      contact.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  if (contact.isDefault)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Priority Emergency Line',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contact.email.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.email_outlined, color: isDark ? Colors.white70 : AppColors.primaryPurple),
                      onPressed: () => _sendEmail(contact.email, context),
                    ),
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: Color(0xFFD32F2F)),
                    onPressed: () => _makePhoneCall(contact.phone, context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFirstAidCard({
    required BuildContext context,
    required FirstAidGuide guide,
    required Color backgroundColor,
    required Color borderColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppStyles.cardRadius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppStyles.cardRadius,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Color(0xFFD32F2F),
                width: 4,
              ),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFirstAidDialog(context, guide),
              borderRadius: AppStyles.cardRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child:  Icon(guide.icon , size: 26, color: Color(0xFFD32F2F)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      guide.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        guide.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendEmail(String email, BuildContext context) async {
    final String subject = Uri.encodeComponent('Pet Emergency - Urgent Support Required');
    final String body = Uri.encodeComponent(
      'Hello,\n\nI am contacting you regarding an urgent pet care emergency. Please get in touch with me as soon as possible.',
    );
    final Uri url = Uri.parse('mailto:$email?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email application: $e')),
        );
      }
    }
  }

  void _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate phone call: $e')),
        );
      }
    }
  }

  void _showFirstAidDialog(BuildContext context, FirstAidGuide guide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(guide.icon, color: const Color(0xFFD32F2F), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    guide.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guide.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Action Steps:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...guide.steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(color: isDark ? AppColors.accentPurple : AppColors.primaryPurple),
                ),
              ),
            ],
          ),
    );
  }
}
