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

  void _showEditSheet(BuildContext context) {
    if (_fact == null) return;
    if (_fact!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This fact is from local storage and cannot be edited.',
            style: GoogleFonts.dmSans(color: AppColors.background),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: _fact!.fact);
    String selectedCategory = _fact!.category;

    const categories = [
      'positions', 'history', 'science', 'sports', 'organisations',
      'schemes', 'dates', 'currency', 'indexes', 'discoverers',
      'geography', 'politics', 'authors', 'miscellaneous',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit GK Fact',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Text(
                'CATEGORY',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    dropdownColor: AppColors.surfaceElevated,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    items: categories.map((cat) {
                      final meta = _categoryMeta[cat] ?? _categoryMeta['miscellaneous']!;
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Row(
                          children: [
                            Text(
                              meta['emoji'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              meta['label'] as String,
                              style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fact text field
              Text(
                'FACT',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                maxLines: 6,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  hintText: 'Edit the fact...',
                  hintStyle: GoogleFonts.dmSans(color: AppColors.textTertiary),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SaveButton(
                      controller: controller,
                      fact: _fact!,
                      service: _service,
                      sheetContext: ctx,
                      selectedCategory: selectedCategory,
                      onSuccess: (updatedFact, updatedCategory) {
                        Navigator.pop(ctx);
                        setState(() {
                          _fact = GkFactModel(
                            id: _fact!.id,
                            category: updatedCategory,
                            fact: updatedFact,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fact updated successfully',
                              style: GoogleFonts.dmSans(color: AppColors.background),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      onError: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to update. Check your connection.',
                              style: GoogleFonts.dmSans(color: AppColors.background),
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
      onLongPress: () => _showEditSheet(context),       // mobile
      onSecondaryTap: () => _showEditSheet(context),    // desktop right-click
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

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_expanded)
                  Text(
                    'Tap to read more',
                    style: GoogleFonts.dmSans(
                      color: color.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  '✏️ Hold to edit',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.03);
  }
}

class _SaveButton extends StatefulWidget {
  final TextEditingController controller;
  final GkFactModel fact;
  final GkService service;
  final BuildContext sheetContext;
  final String selectedCategory;
  final void Function(String fact, String category) onSuccess;
  final VoidCallback onError;

  const _SaveButton({
    required this.controller,
    required this.fact,
    required this.service,
    required this.sheetContext,
    required this.selectedCategory,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saving = false;

  Future<void> _save() async {
    final updatedFact = widget.controller.text.trim();
    final updatedCategory = widget.selectedCategory;

    final factUnchanged = updatedFact == widget.fact.fact;
    final categoryUnchanged = updatedCategory == widget.fact.category;

    if (updatedFact.isEmpty || (factUnchanged && categoryUnchanged)) {
      Navigator.pop(widget.sheetContext);
      return;
    }

    setState(() => _saving = true);
    final success = await widget.service.updateFact(
      widget.fact.id!,
      updatedFact,
      updatedCategory,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        widget.onSuccess(updatedFact, updatedCategory);
      } else {
        widget.onError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black,
                  ),
                )
              : Text(
                  'Save',
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}