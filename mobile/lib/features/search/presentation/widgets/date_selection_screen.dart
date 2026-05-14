import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flightly/core/theme/app_colors.dart';
import 'package:flightly/core/theme/app_text_styles.dart';
import 'package:flightly/features/search/domain/models/search_query.dart';
import 'package:flightly/features/search/domain/providers/search_form_provider.dart';

class DateSelectionScreen extends ConsumerStatefulWidget {
  const DateSelectionScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DateSelectionScreen(),
    );
  }

  @override
  ConsumerState<DateSelectionScreen> createState() => _DateSelectionScreenState();
}

class _DateSelectionScreenState extends ConsumerState<DateSelectionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchFormProvider);
    _selectedStart = query.departureDate;
    _selectedEnd = query.returnDate;
    if (_selectedStart != null) {
      _focusedDay = _selectedStart!;
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final query = ref.read(searchFormProvider);
    setState(() {
      _focusedDay = focusedDay;

      if (query.tripType == TripType.oneWay) {
        _selectedStart = selectedDay;
        _selectedEnd = null;
      } else {
        if (_selectedStart == null) {
          _selectedStart = selectedDay;
        } else if (_selectedEnd == null) {
          if (selectedDay.isBefore(_selectedStart!)) {
            _selectedEnd = _selectedStart;
            _selectedStart = selectedDay;
          } else {
            _selectedEnd = selectedDay;
          }
        } else {
          _selectedStart = selectedDay;
          _selectedEnd = null;
        }
      }
    });
  }

  void _applyDates() {
    final query = ref.read(searchFormProvider);
    ref.read(searchFormProvider.notifier).updateQuery(
      query.copyWith(
        departureDate: _selectedStart,
        returnDate: _selectedEnd,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchFormProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  query.tripType == TripType.oneWay ? 'Select Departure' : 'Select Dates',
                  style: AppTextStyles.headingLarge,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedStart, day) || isSameDay(_selectedEnd, day),
                  rangeStartDay: _selectedStart,
                  rangeEndDay: _selectedEnd,
                  calendarFormat: CalendarFormat.month,
                  rangeSelectionMode: query.tripType == TripType.roundTrip ? RangeSelectionMode.enforced : RangeSelectionMode.disabled,
                  onDaySelected: (selectedDay, focusedDay) => _onDaySelected(selectedDay, focusedDay),
                  onRangeSelected: (start, end, focusedDay) {
                    setState(() {
                      _selectedStart = start;
                      _selectedEnd = end;
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: AppTextStyles.headingMedium,
                    leftChevronIcon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
                    rightChevronIcon: const Icon(LucideIcons.chevronRight, color: AppColors.textPrimary),
                  ),
                  calendarStyle: CalendarStyle(
                    // ── Day number typography ──────────────────────────────
                    // Darker, bolder default so every date reads clearly
                    defaultTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF1A2340), // near-navy, not harsh black
                      fontWeight: FontWeight.w600,
                    ),
                    weekendTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                    ),
                    // Disabled / past dates — clearly muted
                    disabledTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFFBEC8D8),
                      fontWeight: FontWeight.w400,
                    ),
                    // Outside-month days hidden
                    outsideDaysVisible: false,

                    // ── Today — clean ring, no fill ────────────────────────
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.8),
                    ),
                    todayTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),

                    // ── Selected single day ────────────────────────────────
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),

                    // ── Range endpoints ────────────────────────────────────
                    rangeStartDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeStartTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    rangeEndDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    rangeEndTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),

                    // ── Range fill between endpoints ───────────────────────
                    rangeHighlightColor: AppColors.primary.withValues(alpha: 0.12),

                    // ── Within-range days ──────────────────────────────────
                    withinRangeTextStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    withinRangeDecoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                    ),

                    // ── Cell margin (breathing room between days) ──────────
                    cellMargin: const EdgeInsets.all(4),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: (_selectedStart != null && (query.tripType == TripType.oneWay || _selectedEnd != null))
                  ? _applyDates
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surface,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Apply Dates', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
