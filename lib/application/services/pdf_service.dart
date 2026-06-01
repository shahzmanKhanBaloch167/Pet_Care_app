import 'dart:io';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  Future<void> generateAndShareHealthReport(Pet pet) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(pet),
            pw.SizedBox(height: 20),
            if (pet.vaccinations.isNotEmpty) ...[
              _buildSectionTitle('Vaccinations & Preventive Care'),
              pw.SizedBox(height: 10),
              _buildVaccinationTable(pet),
              pw.SizedBox(height: 30),
            ],
            if (pet.medicalHistory.isNotEmpty) ...[
              _buildSectionTitle('Medical History'),
              pw.SizedBox(height: 10),
              _buildMedicalHistoryList(pet),
            ],
            if (pet.vaccinations.isEmpty && pet.medicalHistory.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No health records found for ${pet.name}.',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              )
          ];
        },
      ),
    );

    // Save to temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${pet.name}_Health_Report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareXFiles([XFile(file.path)], text: '${pet.name}\\s Health Report');
  }

  pw.Widget _buildHeader(Pet pet) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F9FA'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pet Health Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#090040')),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('Name:', pet.name),
                  _buildHeaderRow('Species/Breed:', pet.breed),
                  _buildHeaderRow('Age:', '${pet.age} years'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow('Weight:', pet.weight != null ? '${pet.weight} kg' : 'Unknown'),
                  _buildHeaderRow('Allergies:', pet.allergies.isNotEmpty ? pet.allergies.join(', ') : 'None'),
                  _buildHeaderRow('Date:', DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          pw.SizedBox(width: 8),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#471396')),
      ),
    );
  }

  pw.Widget _buildVaccinationTable(Pet pet) {
    final headers = ['Vaccine/Medicine', 'Administered', 'Next Due', 'Veterinarian'];
    final data = pet.vaccinations.map((v) {
      return [
        v.name,
        DateFormat('MMM dd, yyyy').format(v.dateAdministered),
        v.nextDueDate != null ? DateFormat('MMM dd, yyyy').format(v.nextDueDate!) : 'N/A',
        v.veterinarian?.isNotEmpty ?? false ? 'Dr. ${v.veterinarian}' : 'N/A',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#B13BFF')),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.centerLeft,
      },
    );
  }

  pw.Widget _buildMedicalHistoryList(Pet pet) {
    return pw.Column(
      children: pet.medicalHistory.map((record) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    record.title,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    DateFormat('MMM dd, yyyy').format(record.date),
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                record.description,
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (record.veterinarian.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Veterinarian: Dr. ${record.veterinarian}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
