import 'package:flutter/material.dart';
import '../../../data/data_source/dto/tracking/tracking_dto.dart';
import 'package:intl/intl.dart';

class OrderStatusTimeline extends StatelessWidget {
  final TrackingDto tracking;

  const OrderStatusTimeline({
    Key? key,
    required this.tracking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = _getTimelineEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...events.map((event) => _buildTimelineItem(
              context,
              event,
              isLast: event == events.last,
            )),
      ],
    );
  }

  List<TimelineEvent> _getTimelineEvents() {
    final events = <TimelineEvent>[];

    // Order created
    events.add(TimelineEvent(
      title: 'Order Placed',
      subtitle: 'Your order has been placed',
      time: tracking.createdAt,
      icon: Icons.shopping_cart,
      isCompleted: true,
    ));

    // Driver assigned
    if (tracking.driver != null) {
      events.add(TimelineEvent(
        title: 'Driver Assigned',
        subtitle: 'Driver ${tracking.driver!.name} accepted your order',
        time: tracking.acceptedAt,
        icon: Icons.person,
        isCompleted: tracking.acceptedAt != null,
      ));
    }

    // Picked up
    if (tracking.status == 'picked_up' ||
        tracking.status == 'in_transit' ||
        tracking.status == 'completed') {
      events.add(TimelineEvent(
        title: 'Order Picked Up',
        subtitle: 'Driver picked up your order',
        time: tracking.pickedUpAt,
        icon: Icons.shopping_bag,
        isCompleted: tracking.pickedUpAt != null,
      ));
    }

    // In transit
    if (tracking.status == 'in_transit' || tracking.status == 'completed') {
      events.add(TimelineEvent(
        title: 'On The Way',
        subtitle: 'Driver is heading to your location',
        time: tracking.inTransitAt,
        icon: Icons.local_shipping,
        isCompleted: tracking.inTransitAt != null,
      ));
    }

    // Completed
    if (tracking.status == 'completed') {
      events.add(TimelineEvent(
        title: 'Delivered',
        subtitle: 'Order has been delivered',
        time: tracking.completedAt,
        icon: Icons.done_all,
        isCompleted: tracking.completedAt != null,
      ));
    }

    // Cancelled
    if (tracking.status == 'cancelled') {
      events.add(TimelineEvent(
        title: 'Cancelled',
        subtitle: 'Order was cancelled',
        time: tracking.cancelledAt,
        icon: Icons.cancel,
        isCompleted: true,
        isError: true,
      ));
    }

    return events;
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event, {
    required bool isLast,
  }) {
    final color = event.isError
        ? Colors.red
        : event.isCompleted
            ? Colors.green
            : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.isCompleted
                    ? color.withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                event.icon,
                size: 20,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: event.isCompleted ? color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Event details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: event.isCompleted ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (event.time != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatTime(event.time!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(dateTime);
      }
    } catch (e) {
      return timestamp;
    }
  }
}

class TimelineEvent {
  final String title;
  final String subtitle;
  final String? time;
  final IconData icon;
  final bool isCompleted;
  final bool isError;

  TimelineEvent({
    required this.title,
    required this.subtitle,
    this.time,
    required this.icon,
    this.isCompleted = false,
    this.isError = false,
  });
}

