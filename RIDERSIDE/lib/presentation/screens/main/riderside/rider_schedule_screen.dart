import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_schedule_provider.dart';

class RiderScheduleScreen extends ConsumerWidget {
  const RiderScheduleScreen({super.key});

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riderScheduleProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'Scheduled Availability',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5F2D82),
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Schedule',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
      ),
      body: state.entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 64, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'No schedules yet',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your availability',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(hp, 16, hp, 80),
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return Card(
                  margin: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 10),
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: entry.isEnabled
                          ? const Color(0xFF5F2D82).withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                      child: Text(
                        _dayNames[entry.dayOfWeek - 1],
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: entry.isEnabled
                              ? const Color(0xFF5F2D82)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      '${entry.startTime} - ${entry.endTime}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: entry.isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      entry.isEnabled ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color:
                            entry.isEnabled ? Colors.green : Colors.grey.shade500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: entry.isEnabled,
                          activeColor: const Color(0xFF5F2D82),
                          onChanged: (_) =>
                              ref.read(riderScheduleProvider.notifier).toggleEntry(index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () =>
                              ref.read(riderScheduleProvider.notifier).removeEntry(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    int selectedDay = 1;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Add Schedule',
            style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedDay,
                decoration:
                    const InputDecoration(labelText: 'Day of Week'),
                items: List.generate(
                  7,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(
                      _dayNames[i],
                      style: const TextStyle(fontFamily: 'TT Fors'),
                    ),
                  ),
                ),
                onChanged: (v) => setDialogState(() => selectedDay = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'Start Time',
                  style: TextStyle(fontFamily: 'TT Fors'),
                ),
                trailing: Text(
                  startTime.format(context),
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (picked != null) {
                    setDialogState(() => startTime = picked);
                  }
                },
              ),
              ListTile(
                title: const Text(
                  'End Time',
                  style: TextStyle(fontFamily: 'TT Fors'),
                ),
                trailing: Text(
                  endTime.format(context),
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (picked != null) {
                    setDialogState(() => endTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              onPressed: () {
                ref.read(riderScheduleProvider.notifier).addEntry(
                      RiderScheduleEntry(
                        dayOfWeek: selectedDay,
                        startTime: startTime.format(context),
                        endTime: endTime.format(context),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
