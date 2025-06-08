import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class DateRangeComponent extends StatefulWidget {
  final Function(DateTimeRange?)
  onDateRangeChanged; // Callback to notify parent of date changes

  final DateTimeRange? currentValue;

  const DateRangeComponent({
    Key? key,
    required this.onDateRangeChanged,
    this.currentValue,
  }) : super(key: key);

  @override
  _DateRangeComponentState createState() => _DateRangeComponentState();
}

class _DateRangeComponentState extends State<DateRangeComponent> {
  String _selectedFilterOption = 'Last 7 Days'; // Default filter option
  final List<String> _filterOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Custom Range',
  ];

  @override
  void initState() {
    super.initState();
    // _updateDataBasedOnFilter(); // Initialize with default filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = widget.currentValue;

    if (current != null) {
      final start = DateTime(
        current.start.year,
        current.start.month,
        current.start.day,
      );
      final end = DateTime(
        current.end.year,
        current.end.month,
        current.end.day,
      );

      if (start == today.subtract(const Duration(days: 6)) && end == today) {
        _selectedFilterOption = 'Last 7 Days';
      } else if (start == today.subtract(const Duration(days: 29)) &&
          end == today) {
        _selectedFilterOption = 'Last 30 Days';
      } else if (start == DateTime(today.year, today.month, 1) &&
          end == today) {
        _selectedFilterOption = 'This Month';
      } else {
        final firstDayOfCurrentMonth = DateTime(today.year, today.month, 1);
        final lastDayOfLastMonth = firstDayOfCurrentMonth.subtract(
          const Duration(days: 1),
        );
        final firstDayOfLastMonth = DateTime(
          lastDayOfLastMonth.year,
          lastDayOfLastMonth.month,
          1,
        );
        if (start == firstDayOfLastMonth && end == lastDayOfLastMonth) {
          _selectedFilterOption = 'Last Month';
        } else {
          _selectedFilterOption = 'Custom Range';
        }
      }
    } else {
      _selectedFilterOption = 'Last 7 Days'; // default
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialDateRange =
        widget.currentValue ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        // Optional: Theme the picker
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary:
                  Theme.of(
                    context,
                  ).colorScheme.primary, // Use your app's primary color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      print("newDateRange:" + newDateRange.toString());
      widget.onDateRangeChanged(newDateRange);
    }
  }

  void _updateDataBasedOnFilter(String filterValue) async {
    final now = DateTime.now();
    DateTimeRange? newRange;

    DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

    switch (filterValue) {
      case 'Last 7 Days':
        newRange = DateTimeRange(
          start: dateOnly(now.subtract(const Duration(days: 6))),
          end: dateOnly(now),
        );
        break;
      case 'Last 30 Days':
        newRange = DateTimeRange(
          start: dateOnly(now.subtract(const Duration(days: 29))),
          end: dateOnly(now),
        );
        break;
      case 'This Month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: dateOnly(now),
        );
        break;
      case 'Last Month':
        final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
        final lastDayOfLastMonth = firstDayOfCurrentMonth.subtract(
          const Duration(days: 1),
        );
        final firstDayOfLastMonth = DateTime(
          lastDayOfLastMonth.year,
          lastDayOfLastMonth.month,
          1,
        );
        newRange = DateTimeRange(
          start: firstDayOfLastMonth,
          end: dateOnly(lastDayOfLastMonth),
        );
        break;
      case 'Custom Range':
        await _pickDateRange();
        return; // Exit early since _pickDateRange will handle callback
      default:
        newRange = null;
    }

    if (newRange != null) {
      widget.onDateRangeChanged(newRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(widget.currentValue.toString()),
        // ----- ADDED FILTERS -----
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items vertically
          children: [
            Expanded(
              flex:
                  _selectedFilterOption == 'Custom Range'
                      ? 2
                      : 3, // Adjust flex based on visibility of button
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Filter Period',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                ),
                value: _selectedFilterOption,
                items:
                    _filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateDataBasedOnFilter(newValue);
                  }
                },
              ),
            ),
            if (_selectedFilterOption == 'Custom Range') ...[
              const SizedBox(width: 10),
              Expanded(
                // Make button take remaining space or a defined flex
                flex: 3,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    widget.currentValue == null
                        ? 'Select Dates'
                        : '${DateFormat.yMd().format(widget.currentValue!.start)}\n${DateFormat.yMd().format(widget.currentValue!.end)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis, // Handle long dates
                    maxLines: 2,
                  ),
                  onPressed: _pickDateRange,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10.0,
                    ), // Adjusted padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    minimumSize: Size(
                      0,
                      50,
                    ), // Ensure button height matches dropdown
                  ),
                ),
              ),
            ],
          ],
        ),
        // ----- END OF ADDED FILTERS -----
      ],
    );
  }
}
