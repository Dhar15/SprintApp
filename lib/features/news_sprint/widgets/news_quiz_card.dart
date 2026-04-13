import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/news_model.dart';
import '../../../core/theme/app_theme.dart';

class NewsQuizCard extends StatelessWidget {
  final NewsQuizQuestion question;
  final int index;
  final int total;
  final int? selectedOption;
  final bool revealed;
  final Function(int) onSelect;
  final VoidCallback onNext;  
  final String explanation;

  const NewsQuizCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.selectedOption,
    required this.revealed,
    required this.onSelect,
    required this.onNext,
    required this.explanation,
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
              const SizedBox(height: 28),
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
                color: AppColors.newsGlow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'QUIZ',
                style: GoogleFonts.dmSans(
                  color: AppColors.newsAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${index + 1} / $total',
              style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (index + 1) / total,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.newsAccent),
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
        // Context hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📰', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      question.article.source.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: AppColors.newsAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      question.article.title,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 20),

        Text(
          question.question,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 24),

        ...List.generate(question.options.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NewsOptionTile(
              label: String.fromCharCode(65 + i),
              text: question.options[i],
              state: _getState(i),
              onTap: revealed ? null : () => onSelect(i),
            ).animate().fadeIn(delay: Duration(milliseconds: 100 + i * 50)),
          );
        }),
      ],
    );
  }

  _OptionState _getState(int i) {
    if (!revealed) return _OptionState.normal;
    if (i == question.correctIndex) return _OptionState.correct;
    if (i == selectedOption) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  Widget _buildNextButton() {
    final isCorrect = selectedOption == question.correctIndex;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: isCorrect ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? 'Correct!' : 'Not quite',
                    style: GoogleFonts.dmSans(
                      color: isCorrect ? AppColors.success : AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.newsAccent,
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
              if (question.explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  question.explanation,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
      ],
    );
  }
}

enum _OptionState { normal, correct, wrong, dimmed }

class _NewsOptionTile extends StatelessWidget {
  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _NewsOptionTile({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: labelBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: state == _OptionState.correct || state == _OptionState.wrong
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.dmSans(
                  color: textColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
