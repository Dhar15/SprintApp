import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/news_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final int index;
  final int total;
  final VoidCallback onNext;

  const NewsCard({
    super.key,
    required this.article,
    required this.index,
    required this.total,
    required this.onNext,
  });

  Color get _categoryColor {
    switch (article.category) {
      case 'technology': return const Color(0xFF7B61FF);
      case 'environment': return const Color(0xFF00E5A0);
      case 'business': return const Color(0xFFFFB547);
      case 'health': return const Color(0xFFFF6B9D);
      case 'science': return const Color(0xFF00C4FF);
      default: return AppColors.newsAccent;
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
                const SizedBox(height: 24),
                Expanded(child: _buildContent()),
                _buildHint(),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04);
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STORY ${index + 1} / $total',
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
                color: _categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _categoryColor.withOpacity(0.3)),
              ),
              child: Text(
                article.category.toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: _categoryColor,
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
            valueColor: AlwaysStoppedAnimation<Color>(_categoryColor),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final timeAgo = _getTimeAgo(article.publishedAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Source + time
        Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _categoryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              article.source,
              style: GoogleFonts.dmSans(
                color: _categoryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '· $timeAgo',
              style: GoogleFonts.dmSans(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 60.ms),
        const SizedBox(height: 20),

        // Headline
        Text(
          article.title,
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(delay: 90.ms).slideY(begin: 0.03),

        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: _categoryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ).animate().scaleX(begin: 0, alignment: Alignment.centerLeft, delay: 160.ms),

        const SizedBox(height: 28),

        // Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.article_outlined, size: 14, color: _categoryColor),
                  const SizedBox(width: 6),
                  Text(
                    '60-SECOND READ',
                    style: GoogleFonts.dmSans(
                      color: _categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.summary,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.65,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.03),

        // Read More
        if (article.originalUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(article.originalUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  Text(
                    'Read full story',
                    style: GoogleFonts.dmSans(
                      color: _categoryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: _categoryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new_rounded, size: 13, color: _categoryColor),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.textTertiary, size: 20),
          Text(
            index < total - 1 ? 'Swipe up for next story' : 'Swipe up to start quiz',
            style: GoogleFonts.dmSans(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
