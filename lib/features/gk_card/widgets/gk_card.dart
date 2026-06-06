import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gk_fact_model.dart';
import '../services/gk_service.dart';
import '../../../core/theme/app_theme.dart';

class GkCard extends StatefulWidget {
  const GkCard({super.key});

  @override
  State<GkCard> createState() => _GkCardState();
}

class _GkCardState extends State<GkCard> {
  final _service = GkService();
  GkFactModel? _fact;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fact = await _service.getFactOfDay();
    if (mounted) {
      setState(() {
        _fact = fact;
        _loading = false;
      });
    }
  }

  // Category metadata
  static const _categoryMeta = {
    'positions':      {'emoji': '🏛️', 'label': 'Positions',      'color': Color(0xFF7B61FF)},
    'history':        {'emoji': '📜', 'label': 'History',         'color': Color(0xFFE8834A)},
    'science':        {'emoji': '🔬', 'label': 'Science',         'color': Color(0xFF34D399)},
    'sports':         {'emoji': '⚽', 'label': 'Sports',          'color': Color(0xFF60A5FA)},
    'organisations':  {'emoji': '🌐', 'label': 'Organisations',   'color': Color(0xFFA78BFA)},
    'schemes':        {'emoji': '📋', 'label': 'Schemes',         'color': Color(0xFFFBBF24)},
    'dates':          {'emoji': '📅', 'label': 'Dates',           'color': Color(0xFFF472B6)},
    'currency':       {'emoji': '💰', 'label': 'Currency',        'color': Color(0xFF4ADE80)},
    'indexes':        {'emoji': '📊', 'label': 'Indexes',         'color': Color(0xFF38BDF8)},
    'discoverers':    {'emoji': '💡', 'label': 'Discoverers',     'color': Color(0xFFFF8C42)},
    'geography':      {'emoji': '🗺️', 'label': 'Geography',       'color': Color(0xFF6EE7B7)},
    'politics':       {'emoji': '🗳️', 'label': 'Politics',        'color': Color(0xFFFCA5A5)},
    'authors':        {'emoji': '✍️', 'label': 'Authors',         'color': Color(0xFFE879F9)},
    'miscellaneous':  {'emoji': '🎲', 'label': 'Miscellaneous',   'color': Color(0xFFCBD5E1)},
  };

  Map<String, dynamic> get _meta =>
      (_categoryMeta[_fact?.category] ?? _categoryMeta['miscellaneous'])
          as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }

    if (_fact == null) return const SizedBox.shrink();

    final color = _meta['color'] as Color;
    final emoji = _meta['emoji'] as String;
    final label = _meta['label'] as String;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 7),
                Text(
                  'GK OF THE DAY',
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fact text
            Text(
              _fact!.fact,
              style: GoogleFonts.dmSans(
                color: _expanded
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),

            if (!_expanded) ...[
              const SizedBox(height: 6),
              Text(
                'Tap to read more',
                style: GoogleFonts.dmSans(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.03);
  }
}