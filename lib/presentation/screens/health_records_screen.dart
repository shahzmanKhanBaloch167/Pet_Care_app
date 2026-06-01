import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/notification_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/medical_record.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/vaccine.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/pdf_service.dart';

import '../../application/services/notification_service.dart';

class HealthRecordsScreen extends ConsumerStatefulWidget {
  final Pet pet;

  const HealthRecordsScreen({super.key, required this.pet});

  @override
  ConsumerState<HealthRecordsScreen> createState() =>
      _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends ConsumerState<HealthRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryDark = Color(0xFF090040);
  static const Color primaryPurple = Color(0xFF471396);
  static const Color accentPurple = Color(0xFFB13BFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddMedicalRecordSheet(BuildContext context, Pet currentPet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMedicalRecordSheet(pet: currentPet),
    );
  }

  void _showAddVaccineSheet(BuildContext context, Pet currentPet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddVaccineSheet(pet: currentPet),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider);
    final currentPet = pets.firstWhere(
      (p) => p.id == widget.pet.id,
      orElse: () => widget.pet,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text(
          'Health Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export & Share PDF',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF Report...')),
              );
              try {
                await PdfService().generateAndShareHealthReport(currentPet);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to generate PDF: $e')),
                  );
                }
              }
            },
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentYellow,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: const [
            Tab(text: 'Medical History', icon: Icon(Icons.medical_services)),
            Tab(text: 'Vaccines', icon: Icon(Icons.vaccines)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicalHistoryTab(currentPet),
          _buildVaccinesTab(currentPet),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddMedicalRecordSheet(context, currentPet);
          } else {
            _showAddVaccineSheet(context, currentPet);
          }
        },
        backgroundColor: AppColors.accentPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Record' : 'Add Vaccine',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
    );
  }


  Widget _buildMedicalHistoryTab(Pet currentPet) {
    if (currentPet.medicalHistory.isEmpty) {
      return _buildEmptyState(
        'No medical records yet',
        'Track vet visits and illness histories here.',
        Icons.medical_services_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: currentPet.medicalHistory.length,
      itemBuilder: (context, index) {
        return _MedicalRecordCard(record: currentPet.medicalHistory[index]);
      },
    );
  }

  Widget _buildVaccinesTab(Pet currentPet) {
    if (currentPet.vaccinations.isEmpty) {
      return _buildEmptyState(
        'No vaccines or deworming records',
        'Add preventive care records to set upcoming reminders.',
        Icons.vaccines_outlined,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: currentPet.vaccinations.length,
      itemBuilder: (context, index) {
        return _VaccineCard(vaccine: currentPet.vaccinations[index]);
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: accentPurple),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;

  const _MedicalRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape:RoundedRectangleBorder(borderRadius: AppStyles.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppStyles.cardRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(record.date),
                      style: const TextStyle(
                        color: AppColors.accentPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (record.veterinarian.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dr. ${record.veterinarian}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _VaccineCard extends StatelessWidget {
  final Vaccine vaccine;

  const _VaccineCard({required this.vaccine});

  @override
  Widget build(BuildContext context) {
    final bool isDueSoon = vaccine.nextDueDate != null &&
        vaccine.nextDueDate!.difference(DateTime.now()).inDays <= 14 &&
        vaccine.nextDueDate!.isAfter(DateTime.now());
    final bool isOverdue = vaccine.nextDueDate != null &&
        vaccine.nextDueDate!.isBefore(DateTime.now());

    Color statusColor = const Color(0xFF471396);
    if (isOverdue) {
      statusColor = Colors.red;
    } else if (isDueSoon) {
      statusColor = const Color(0xFFFFCC00);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vaccine.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF090040),
                          ),
                        ),
                      ),
                      if (vaccine.nextDueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOverdue
                                ? 'Overdue!'
                                : (isDueSoon ? 'Due Soon!' : 'Up to Date'),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_available, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Administered: ${DateFormat('MMM dd, yyyy').format(vaccine.dateAdministered)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  if (vaccine.nextDueDate != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_repeat, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Next Due: ${DateFormat('MMM dd, yyyy').format(vaccine.nextDueDate!)}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : Colors.grey,
                            fontSize: 14,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (vaccine.notes != null && vaccine.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      vaccine.notes!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom sheets
class _AddMedicalRecordSheet extends ConsumerStatefulWidget {
  final Pet pet;

  const _AddMedicalRecordSheet({required this.pet});

  @override
  ConsumerState<_AddMedicalRecordSheet> createState() =>
      _AddMedicalRecordSheetState();
}

class _AddMedicalRecordSheetState extends ConsumerState<_AddMedicalRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _veterinarianController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _veterinarianController.dispose();
    super.dispose();
  }

  void _saveMedicalRecord() {
    if (_formKey.currentState!.validate()) {
      final record = MedicalRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        veterinarian: _veterinarianController.text,
      );

      ref.read(petsProvider.notifier).addMedicalRecord(widget.pet.id, record);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBottomSheetContainer(
      context: context,
      title: 'Add Medical Record',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g., Annual Checkup',
              icon: Icons.title,
              validator: (v) => v!.isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Details about the visit',
              icon: Icons.description,
              maxLines: 3,
              validator: (v) => v!.isEmpty ? 'Enter a description' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _veterinarianController,
              label: 'Veterinarian (Optional)',
              hint: 'Dr. Smith',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              context: context,
              label: 'Date',
              date: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 32),
            _buildSaveButton('Save Medical Record', _saveMedicalRecord),
          ],
        ),
      ),
    );
  }
}

class _AddVaccineSheet extends ConsumerStatefulWidget {
  final Pet pet;

  const _AddVaccineSheet({required this.pet});

  @override
  ConsumerState<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends ConsumerState<_AddVaccineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _veterinarianController = TextEditingController();
  DateTime _administeredDate = DateTime.now();
  DateTime? _nextDueDate;
  bool _setReminder = true;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _veterinarianController.dispose();
    super.dispose();
  }

  void _saveVaccine() {
    if (_formKey.currentState!.validate()) {
      final vaccine = Vaccine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        dateAdministered: _administeredDate,
        nextDueDate: _nextDueDate,
        veterinarian: _veterinarianController.text,
        notes: _notesController.text,
      );

      ref.read(petsProvider.notifier).addVaccination(widget.pet.id, vaccine);

      if (_setReminder && _nextDueDate != null) {
        NotificationService().scheduleFutureAlert(
          id: vaccine.id.hashCode,
          title: 'Upcoming Care: ${vaccine.name}',
          body: '${widget.pet.name} is due for ${vaccine.name} soon!',
          scheduledDate: _nextDueDate!.subtract(const Duration(days: 1)), // Alert 1 day before
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBottomSheetContainer(
      context: context,
      title: 'Add Vaccine / Preventive Care',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Vaccine / Medicine Name',
              hint: 'e.g., Rabies, Deworming',
              icon: Icons.vaccines,
              validator: (v) => v!.isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              context: context,
              label: 'Date Administered',
              date: _administeredDate,
              onDateSelected: (date) => setState(() => _administeredDate = date),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              context: context,
              label: 'Next Due Date (Optional)',
              date: _nextDueDate,
              onDateSelected: (date) => setState(() => _nextDueDate = date),
              allowNull: true,
            ),
            if (_nextDueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Set Reminder (1 Day Before)'),
                  Switch(
                    value: _setReminder,
                    activeColor: const Color(0xFFB13BFF),
                    onChanged: (val) => setState(() => _setReminder = val),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              controller: _veterinarianController,
              label: 'Veterinarian (Optional)',
              hint: 'Dr. Smith',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Brand name, lot number, etc.',
              icon: Icons.notes,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            _buildSaveButton('Save Record', _saveVaccine),
          ],
        ),
      ),
    );
  }
}

// Shared UI Builders for Bottom Sheets
Widget _buildBottomSheetContainer({required BuildContext context, required String title, required Widget child}) {
  return Container(
    height: MediaQuery.of(context).size.height * 0.9,
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF090040),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: child,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    validator: validator,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFFB13BFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB13BFF), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
  );
}

Widget _buildDatePicker({
  required BuildContext context,
  required String label,
  required DateTime? date,
  required Function(DateTime) onDateSelected,
  bool allowNull = false,
}) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(12),
      color: Colors.grey.shade50,
    ),
    child: ListTile(
      leading: const Icon(Icons.calendar_today, color: Color(0xFFB13BFF)),
      title: Text(label),
      subtitle: Text(
        date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Not set',
        style: TextStyle(
          color: date != null ? const Color(0xFF090040) : Colors.grey,
          fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onDateSelected(d);
      },
    ),
  );
}

Widget _buildSaveButton(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFB13BFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}
