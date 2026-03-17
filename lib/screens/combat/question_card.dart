import 'package:flutter/material.dart';

class QuestionCard extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final int? selectedIndex;
  final bool isEnabled;
  final void Function(int) onAnswer;
  /// When true, a subtle weapon-power hint is shown on the correct option
  /// before the player answers — faint enough to feel like an edge, not a
  /// giveaway.
  final bool showWeaponHint;

  const QuestionCard({
    super.key,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.isEnabled,
    required this.onAnswer,
    this.showWeaponHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            questionText,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) => _buildOption(i, cs)),
        ],
      ),
    );
  }

  Widget _buildOption(int index, ColorScheme cs) {
    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (selectedIndex != null) {
      if (index == correctIndex) {
        borderColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.12);
        textColor = Colors.green;
      } else if (index == selectedIndex) {
        borderColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.08);
        textColor = cs.onSurface.withValues(alpha: 0.4);
      } else {
        borderColor = cs.outline.withValues(alpha: 0.3);
        bgColor = Colors.transparent;
        textColor = cs.onSurface.withValues(alpha: 0.2);
      }
    } else if (showWeaponHint && index == correctIndex) {
      // Weapon-power hint — subtle glow on correct answer before selection
      borderColor = cs.primary.withValues(alpha: 0.45);
      bgColor = cs.primary.withValues(alpha: 0.09);
      textColor = cs.onSurface.withValues(alpha: 0.85);
    } else {
      borderColor = cs.outline;
      bgColor = Colors.transparent;
      textColor = cs.onSurface.withValues(alpha: 0.85);
    }

    return GestureDetector(
      onTap: isEnabled ? () => onAnswer(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                options[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
