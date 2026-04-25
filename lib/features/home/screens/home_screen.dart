import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';
import '../../word_sprint/screens/word_sprint_screen.dart';
import '../../word_sprint/services/word_sprint_provider.dart';
import '../../news_sprint/screens/news_sprint_screen.dart';
import '../../news_sprint/services/news_sprint_provider.dart';
import '../widgets/streak_calendar.dart';
import '../../settings/settings_screen.dart';
import '../../../core/utils/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _wordStats = {};
  Map<String, dynamic> _newsStats = {};
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final storage = StorageService.instance;
    setState(() {
      _wordStats = storage.getWordStats();
      _newsStats = storage.getNewsStats();
      _streak = storage.getStreak();
    });
    storage.recordOpenedToday().then((s) {
      if (mounted) setState(() => _streak = s);
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still up?';
    if (h < 12) return 'Good morning.';
    if (h < 17) return 'Good afternoon.';
    if (h < 21) return 'Good evening.';
    return 'Still up?';
  }

  String get _subGreeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'A late-night sprint counts too.';
    if (h < 12) return 'Start your day a little sharper.';
    if (h < 17) return 'A quick sprint keeps you sharp.';
    if (h < 21) return 'Wind down with something useful.';
    return 'Night owl energy. Let\'s go.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background glows
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.wordAccent.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 160,
            right: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.newsAccent.withOpacity(0.05),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(),
                  const SizedBox(height: 32),
                  _buildGreeting(),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(child: _WordSprintButton(onTap: _goToWordSprint, wordsLearned: (_wordStats['total_seen'] ?? 0) as int)),
                        const SizedBox(height: 14),
                        Expanded(child: _NewsSprintButton(onTap: _goToNewsSprint, articlesRead: (_newsStats['articles_read'] ?? 0) as int)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // Logo
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.wordAccent, AppColors.newsAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '⚡',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Sprint',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        GestureDetector(
        onTap: () => StreakCalendarSheet.show(context),
        child: 
            // Streak chip
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: _streak > 0
                    ? AppColors.warning.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                color: _streak > 0
                    ? AppColors.warning.withOpacity(0.35)
                    : AppColors.border,
                ),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                Text(
                    _streak > 0 ? '🔥' : '○',
                    style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 5),
                Text(
                    _streak > 0 ? 'Day $_streak' : 'Start',
                    style: GoogleFonts.dmSans(
                    color: _streak > 0 ? AppColors.warning : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    ),
                ),
                ],
            ),
        ),
        ),      
        const SizedBox(width: 12),
        // Settings button
        GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ).then((_) => _loadStats()),
        child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
            Icons.tune_rounded,
            color: AppColors.textSecondary,
            size: 18,
            ),
        ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            height: 1,
          ),
        ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.04),
        const SizedBox(height: 6),
        Text(
          _subGreeting,
          style: GoogleFonts.dmSans(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 140.ms),
      ],
    );
  }

  Widget _buildStatsRow() {
    final wordSessions = (_wordStats['sessions'] ?? 0) as int;
    final newsSessions = (_newsStats['sessions'] ?? 0) as int;
    final totalSessions = wordSessions + newsSessions;
    final wordsLearned = (_wordStats['total_seen'] ?? 0) as int;
    final wCorrect = (_wordStats['total_correct'] ?? 0) as int;
    final wSeen = (_wordStats['total_seen'] ?? 0) as int;
    final nCorrect = (_newsStats['total_correct'] ?? 0) as int;
    final nArticles = (_newsStats['articles_read'] ?? 0) as int;
    final totalAttempted = wSeen + nArticles;
    final accuracy = totalAttempted == 0
        ? '—'
        : '${((wCorrect + nCorrect) / totalAttempted * 100).round()}%';

    return Row(
      children: [
        _StatPill(value: wordsLearned.toString(), label: 'words', color: AppColors.wordAccent),
        const SizedBox(width: 8),
        _StatPill(value: totalSessions.toString(), label: 'sessions', color: AppColors.newsAccent),
        const SizedBox(width: 8),
        _StatPill(value: accuracy, label: 'accuracy', color: AppColors.success),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }

  void _goToWordSprint() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ChangeNotifierProvider(
          create: (_) => WordSprintProvider(),
          child: const WordSprintScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ).then((_) => _loadStats());
  }

  void _goToNewsSprint() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ChangeNotifierProvider(
          create: (_) => NewsSprintProvider(),
          child: const NewsSprintScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ).then((_) => _loadStats());
  }
}

// ── Word Sprint Button ────────────────────────────────────────────────────────

class _WordSprintButton extends StatefulWidget {
  final VoidCallback onTap;
  final int wordsLearned;
  const _WordSprintButton({required this.onTap, required this.wordsLearned});

  @override
  State<_WordSprintButton> createState() => _WordSprintButtonState();
}

class _WordSprintButtonState extends State<_WordSprintButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) { setState(() => _pressing = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.wordSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _pressing
                  ? AppColors.wordAccent.withOpacity(0.6)
                  : AppColors.wordAccent.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Large decorative letter
              Positioned(
                right: -8,
                bottom: -16,
                child: Text(
                  'Aa',
                  style: GoogleFonts.dmSans(
                    color: AppColors.wordAccent.withOpacity(0.06),
                    fontSize: 110,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.wordAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'WORD SPRINT',
                            style: GoogleFonts.dmSans(
                              color: AppColors.wordAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.wordAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.wordAccent,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Build your\nvocabulary',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.wordAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              widget.wordsLearned == 0
                                  ? '${StorageService.instance.getWordCount()} words · quiz'
                                  : '${widget.wordsLearned} words mastered',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }
}

// ── News Sprint Button ────────────────────────────────────────────────────────

class _NewsSprintButton extends StatefulWidget {
  final VoidCallback onTap;
  final int articlesRead;
  const _NewsSprintButton({required this.onTap, required this.articlesRead});

  @override
  State<_NewsSprintButton> createState() => _NewsSprintButtonState();
}

class _NewsSprintButtonState extends State<_NewsSprintButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) { setState(() => _pressing = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.newsSurface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _pressing
                  ? AppColors.newsAccent.withOpacity(0.6)
                  : AppColors.newsAccent.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Decorative background text
              Positioned(
                right: -4,
                bottom: -10,
                child: Text(
                  '📰',
                  style: TextStyle(
                    fontSize: 90,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.newsAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'NEWS SPRINT',
                            style: GoogleFonts.dmSans(
                              color: AppColors.newsAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.newsAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.newsAccent,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catch up on\nthe world',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.newsAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              widget.articlesRead == 0
                                  ? 'Top stories · AI quiz'
                                  : '${widget.articlesRead} articles read',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}