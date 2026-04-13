import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/word_model.dart';
import '../../../core/theme/app_theme.dart';

class WordCard extends StatelessWidget {
  final WordModel word;
  final int index;
  final int total;
  final VoidCallback onNext;

  const WordCard({
    super.key,
    required this.word,
    required this.index,
    required this.total,
    required this.onNext,
  });

  Color get _difficultyColor {
    switch (word.difficulty) {
      case 'easy': return AppColors.success;
      case 'hard': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          onNext();
        }
      },
      onTap: onNext,
      child: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgress(),
                const SizedBox(height: 32),
                Expanded(child: _buildContent(context)),
                _buildHint(),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WORD ${index + 1} / $total',
              style: GoogleFonts.dmSans(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _difficultyColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _difficultyColor.withOpacity(0.3)),
              ),
              child: Text(
                word.difficulty.toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: _difficultyColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
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

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The word
        Text(
          word.word,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 52,
            fontWeight: FontWeight.w700,
            letterSpacing: -2,
            height: 1,
          ),
        ).animate().fadeIn(delay: 80.ms).slideX(begin: -0.02),
        const SizedBox(height: 6),
        // Phonetic + part-of-speech
        Row(
          children: [
            if (word.phonetic != null) ...[Text(word.phonetic!, style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 13, fontStyle: FontStyle.italic)),const SizedBox(width: 10)],
            if (word.partOfSpeech != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.wordGlow, borderRadius: BorderRadius.circular(8)), child: Text(word.partOfSpeech!, style: GoogleFonts.dmSans(color: AppColors.wordAccent, fontSize: 11, fontWeight: FontWeight.w600))),
          ],
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),

        // Divider accent
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.wordAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate().scaleX(begin: 0, alignment: Alignment.centerLeft, delay: 150.ms),

        const SizedBox(height: 28),

        // Meaning
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEANING',
                style: GoogleFonts.dmSans(
                  color: AppColors.wordAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                word.meaning,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.03),

        const SizedBox(height: 16),

        // Example
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXAMPLE',
                style: GoogleFonts.dmSans(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '"${word.example}"',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.03),
      ],
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          Text(
            index < total - 1 ? 'Swipe up or tap for next' : 'Swipe up to start quiz',
            style: GoogleFonts.dmSans(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
