import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _wordCount;
  late int _quizCount;
  late String _newsTopic;

  final List<Map<String, String>> _topics = [
    {'value': 'all',          'label': 'All Topics',   'emoji': '🌍'},
    {'value': 'technology',   'label': 'Technology',   'emoji': '💻'},
    {'value': 'business',     'label': 'Business',     'emoji': '📈'},
    {'value': 'science',      'label': 'Science',      'emoji': '🔬'},
    {'value': 'health',       'label': 'Health',       'emoji': '🏥'},
    {'value': 'sports',       'label': 'Sports',       'emoji': '⚽'},
    {'value': 'entertainment','label': 'Entertainment','emoji': '🎬'},
    {'value': 'politics',     'label': 'Politics',     'emoji': '🏛️'},
  ];

  @override
  void initState() {
    super.initState();
    final s = StorageService.instance;
    _wordCount  = s.getWordCount();
    _quizCount  = s.getQuizCount();
    _newsTopic  = s.getNewsTopic();
  }

  Future<void> _save() async {
    final s = StorageService.instance;
    await s.setWordCount(_wordCount);
    await s.setQuizCount(_quizCount);
    await s.setNewsTopic(_newsTopic);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved', style: GoogleFonts.dmSans(color: AppColors.background)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSans(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.dmSans(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        children: [
          _buildSection(
            label: 'WORD SPRINT',
            color: AppColors.wordAccent,
            children: [
              _buildSliderTile(
                title: 'Words per session',
                subtitle: 'How many words to learn each day',
                value: _wordCount.toDouble(),
                min: 5,
                max: 20,
                divisions: 15,
                color: AppColors.wordAccent,
                onChanged: (v) => setState(() {
                    _wordCount = v.round();
                    if (_quizCount > _wordCount) {
                        _quizCount = _wordCount;
                    }
                }),
              ),
              const SizedBox(height: 4),
              _buildSliderTile(
                title: 'Quiz questions',
                subtitle: 'Must be ≤ words per session',
                value: _quizCount.toDouble(),
                min: 3,
                max: _wordCount.toDouble(),
                divisions: _wordCount - 3,
                color: AppColors.wordAccent,
                onChanged: (v) => setState(() => _quizCount = v.round()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            label: 'NEWS SPRINT',
            color: AppColors.newsAccent,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'News topic',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Choose the category of news you want to see',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _topics.map((t) {
                  final selected = _newsTopic == t['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _newsTopic = t['value']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.newsAccent.withOpacity(0.15)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.newsAccent
                              : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t['emoji']!, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 7),
                          Text(
                            t['label']!,
                            style: GoogleFonts.dmSans(
                              color: selected
                                  ? AppColors.newsAccent
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String label,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03);
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value.round().toString(),
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: AppColors.border,
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : 1,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}