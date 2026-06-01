import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/ai_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/chat_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/meal_log_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/pet_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/provider/reminder_provider.dart';
import 'package:flutter_pet_care_and_veterinary_app/application/services/notification_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/chat_message.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/meal_log.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/medical_record.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/vaccine.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/ai_chat/chat_bubble.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/ai_chat/suggestion_chips.dart';
import 'package:flutter_pet_care_and_veterinary_app/presentation/widgets/ai_chat/typing_indicator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

class AiChatScreen extends HookConsumerWidget {
  final Pet pet;

  const AiChatScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(chatMessagesProvider(pet.id));
    final isLoading = useState(false);
    final isSessionInitialized = useState(false);
    final inputController = useTextEditingController();
    final scrollController = useScrollController();
    final focusNode = useFocusNode();

    // Initialize AI chat session on first build
    useEffect(() {
      _initializeSession(ref, pet, isSessionInitialized);
      return () {
        ref.read(aiServiceProvider).disposeChatSession();
      };
    }, [pet.id]);

    // Auto-scroll to bottom when messages change
    useEffect(() {
      if (messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
      return null;
    }, [messages.length]);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1F) : AppColors.surface,
      appBar: _buildAppBar(context, ref, isDark),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: messages.isEmpty && !isLoading.value
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length + (isLoading.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isLoading.value) {
                        return const TypingIndicatorWidget();
                      }
                      return ChatBubbleWidget(message: messages[index]);
                    },
                  ),
          ),

          // Suggestion chips (show when empty or after AI response)
          if (!isLoading.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SuggestionChipsWidget(
                onSuggestionTap: (prompt) {
                  inputController.text = prompt;
                  _sendMessage(
                    ref,
                    context,
                    inputController,
                    isLoading,
                    scrollController,
                    pet,
                  );
                },
              ),
            ),

          // Input bar
          _buildInputBar(
            context,
            ref,
            isDark,
            inputController,
            isLoading,
            scrollController,
            focusNode,
          ),
        ],
      ),
    );
  }

  void _initializeSession(
      WidgetRef ref, Pet pet, ValueNotifier<bool> isSessionInitialized) {
    if (!isSessionInitialized.value) {
      final reminders = ref.read(remindersProvider);
      final todaysMeals =
          ref.read(mealLogsProvider.notifier).getTodaysMealsForPet(pet.id);
      // Read the latest pet data
      final currentPet = ref.read(petsProvider).firstWhere(
            (p) => p.id == pet.id,
            orElse: () => pet,
          );
      ref.read(aiServiceProvider).createPetChatSession(
            pet: currentPet,
            reminders: reminders,
            todaysMeals: todaysMeals,
          );
      isSessionInitialized.value = true;
    }
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, bool isDark) {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppGradients.accentGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. PetPal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Caring for ${pet.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'clear') {
              _showClearChatDialog(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppGradients.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.pets_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              'Hello! I\'m Dr. PetPal 🐾',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'I\'m your AI veterinary assistant.\nAsk me anything about ${pet.name}\'s health, diet, vaccines, or log a meal!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    TextEditingController controller,
    ValueNotifier<bool> isLoading,
    ScrollController scrollController,
    FocusNode focusNode,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141428) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E3F)
                    : const Color(0xFFF5F3FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : AppColors.primaryPurple.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask Dr. PetPal...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(
                  ref,
                  context,
                  controller,
                  isLoading,
                  scrollController,
                  pet,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.mainGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isLoading.value
                  ? null
                  : () => _sendMessage(
                        ref,
                        context,
                        controller,
                        isLoading,
                        scrollController,
                        pet,
                      ),
              icon: Icon(
                isLoading.value
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(
    WidgetRef ref,
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<bool> isLoading,
    ScrollController scrollController,
    Pet pet,
  ) async {
    final text = controller.text.trim();
    if (text.isEmpty || isLoading.value) return;

    controller.clear();

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      role: ChatRole.user,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider(pet.id).notifier).addMessage(userMessage);

    isLoading.value = true;

    // Get AI response
    final aiService = ref.read(aiServiceProvider);
    final responseText = await aiService.sendChatMessage(text);

    // Parse actions from response
    final actionResult = _parseActions(responseText);

    // Execute any actions
    ChatActionType actionType = ChatActionType.none;
    Map<String, dynamic>? actionData;

    if (actionResult != null) {
      actionType = actionResult.type;
      actionData = actionResult.data;

      _executeAction(ref, pet, actionType, actionData);
    }

    // Add AI message
    final aiMessage = ChatMessage(
      id: const Uuid().v4(),
      content: responseText,
      role: ChatRole.assistant,
      timestamp: DateTime.now(),
      actionType: actionType,
      actionData: actionData,
    );
    ref.read(chatMessagesProvider(pet.id).notifier).addMessage(aiMessage);

    isLoading.value = false;
  }

  /// Parse action tags from AI response
  _ActionResult? _parseActions(String response) {
    final actionRegex = RegExp(r'<<<ACTION:(\w+):(.+?)>>>');
    final match = actionRegex.firstMatch(response);

    if (match == null) return null;

    final actionTypeStr = match.group(1);
    final jsonStr = match.group(2);

    if (actionTypeStr == null || jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      ChatActionType type;
      switch (actionTypeStr) {
        case 'MEAL_LOG':
          type = ChatActionType.mealLog;
          break;
        case 'ADD_MEDICAL':
          type = ChatActionType.addMedical;
          break;
        case 'ADD_VACCINE':
          type = ChatActionType.addVaccine;
          break;
        case 'ADD_REMINDER':
          type = ChatActionType.addReminder;
          break;
        default:
          return null;
      }

      return _ActionResult(type: type, data: data);
    } catch (e) {
      print('Action parse error: $e');
      return null;
    }
  }

  /// Execute the parsed action (add meal log, medical record, or vaccine)
  void _executeAction(
    WidgetRef ref,
    Pet pet,
    ChatActionType type,
    Map<String, dynamic> data,
  ) {
    switch (type) {
      case ChatActionType.mealLog:
        final mealTypeStr = (data['mealType'] as String?) ?? 'snack';
        final mealType = MealType.values.firstWhere(
          (e) => e.name == mealTypeStr.toLowerCase(),
          orElse: () => MealType.snack,
        );
        ref.read(mealLogsProvider.notifier).addMealLog(
              MealLog(
                id: const Uuid().v4(),
                petId: pet.id,
                petName: pet.name,
                mealType: mealType,
                foodName: data['foodName'] ?? '',
                portionDescription: data['portionDescription'] ?? '',
                timestamp: DateTime.now(),
              ),
            );
        break;

      case ChatActionType.addMedical:
        ref.read(petsProvider.notifier).addMedicalRecord(
              pet.id,
              MedicalRecord(
                id: const Uuid().v4(),
                title: data['title'] ?? 'AI Recommended Check',
                description: data['description'] ?? '',
                date: DateTime.now(),
                veterinarian: data['veterinarian'] ?? 'AI Recommended',
                status: RecordStatus.needed,
              ),
            );
        break;

      case ChatActionType.addVaccine:
        ref.read(petsProvider.notifier).addVaccination(
              pet.id,
              Vaccine(
                id: const Uuid().v4(),
                name: data['name'] ?? 'AI Recommended Vaccine',
                dateAdministered: DateTime.now(),
                notes: data['notes'] ?? 'Suggested by Dr. PetPal',
                status: VaccineStatus.needed,
              ),
            );
        break;

      case ChatActionType.addReminder:
        final hour = (data['hour'] as num?)?.toInt() ?? 8;
        final minute = (data['minute'] as num?)?.toInt() ?? 0;
        final now = DateTime.now();
        var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
        // If the time has already passed today, schedule for tomorrow
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
        final typeStr = (data['type'] as String?) ?? 'other';
        final reminderType = ReminderType.values.firstWhere(
          (e) => e.name == typeStr.toLowerCase(),
          orElse: () => ReminderType.other,
        );
        // AI-created feeding reminders default to daily
        final aiFrequency = reminderType == ReminderType.feeding
            ? ReminderFrequency.daily
            : ReminderFrequency.once;
        final reminder = Reminder(
          id: const Uuid().v4(),
          petId: pet.id,
          petName: pet.name,
          title: data['title'] ?? 'AI Reminder',
          description: data['description'] ?? 'Created by Dr. PetPal',
          dateTime: scheduledDate,
          type: reminderType,
          isCompleted: false,
          frequency: aiFrequency,
        );
        ref.read(remindersProvider.notifier).addReminder(reminder);

        // Schedule notification based on frequency
        NotificationService().scheduleFromReminder(reminder);
        break;

      case ChatActionType.none:
        break;
    }
  }

  void _showClearChatDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: Text(
          'Clear Chat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.primaryDark,
          ),
        ),
        content: Text(
          'This will delete all messages with Dr. PetPal for ${pet.name}. This cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatMessagesProvider(pet.id).notifier).clearChat();
              // Re-initialize the chat session
              final reminders = ref.read(remindersProvider);
              final todaysMeals =
                  ref.read(mealLogsProvider.notifier).getTodaysMealsForPet(pet.id);
              final currentPet = ref.read(petsProvider).firstWhere(
                    (p) => p.id == pet.id,
                    orElse: () => pet,
                  );
              ref.read(aiServiceProvider).createPetChatSession(
                    pet: currentPet,
                    reminders: reminders,
                    todaysMeals: todaysMeals,
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ActionResult {
  final ChatActionType type;
  final Map<String, dynamic> data;

  _ActionResult({required this.type, required this.data});
}
