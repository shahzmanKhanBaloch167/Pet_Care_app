import 'dart:convert';

enum ChatRole { user, assistant }

enum ChatActionType { none, mealLog, addMedical, addVaccine, addReminder }

class ChatMessage {
  final String id;
  final String content;
  final ChatRole role;
  final DateTime timestamp;
  final ChatActionType actionType;
  /// Optional JSON data for executed actions (stored for display confirmation)
  final Map<String, dynamic>? actionData;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.actionType = ChatActionType.none,
    this.actionData,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatRole? role,
    DateTime? timestamp,
    ChatActionType? actionType,
    Map<String, dynamic>? actionData,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'actionType': actionType.name,
      'actionData': actionData,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      role: ChatRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => ChatRole.user,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      actionType: ChatActionType.values.firstWhere(
        (e) => e.name == map['actionType'],
        orElse: () => ChatActionType.none,
      ),
      actionData: map['actionData'] != null
          ? Map<String, dynamic>.from(map['actionData'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source));
}
