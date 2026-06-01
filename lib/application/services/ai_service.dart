import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/meal_log.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/medical_record.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/vaccine.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class AiService {
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AiService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Generic method to generate structured JSON output based on a provided schema
  Future<Map<String, dynamic>?> generateStructuredData(
      String prompt, Schema schema) async {
    final modelWithSchema = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );

    try {
      final response =
          await modelWithSchema.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        return jsonDecode(response.text!);
      }
    } catch (e) {
      print('AI Error: $e');
    }
    return null;
  }

  /// Creates a pet-scoped chat session with full context about the selected pet
  void createPetChatSession({
    required Pet pet,
    required List<Reminder> reminders,
    required List<MealLog> todaysMeals,
  }) {
    final petReminders = reminders
        .where((r) => r.petId == pet.id)
        .map((r) =>
            '- ${r.title}: ${r.description} (${DateFormat('MMM d, h:mm a').format(r.dateTime)}, type: ${r.type.name}, ${r.isCompleted ? "completed" : "pending"})')
        .join('\n');

    final medicalHistory = pet.medicalHistory
        .map((r) =>
            '- ${r.title}: ${r.description} (${DateFormat('MMM d, y').format(r.date)}, vet: ${r.veterinarian}, status: ${r.status.name})')
        .join('\n');

    final vaccinations = pet.vaccinations
        .map((v) =>
            '- ${v.name} (administered: ${DateFormat('MMM d, y').format(v.dateAdministered)}${v.nextDueDate != null ? ', next due: ${DateFormat('MMM d, y').format(v.nextDueDate!)}' : ''}, status: ${v.status.name}${v.notes != null ? ', notes: ${v.notes}' : ''})')
        .join('\n');

    final dietInfo = pet.dietPlan != null
        ? '''
Diet Plan:
  Feeding schedule: ${pet.dietPlan!.feedingSchedule.join(', ')}
  Recommended foods: ${pet.dietPlan!.recommendedFoods.join(', ')}
  Restricted foods: ${pet.dietPlan!.restrictedFoods.join(', ')}
  Daily water target: ${pet.dietPlan!.dailyWaterTargetMl}ml
  Current water intake: ${pet.dietPlan!.waterIntakeMl}ml'''
        : 'No diet plan configured yet.';

    final todaysMealInfo = todaysMeals.isNotEmpty
        ? todaysMeals
            .map((m) =>
                '- ${m.mealTypeLabel}: ${m.foodName}${m.portionDescription.isNotEmpty ? ' (${m.portionDescription})' : ''} at ${DateFormat('h:mm a').format(m.timestamp)} [${m.isChecked ? "✅ fed" : "⬜ not yet"}]')
            .join('\n')
        : 'No meals logged today.';

    final systemInstruction = '''
You are Dr. PetPal, an expert AI veterinary assistant integrated into the PetPal pet care app.
You are currently helping with a pet named "${pet.name}".

=== PET PROFILE ===
Name: ${pet.name}
Breed: ${pet.breed}
Age: ${pet.age} years old
Gender: ${pet.gender}
Weight: ${pet.weight != null ? '${pet.weight} kg' : 'Not recorded'}
Allergies: ${pet.allergies.isNotEmpty ? pet.allergies.join(', ') : 'None recorded'}
Notes: ${pet.notes ?? 'None'}

=== MEDICAL HISTORY ===
${medicalHistory.isNotEmpty ? medicalHistory : 'No medical records.'}

=== VACCINATIONS ===
${vaccinations.isNotEmpty ? vaccinations : 'No vaccinations recorded.'}

=== DIET & NUTRITION ===
$dietInfo

=== TODAY'S MEALS ===
$todaysMealInfo

=== REMINDERS ===
${petReminders.isNotEmpty ? petReminders : 'No reminders set.'}

=== YOUR CAPABILITIES ===
You can help the user with:

1. **Veterinary advice** — Answer health questions about ${pet.name} based on their profile, breed, age, and medical history. Use markdown formatting (bold, lists, headers) for clear, readable responses.

2. **Log meals** — When the user wants to log a meal, respond normally AND include this JSON block at the END of your response on its own line:
   <<<ACTION:MEAL_LOG:{"mealType":"breakfast|lunch|dinner|snack","foodName":"food description","portionDescription":"portion info"}>>>

3. **Add medical record (suggested)** — When the user mentions a medical concern or you recommend a check-up, include:
   <<<ACTION:ADD_MEDICAL:{"title":"Record title","description":"Description","veterinarian":"AI Suggested"}>>>

4. **Suggest vaccine** — When the user asks about or you recommend a vaccine, include:
   <<<ACTION:ADD_VACCINE:{"name":"Vaccine name","notes":"Why it is recommended"}>>>
   Note: This adds the vaccine as "suggested" — NOT as an administered record. The user can mark it as done later.

5. **Add reminder** — When the user asks to set any reminder (feeding, medication, grooming, checkup, exercise, vaccination, appointment, etc.), include:
   <<<ACTION:ADD_REMINDER:{"title":"Reminder title","description":"Description","type":"medication|vaccination|grooming|checkup|feeding|appointment|exercise|veterinary|other","hour":8,"minute":0}>>>
   Available reminder types: medication, vaccination, grooming, checkup, feeding, appointment, exercise, veterinary, other.
   The hour and minute should be in 24-hour format.

=== RULES ===
- Always be warm, caring, and professional.
- Use **markdown formatting** in your responses — use bold, bullet lists, headers, and emphasis for clarity. This makes your responses more readable.
- Base your advice on ${pet.name}'s specific profile (breed, age, weight, allergies, history).
- When recommending medical visits or vaccines, use the action tags to add them to the app.
- For meal logging, always confirm what you logged.
- For reminders, confirm the time and type you created.
- If you don't have enough info, ask follow-up questions.
- Keep responses concise but thorough.
- You are NOT a replacement for a real veterinarian — for emergencies, always advise visiting a vet.
- Do not respond to questions unrelated to pets and pet care.
- You can only include ONE action tag per response. If the user asks for multiple actions, handle one at a time and ask them to confirm for the next.
''';

    final chatModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(systemInstruction),
    );

    _chatSession = chatModel.startChat();
  }

  /// Sends a message in the current chat session and returns the AI response
  Future<String> sendChatMessage(String message) async {
    if (_chatSession == null) {
      return 'Chat session not initialized. Please try again.';
    }

    try {
      final response =
          await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'I could not generate a response. Please try again.';
    } catch (e) {
      print('AI Chat Error: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  /// Disposes the current chat session
  void disposeChatSession() {
    _chatSession = null;
  }
}
