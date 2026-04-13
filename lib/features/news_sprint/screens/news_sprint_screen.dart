import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/news_sprint_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_quiz_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

class NewsSprintScreen extends StatefulWidget {
  const NewsSprintScreen({super.key});

  @override
  State<NewsSprintScreen> createState() => _NewsSprintScreenState();
}

class _NewsSprintScreenState extends State<NewsSprintScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsSprintProvider>().startSession();
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
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.newsAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEWS SPRINT',
                style: GoogleFonts.dmSans(
                  color: AppColors.newsAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          actions: [
            Consumer<NewsSprintProvider>(
              builder: (_, p, __) => p.usingFallback
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Tooltip(
                        message: 'Using cached stories (offline)',
                        child: Icon(Icons.wifi_off_rounded, color: AppColors.textTertiary, size: 16),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        body: Consumer<NewsSprintProvider>(
          builder: (context, provider, _) {
            return switch (provider.state) {
              NewsSprintState.loading => const _LoadingView(),
              NewsSprintState.articles => NewsCard(
                  article: provider.currentArticle,
                  index: provider.currentArticleIndex,
                  total: provider.articles.length,
                  onNext: () {
                    HapticFeedback.lightImpact();
                    provider.nextArticle();
                  },
                ),
              NewsSprintState.quiz => provider.quizQuestions.isEmpty
                  ? const _QuizLoadingView()
                  : NewsQuizCard(
                    question: provider.currentQuestion,
                    index: provider.currentQuizIndex,
                    total: provider.totalQuestions,
                    explanation: provider.currentQuestion.explanation,
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
              NewsSprintState.summary => _NewsSummaryView(
                  articlesRead: provider.articles.length,
                  correct: provider.correctAnswers,
                  total: provider.totalQuestions,
                  onHome: () {
                    provider.reset();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  onRetry: provider.startSession,
                ),
              NewsSprintState.error => _ErrorView(
                  message: provider.errorMessage ?? 'Failed to load news',
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
        content: Text('Your progress will be lost.', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continue', style: GoogleFonts.dmSans(color: AppColors.newsAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NewsSprintProvider>().reset();
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
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.newsAccent, strokeWidth: 2),
          const SizedBox(height: 20),
          Text('Fetching today\'s stories...', style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
        ],
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
            const Icon(Icons.cloud_off_rounded, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.dmSans(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.newsAccent),
              onPressed: onRetry,
              child: Text('Try Again', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSummaryView extends StatelessWidget {
  final int articlesRead;
  final int correct;
  final int total;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  const _NewsSummaryView({
    required this.articlesRead,
    required this.correct,
    required this.total,
    required this.onHome,
    required this.onRetry,
  });

  String get _emoji {
    final pct = total == 0 ? 0 : correct / total;
    if (pct >= 0.8) return '🎯';
    if (pct >= 0.5) return '📰';
    return '🤔';
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
              'All caught\nup!',
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
                _StatBox(label: 'Stories', value: articlesRead.toString(), sub: 'read today', color: AppColors.newsAccent),
                const SizedBox(width: 16),
                _StatBox(
                  label: 'Quiz',
                  value: '${(accuracy * 100).round()}%',
                  sub: '$correct / $total correct',
                  color: accuracy >= 0.7 ? AppColors.success : AppColors.warning,
                ),
              ],
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
            const Spacer(),
            _ActionButton(label: 'Back to Home', onTap: onHome, primary: true, color: AppColors.newsAccent)
                .animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
            const SizedBox(height: 12),
            _ActionButton(label: 'Refresh Stories', onTap: onRetry, primary: false, color: AppColors.newsAccent)
                .animate().fadeIn(delay: 600.ms).slideY(begin: 0.05),
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
  const _StatBox({required this.label, required this.value, required this.sub, required this.color});

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
            Text(label.toUpperCase(), style: GoogleFonts.dmSans(color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)),
            Text(sub, style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 12)),
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
  const _ActionButton({required this.label, required this.onTap, required this.primary, required this.color});

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
          border: Border.all(color: primary ? color : AppColors.border),
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.dmSans(
            color: primary ? Colors.black : AppColors.textSecondary,
            fontSize: 16, fontWeight: FontWeight.w600,
          )),
        ),
      ),
    );
  }
}

class _QuizLoadingView extends StatelessWidget {
  const _QuizLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.newsAccent, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'Generating quiz questions...',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is reading the articles',
            style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
