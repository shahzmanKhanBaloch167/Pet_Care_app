import 'package:flutter_pet_care_and_veterinary_app/data/datasources/local/storage_service.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/chat_message.dart';
import 'package:flutter_pet_care_and_veterinary_app/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Family provider keyed by petId — each pet has its own chat history
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, List<ChatMessage>, String>((ref, petId) {
  final storage = ref.watch(storageServiceProvider);
  return ChatMessagesNotifier(storage, petId);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final StorageService _storage;
  final String _petId;

  ChatMessagesNotifier(this._storage, this._petId) : super([]) {
    state = _storage.getChatMessages(_petId);
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
    _storage.saveChatMessages(_petId, state);
  }

  void clearChat() {
    state = [];
    _storage.clearChatMessages(_petId);
  }
}
