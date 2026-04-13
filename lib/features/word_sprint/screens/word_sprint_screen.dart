import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/word_sprint_provider.dart';
import '../widgets/word_card.dart';
import '../widgets/quiz_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

class WordSprintScreen extends StatefulWidget {
  const WordSprintScreen({super.key});

  @override
  State<WordSprintScreen> createState() => _WordSprintScreenState();
}

class _WordSprintScreenState extends State<WordSprintScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordSprintProvider>().startSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary),
            onPressed: _confirmExit,
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.wordAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'WORD SPRINT',
                style: GoogleFonts.dmSans(
                  color: AppColors.wordAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        body: Consumer<WordSprintProvider>(
          builder: (context, provider, _) {
            return switch (provider.state) {
              WordSprintState.loading => const _LoadingView(message: 'Preparing your session...'),
              WordSprintState.fetchingApi => _LoadingView(message: provider.loadingMessage, showApiNote: true),
              WordSprintState.words => WordCard(
                  word: provider.currentWord,
                  index: provider.currentWordIndex,
                  total: provider.sessionWords.length,
                  onNext: () {
                    HapticFeedback.lightImpact();
                    provider.nextWord();
                  },
                ),
              WordSprintState.quiz => QuizCard(
                  question: provider.currentQuestion,
                  index: provider.currentQuizIndex,
                  total: provider.totalQuestions,
                  selectedOption: provider.selectedOption,
                  revealed: provider.answerRevealed,
                  onSelect: (i) {
                    HapticFeedback.mediumImpact();
                    provider.selectAnswer(i);
                  },
                  onNext: () {
                    HapticFeedback.lightImpact();
                    provider.nextQuestion();
                  },
                ),
              WordSprintState.summary => _SummaryView(
                  wordsLearned: provider.sessionWords.length,
                  correct: provider.correctAnswers,
                  total: provider.totalQuestions,
                  onHome: () {
                    provider.reset();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  onRetry: () {
                    provider.startSession();
                  },
                ),
              WordSprintState.error => _ErrorView(
                  message: provider.errorMessage ?? 'Something went wrong',
                  onRetry: provider.startSession,
                ),
              _ => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Exit session?', style: GoogleFonts.dmSans(color: AppColors.textPrimary)),
        content: Text(
          'Your progress in this session will be lost.',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continue', style: GoogleFonts.dmSans(color: AppColors.wordAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WordSprintProvider>().reset();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: Text('Exit', style: GoogleFonts.dmSans(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  final bool showApiNote;
  const _LoadingView({this.message = 'Loading...', this.showApiNote = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.wordAccent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            if (showApiNote) ...[
              const SizedBox(height: 12),
              Text(
                'Pulling live definitions from dictionary API',
                style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.dmSans(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.wordAccent),
              onPressed: onRetry,
              child: Text('Retry', style: GoogleFonts.dmSans(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  final int wordsLearned;
  final int correct;
  final int total;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const _SummaryView({
    required this.wordsLearned,
    required this.correct,
    required this.total,
    required this.onHome,
    required this.onRetry,
  });

  String get _emoji {
    final pct = total == 0 ? 0 : correct / total;
    if (pct >= 0.8) return '🔥';
    if (pct >= 0.5) return '💪';
    return '📚';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = total == 0 ? 0.0 : correct / total;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(_emoji, style: const TextStyle(fontSize: 56))
                .animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'Session\nComplete',
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -1.5,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const SizedBox(height: 40),
            Row(
              children: [
                _StatBox(
                  label: 'Words',
                  value: wordsLearned.toString(),
                  sub: 'learned',
                  color: AppColors.wordAccent,
                ),
                const SizedBox(width: 16),
                _StatBox(
                  label: 'Accuracy',
                  value: '${(accuracy * 100).round()}%',
                  sub: '$correct / $total correct',
                  color: accuracy >= 0.7 ? AppColors.success : AppColors.warning,
                ),
              ],
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
            const Spacer(),
            _ActionButton(
              label: 'Back to Home',
              onTap: onHome,
              primary: true,
              color: AppColors.wordAccent,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
            const SizedBox(height: 12),
            _ActionButton(
              label: 'New Session',
              onTap: onRetry,
              primary: false,
              color: AppColors.wordAccent,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.05),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.dmSans(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.primary,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: primary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary ? color : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: primary ? Colors.black : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
