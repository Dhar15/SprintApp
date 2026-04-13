import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../../../core/theme/app_theme.dart';

class QuizCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final int total;
  final int? selectedOption;
  final bool revealed;
  final Function(int) onSelect;
  final VoidCallback onNext;

  const QuizCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.selectedOption,
    required this.revealed,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              Expanded(child: _buildBody()),
              if (revealed) _buildNextButton(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.03);
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.wordGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'QUIZ',
                style: GoogleFonts.dmSans(
                  color: AppColors.wordAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${index + 1} / $total',
              style: GoogleFonts.dmSans(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (index + 1) / total,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.wordAccent),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Text(
          'What does "${question.word.word}" mean?',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 32),

        // Options
        ...List.generate(question.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              label: String.fromCharCode(65 + i), // A, B, C, D
              text: question.options[i],
              state: _getOptionState(i),
              onTap: revealed ? null : () => onSelect(i),
            ).animate().fadeIn(delay: Duration(milliseconds: 80 + i * 40))
              .slideX(begin: 0.03),
          );
        }),
      ],
    );
  }

  _OptionState _getOptionState(int index) {
    if (!revealed) return _OptionState.normal;
    if (index == question.correctIndex) return _OptionState.correct;
    if (index == selectedOption && index != question.correctIndex) {
      return _OptionState.wrong;
    }
    return _OptionState.dimmed;
  }

  Widget _buildNextButton() {
    final isCorrect = selectedOption == question.correctIndex;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCorrect
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct!' : 'Not quite',
                      style: GoogleFonts.dmSans(
                        color: isCorrect ? AppColors.success : AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 2),
                      Text(
                        question.options[question.correctIndex],
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.wordAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Next →',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
      ],
    );
  }
}

enum _OptionState { normal, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color labelBg;
    Color textColor;

    switch (state) {
      case _OptionState.correct:
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.08);
        labelBg = AppColors.success;
        textColor = AppColors.textPrimary;
      case _OptionState.wrong:
        borderColor = AppColors.error;
        bgColor = AppColors.error.withOpacity(0.08);
        labelBg = AppColors.error;
        textColor = AppColors.textPrimary;
      case _OptionState.dimmed:
        borderColor = AppColors.border.withOpacity(0.4);
        bgColor = AppColors.surface.withOpacity(0.4);
        labelBg = AppColors.border;
        textColor = AppColors.textTertiary;
      case _OptionState.normal:
        borderColor = AppColors.border;
        bgColor = AppColors.surface;
        labelBg = AppColors.surfaceElevated;
        textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: labelBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: state == _OptionState.correct || state == _OptionState.wrong
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.dmSans(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
