import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../window_manager.dart';

/// A real, live, navigable month calendar (correct day-of-week alignment,
/// today highlighted) paired with a static list of consulting "services" —
/// styled after booking-calendar apps. There's no scheduling backend behind
/// this: picking a date and a service just drafts a message and jumps to
/// the real Contact window/form, so nothing here claims to auto-confirm a
/// booking that doesn't exist.
class CalendarWindowContent extends ConsumerStatefulWidget {
  final Size desktopSize;
  const CalendarWindowContent({super.key, required this.desktopSize});

  @override
  ConsumerState<CalendarWindowContent> createState() => _CalendarWindowContentState();
}

class _Service {
  final String name;
  final String duration;
  const _Service(this.name, this.duration);
}

const _services = [
  _Service('Intro Call', '15m'),
  _Service('UI/UX Feedback', '30m'),
  _Service('Tech Consult', '45m'),
  _Service('Project Scope', '30m'),
];

const _weekdayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
final _monthFormat = DateFormat('MMMM');
final _dateFormat = DateFormat('d MMM yyyy');

class _CalendarWindowContentState extends ConsumerState<CalendarWindowContent> {
  late DateTime _viewedMonth;
  DateTime? _selectedDate;
  int _selectedService = 2; // "Tech Consult" pre-selected, like the reference layout.

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewedMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewedMonth.year == now.year && _viewedMonth.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _viewedMonth = DateTime(_viewedMonth.year, _viewedMonth.month + delta);
      _selectedDate = null;
    });
  }

  void _requestSlot() {
    final date = _selectedDate;
    if (date == null) return;
    final service = _services[_selectedService];
    ref.read(contactPrefillProvider.notifier).set(
          "Hi, I'd like to request a ${service.name} (${service.duration}) on "
          '${_dateFormat.format(date)}. Let me know if that works for you.',
        );
    ref.read(windowManagerProvider.notifier).openWindow('contact', desktopSize: widget.desktopSize);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth > 460;
        final calendar = _MonthCalendar(
          viewedMonth: _viewedMonth,
          selectedDate: _selectedDate,
          canGoBack: !_isCurrentMonth,
          onPrevMonth: () => _changeMonth(-1),
          onNextMonth: () => _changeMonth(1),
          onSelectDate: (d) => setState(() => _selectedDate = d),
        );

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSidebar)
                    _ServicesSidebar(
                      selectedIndex: _selectedService,
                      onSelect: (i) => setState(() => _selectedService = i),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!showSidebar) ...[
                            _ServiceChipsRow(
                              selectedIndex: _selectedService,
                              onSelect: (i) => setState(() => _selectedService = i),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Expanded(child: calendar),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDate != null) _RequestBar(
              service: _services[_selectedService],
              date: _selectedDate!,
              onRequest: _requestSlot,
            ),
          ],
        );
      },
    );
  }
}

class _ServicesSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _ServicesSidebar({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'SERVICES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _services.length; i++)
            _ServiceTile(service: _services[i], isSelected: i == selectedIndex, onTap: () => onSelect(i)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatefulWidget {
  final _Service service;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceTile({required this.service, required this.isSelected, required this.onTap});

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.glassFill : (_hovering ? AppColors.glassFill.withValues(alpha: 0.5) : null),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accentEnd : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(widget.service.duration, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal fallback for narrow window widths where a sidebar wouldn't fit.
class _ServiceChipsRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _ServiceChipsRow({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _services.length; i++) ...[
            _ServiceChip(service: _services[i], isSelected: i == selectedIndex, onTap: () => onSelect(i)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final _Service service;
  final bool isSelected;
  final VoidCallback onTap;
  const _ServiceChip({required this.service, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Text(
            '${service.name} · ${service.duration}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime viewedMonth;
  final DateTime? selectedDate;
  final bool canGoBack;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthCalendar({
    required this.viewedMonth,
    required this.selectedDate,
    required this.canGoBack,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(viewedMonth.year, viewedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(viewedMonth.year, viewedMonth.month, 1).weekday; // 1=Mon..7=Sun
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final cellCount = (totalCells / 7).ceil() * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calendar',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.6),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${_monthFormat.format(viewedMonth)} ${viewedMonth.year}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            _MonthNav(canGoBack: canGoBack, onPrev: onPrevMonth, onNext: onNextMonth),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(height: 1, color: AppColors.glassBorder),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: cellCount,
            itemBuilder: (context, i) {
              final dayNumber = i - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox.shrink();
              final date = DateTime(viewedMonth.year, viewedMonth.month, dayNumber);
              final isToday = date == today;
              final isSelected = selectedDate != null && date == selectedDate;
              final isPast = date.isBefore(today);

              return _DayCell(
                day: dayNumber,
                isToday: isToday,
                isSelected: isSelected,
                isPast: isPast,
                onTap: isPast ? null : () => onSelectDate(date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthNav extends StatelessWidget {
  final bool canGoBack;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthNav({required this.canGoBack, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: canGoBack ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: canGoBack ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          Container(width: 1, height: 16, color: AppColors.glassBorder),
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Gradient? gradient;
    Color textColor = AppColors.textPrimary;
    Border? border;

    if (widget.isToday) {
      gradient = AppColors.accentGradient;
      textColor = Colors.white;
    } else if (widget.isSelected) {
      border = Border.all(color: AppColors.accentEnd, width: 1.5);
      textColor = AppColors.accentEnd;
    } else if (widget.isPast) {
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
    } else if (_hovering) {
      bg = AppColors.glassFill;
    }

    return MouseRegion(
      cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, gradient: gradient, border: border, shape: BoxShape.circle),
            child: Text(
              '${widget.day}',
              style: TextStyle(fontSize: 13, fontWeight: widget.isToday ? FontWeight.bold : FontWeight.w500, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestBar extends StatelessWidget {
  final _Service service;
  final DateTime date;
  final VoidCallback onRequest;
  const _RequestBar({required this.service, required this.date, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${service.name} (${service.duration}) · ${_dateFormat.format(date)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onRequest,
            child: const Text('Request via Contact'),
          ),
        ],
      ),
    );
  }
}
