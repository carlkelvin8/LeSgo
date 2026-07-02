import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/responsive_utils.dart';

enum ScheduleType { now, scheduled }

class OrderScheduleSelector extends StatefulWidget {
  final DateTime? scheduledTime;
  final Function(DateTime?) onScheduleChanged;

  const OrderScheduleSelector({
    super.key,
    this.scheduledTime,
    required this.onScheduleChanged,
  });

  @override
  State<OrderScheduleSelector> createState() => _OrderScheduleSelectorState();
}

class _OrderScheduleSelectorState extends State<OrderScheduleSelector> {
  late ScheduleType _selectedSchedule;
  DateTime? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _selectedSchedule = widget.scheduledTime == null ? ScheduleType.now : ScheduleType.scheduled;
    _scheduledTime = widget.scheduledTime;
  }

  Future<void> _pickScheduledTime() async {
    // Pick date first
    final now = DateTime.now();
    final firstDate = now.add(const Duration(hours: 1)); // At least 1 hour from now
    final lastDate = now.add(const Duration(days: 7)); // Up to 7 days ahead

    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F2D82),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    // Pick time
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledTime != null
          ? TimeOfDay.fromDateTime(_scheduledTime!)
          : const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F2D82),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    // Combine date + time
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Validate: must be at least 1 hour from now
    if (scheduledDateTime.isBefore(now.add(const Duration(hours: 1)))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled time must be at least 1 hour from now'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _scheduledTime = scheduledDateTime;
    });

    widget.onScheduleChanged(_scheduledTime);
  }

  void _clearScheduledTime() {
    setState(() {
      _scheduledTime = null;
      _selectedSchedule = ScheduleType.now;
    });
    widget.onScheduleChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: const Color(0xFF5F2D82),
                  size: ResponsiveUtils.fontSize(context, 20),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'Delivery Schedule',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Order Now option
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSchedule = ScheduleType.now;
                  _clearScheduledTime();
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedSchedule == ScheduleType.now
                        ? const Color(0xFF5F2D82)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedSchedule == ScheduleType.now
                      ? const Color(0xFF5F2D82).withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSchedule == ScheduleType.now
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedSchedule == ScheduleType.now
                          ? const Color(0xFF5F2D82)
                          : Colors.grey[400],
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Now',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            'Deliver as soon as possible',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Schedule for Later option
            InkWell(
              onTap: () {
                setState(() {
                  _selectedSchedule = ScheduleType.scheduled;
                });
                if (_scheduledTime == null) {
                  _pickScheduledTime();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedSchedule == ScheduleType.scheduled
                        ? const Color(0xFF5F2D82)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedSchedule == ScheduleType.scheduled
                      ? const Color(0xFF5F2D82).withOpacity(0.05)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedSchedule == ScheduleType.scheduled
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedSchedule == ScheduleType.scheduled
                          ? const Color(0xFF5F2D82)
                          : Colors.grey[400],
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule for Later',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            'Choose date and time',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Show selected time if scheduled
            if (_selectedSchedule == ScheduleType.scheduled && _scheduledTime != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event,
                      color: Color(0xFF5F2D82),
                      size: 20,
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled Delivery Time',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy \'at\' h:mm a').format(_scheduledTime!),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5F2D82),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF5F2D82)),
                      onPressed: _pickScheduledTime,
                      tooltip: 'Change time',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
