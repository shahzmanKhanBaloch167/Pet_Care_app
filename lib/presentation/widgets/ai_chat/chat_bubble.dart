import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';
import 'package:flutter_pet_care_and_veterinary_app/data/models/chat_message.dart';
import 'package:intl/intl.dart';

/// A single chat bubble widget for user or AI messages
/// Renders AI responses as markdown for rich formatting
class ChatBubbleWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatBubbleWidget({super.key, required this.message});

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _isUser ? AppGradients.mainGradient : null,
                    color: _isUser
                        ? null
                        : (isDark
                            ? const Color(0xFF1E1E3F)
                            : const Color(0xFFF0EDFA)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(_isUser ? 20 : 4),
                      bottomRight: Radius.circular(_isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        )
                      : _buildMarkdownContent(isDark),
                ),
                // Action confirmation card
                if (message.actionType != ChatActionType.none &&
                    message.actionData != null)
                  _buildActionCard(isDark),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Renders AI response as markdown with proper theming
  Widget _buildMarkdownContent(bool isDark) {
    final cleanContent = _cleanActionTags(message.content);
    return MarkdownBody(
      data: cleanContent,
      shrinkWrap: true,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.9) : AppColors.primaryDark,
          fontSize: 15,
          height: 1.5,
        ),
        h1: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        strong: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.8) : AppColors.primaryDark,
          fontStyle: FontStyle.italic,
        ),
        listBullet: TextStyle(
          color: isDark ? AppColors.accentPurple : AppColors.primaryPurple,
          fontSize: 15,
        ),
        code: TextStyle(
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.primaryPurple.withOpacity(0.06),
          color: isDark ? AppColors.accentPurple : AppColors.primaryPurple,
          fontSize: 13,
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : AppColors.primaryPurple.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.accentPurple.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        tableBorder: TableBorder.all(
          color: isDark ? Colors.white24 : AppColors.border,
          width: 1,
        ),
        tableHead: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        tableBody: TextStyle(
          color: isDark ? Colors.white70 : AppColors.primaryDark,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: AppGradients.accentGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _buildActionCard(bool isDark) {
    IconData icon;
    String label;
    Color color;

    switch (message.actionType) {
      case ChatActionType.mealLog:
        icon = Icons.restaurant_rounded;
        label = 'Meal Logged';
        color = const Color(0xFF4CAF50);
        break;
      case ChatActionType.addMedical:
        icon = Icons.medical_services_rounded;
        label = 'Medical Record Added';
        color = const Color(0xFFFF9800);
        break;
      case ChatActionType.addVaccine:
        icon = Icons.vaccines_rounded;
        label = 'Vaccine Suggested';
        color = const Color(0xFF2196F3);
        break;
      case ChatActionType.addReminder:
        icon = Icons.alarm_rounded;
        label = 'Reminder Created';
        color = const Color(0xFF9C27B0);
        break;
      case ChatActionType.none:
        return const SizedBox.shrink();
    }

    final data = message.actionData!;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getActionSummary(data),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  String _getActionSummary(Map<String, dynamic> data) {
    switch (message.actionType) {
      case ChatActionType.mealLog:
        return '${data['mealType'] ?? ''} — ${data['foodName'] ?? ''}';
      case ChatActionType.addMedical:
        return data['title'] ?? '';
      case ChatActionType.addVaccine:
        return data['name'] ?? '';
      case ChatActionType.addReminder:
        return '${data['title'] ?? ''} (${data['type'] ?? 'other'})';
      case ChatActionType.none:
        return '';
    }
  }

  /// Remove action tags from display text
  String _cleanActionTags(String content) {
    return content.replaceAll(RegExp(r'<<<ACTION:.*?>>>'), '').trim();
  }
}
