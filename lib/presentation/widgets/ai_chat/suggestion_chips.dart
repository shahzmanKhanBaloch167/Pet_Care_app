import 'package:flutter/material.dart';
import 'package:flutter_pet_care_and_veterinary_app/core/constants/app_ui.dart';

/// Quick-action suggestion chips displayed above the chat input field
class SuggestionChipsWidget extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SuggestionChipsWidget({super.key, required this.onSuggestionTap});

  static const List<_Suggestion> _suggestions = [
    _Suggestion('🍽️ Log a meal', 'I want to log a meal for my pet'),
    _Suggestion('💉 Check vaccines', 'What vaccines does my pet need?'),
    _Suggestion('⏰ Set reminder', 'Set a feeding reminder for my pet'),
    _Suggestion('❤️ Health summary', 'Give me a health summary of my pet'),
    _Suggestion('🥗 Diet advice', 'What diet do you recommend for my pet?'),
    _Suggestion('💊 Medical check', 'What medical check-ups are due?'),
    _Suggestion('💧 Water intake', 'How much water should my pet drink daily?'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSuggestionTap(suggestion.prompt),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.accentPurple.withOpacity(0.12)
                      : AppColors.primaryPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accentPurple.withOpacity(0.25)
                        : AppColors.primaryPurple.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  suggestion.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.primaryPurple,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Suggestion {
  final String label;
  final String prompt;

  const _Suggestion(this.label, this.prompt);
}
