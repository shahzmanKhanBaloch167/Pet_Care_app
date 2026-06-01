import 'package:flutter_pet_care_and_veterinary_app/data/models/chat_message.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/emergency_contact.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/meal_log.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/pet.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _petsKey = 'pets';
  static const String _remindersKey = 'reminders';
  static const String _emergencyContactsKey = 'emergency_contacts';
  static const String _themeModeKey = 'theme_mode';
  static const String _chatMessagesKeyPrefix = 'chat_messages_';
  static const String _mealLogsKey = 'meal_logs';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Onboarding
  Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs.setBool(_onboardingKey, completed);
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  // Theme
  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_themeModeKey, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_themeModeKey) ?? 'system';
  }

  // Pets
  Future<bool> savePets(List<Pet> pets) async {
    final List<String> petJsonList = pets.map((pet) => pet.toJson()).toList();
    return await _prefs.setStringList(_petsKey, petJsonList);
  }

  List<Pet> getPets() {
    final List<String>? petJsonList = _prefs.getStringList(_petsKey);
    if (petJsonList == null) return [];
    return petJsonList.map((json) => Pet.fromJson(json)).toList();
  }

  // Reminders
  Future<bool> saveReminders(List<Reminder> reminders) async {
    final List<String> reminderJsonList =
        reminders.map((reminder) => reminder.toJson()).toList();
    return await _prefs.setStringList(_remindersKey, reminderJsonList);
  }

  List<Reminder> getReminders() {
    final List<String>? reminderJsonList = _prefs.getStringList(_remindersKey);
    if (reminderJsonList == null) return [];
    return reminderJsonList.map((json) => Reminder.fromJson(json)).toList();
  }

  // Emergency Contacts
  Future<bool> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final List<String> contactJsonList =
        contacts.map((contact) => contact.toJson()).toList();
    return await _prefs.setStringList(_emergencyContactsKey, contactJsonList);
  }

  List<EmergencyContact> getEmergencyContacts() {
    final List<String>? contactJsonList = _prefs.getStringList(
      _emergencyContactsKey,
    );
    if (contactJsonList == null) return [];
    return contactJsonList
        .map((json) => EmergencyContact.fromJson(json))
        .toList();
  }

  // Chat Messages (per pet)
  Future<bool> saveChatMessages(String petId, List<ChatMessage> messages) async {
    final key = '$_chatMessagesKeyPrefix$petId';
    final List<String> jsonList = messages.map((m) => m.toJson()).toList();
    return await _prefs.setStringList(key, jsonList);
  }

  List<ChatMessage> getChatMessages(String petId) {
    final key = '$_chatMessagesKeyPrefix$petId';
    final List<String>? jsonList = _prefs.getStringList(key);
    if (jsonList == null) return [];
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  Future<bool> clearChatMessages(String petId) async {
    final key = '$_chatMessagesKeyPrefix$petId';
    return await _prefs.remove(key);
  }

  // Meal Logs
  Future<bool> saveMealLogs(List<MealLog> logs) async {
    final List<String> jsonList = logs.map((log) => log.toJson()).toList();
    return await _prefs.setStringList(_mealLogsKey, jsonList);
  }

  List<MealLog> getMealLogs() {
    final List<String>? jsonList = _prefs.getStringList(_mealLogsKey);
    if (jsonList == null) return [];
    return jsonList.map((json) => MealLog.fromJson(json)).toList();
  }

  // Clear all data
  Future<bool> clearAllData() async {
    await _prefs.remove(_petsKey);
    await _prefs.remove(_remindersKey);
    await _prefs.remove(_emergencyContactsKey);
    await _prefs.remove(_mealLogsKey);
    return true;
  }
}
