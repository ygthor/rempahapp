import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class DateRangeComponent extends StatefulWidget {
  final Function(DateTimeRange?)
  onDateRangeChanged; // Callback to notify parent of date changes

  const DateRangeComponent({Key? key, required this.onDateRangeChanged})
    : super(key: key);

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
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // _updateDataBasedOnFilter(); // Initialize with default filter
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialDateRange =
        _selectedDateRange ??
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
      setState(() {
        _selectedDateRange = newDateRange;
        // If a custom range is picked, ensure the dropdown reflects "Custom Range"
        // This is important if _pickDateRange is called programmatically
        _selectedFilterOption = 'Custom Range';
      });
      widget.onDateRangeChanged(_selectedDateRange);
    }
  }

  void _updateDataBasedOnFilter() {
    final now = DateTime.now();
    DateTimeRange? newRange;

    switch (_selectedFilterOption) {
      case 'Last 7 Days':
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 6)), // Inclusive of today
          end: now,
        );
        break;
      case 'Last 30 Days':
        newRange = DateTimeRange(
          start: now.subtract(const Duration(days: 29)), // Inclusive of today
          end: now,
        );
        break;
      case 'This Month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end:
              now, // Could also be end of month: DateTime(now.year, now.month + 1, 0).subtract(Duration(microseconds: 1))
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
          end: lastDayOfLastMonth,
        );
        break;
      case 'Custom Range':
        // If it's already custom range, we don't override _selectedDateRange here.
        // _selectedDateRange is set by _pickDateRange.
        // If _selectedDateRange is null, it means the user hasn't picked yet.
        newRange = _selectedDateRange;
        break;
      default:
        newRange = null;
    }

    setState(() {
      if (_selectedFilterOption != 'Custom Range') {
        _selectedDateRange =
            newRange; // Update _selectedDateRange for predefined filters
      }
    });

    // Notify parent widget about the change
    widget.onDateRangeChanged(
      newRange,
    ); // Pass the calculated or selected range
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    setState(() {
                      _selectedFilterOption = newValue;
                      if (_selectedFilterOption != 'Custom Range') {
                        _selectedDateRange =
                            null; // Clear custom range if a predefined one is selected
                        _updateDataBasedOnFilter();
                      } else {
                        // If "Custom Range" is selected and no range is set yet, open picker.
                        // If a range IS set, _updateDataBasedOnFilter will use it.
                        _updateDataBasedOnFilter(); // This will pass the current _selectedDateRange (if any)
                        if (_selectedDateRange == null) {
                          _pickDateRange();
                        }
                      }
                    });
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
                    _selectedDateRange == null
                        ? 'Select Dates'
                        : '${DateFormat.yMd().format(_selectedDateRange!.start)}\n${DateFormat.yMd().format(_selectedDateRange!.end)}',
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
