# 📱 Push Notifications - Flow Diagram

## 🔄 Complete Notification Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER CREATES ORDER                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DRIVER FINDING SCREEN                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DriverFindingProvider.startFindingDriver()              │  │
│  │  • Searches for available driver                         │  │
│  │  • Simulates 3-second search                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Driver Found!  │
                    └────────┬───────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🔔 NOTIFICATION #1                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NotificationHelper.showDriverAssigned()                 │  │
│  │  • Purple banner appears                                 │  │
│  │  • Shows driver name                                     │  │
│  │  • Auto-dismisses after 4 seconds                        │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ORDER TRACKING SCREEN                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  LiveTrackingProvider.startTracking()                    │  │
│  │  • Connects to WebSocket                                 │  │
│  │  • Subscribes to order channel                           │  │
│  │  • Listens for events                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEBSOCKET EVENTS                            │
│                                                                  │
│  Event: "order.status.updated"                                  │
│  Data: { "new_status": "accepted" }                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🔔 NOTIFICATION #2                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NotificationHelper.showOrderAccepted()                  │  │
│  │  • Green banner appears                                  │  │
│  │  • "Order Accepted"                                      │  │
│  │  • Shows driver name                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEBSOCKET EVENTS                            │
│                                                                  │
│  Event: "order.status.updated"                                  │
│  Data: { "new_status": "picked_up" }                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🔔 NOTIFICATION #3                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NotificationHelper.showOrderPickedUp()                  │  │
│  │  • Blue banner appears                                   │  │
│  │  • "Order Picked Up"                                     │  │
│  │  • Shows driver name                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEBSOCKET EVENTS                            │
│                                                                  │
│  Event: "order.status.updated"                                  │
│  Data: { "new_status": "in_transit" }                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🔔 NOTIFICATION #4                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NotificationHelper.showOrderInTransit()                 │  │
│  │  • Orange banner appears                                 │  │
│  │  • "On The Way"                                          │  │
│  │  • Shows ETA                                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WEBSOCKET EVENTS                            │
│                                                                  │
│  Event: "order.status.updated"                                  │
│  Data: { "new_status": "completed" }                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🔔 NOTIFICATION #5                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  NotificationHelper.showOrderDelivered()                 │  │
│  │  • Green banner appears                                  │  │
│  │  • "Delivered"                                           │  │
│  │  • "Your order has been delivered!"                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Order Complete │
                    └────────────────┘
```

## 🎨 Notification Banner Design

```
┌─────────────────────────────────────────────────────────────┐
│  [Icon]  Notification Title                          [X]    │
│          Notification message text here                     │
└─────────────────────────────────────────────────────────────┘
     │
     └─ Swipe down to dismiss
     └─ Auto-dismiss after 4 seconds
     └─ Tap to navigate to relevant screen
```

## 🔧 Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                      │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ Driver Finding  │  │ Order Tracking  │                  │
│  │     Screen      │  │     Screen      │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                            │
│           │ setContext()       │ setContext()               │
│           ▼                    ▼                            │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ Driver Finding  │  │ Live Tracking   │                  │
│  │    Provider     │  │    Provider     │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
└───────────┼─────────────────────┼──────────────────────────┘
            │                     │
            │ showDriverAssigned()│ _showStatusNotification()
            ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      HELPER LAYER                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           NotificationHelper (Static Methods)        │  │
│  │  • showDriverAssigned()                              │  │
│  │  • showOrderAccepted()                               │  │
│  │  • showOrderPickedUp()                               │  │
│  │  • showOrderInTransit()                              │  │
│  │  • showOrderDelivered()                              │  │
│  │  • showOrderCancelled()                              │  │
│  └────────────────────────┬─────────────────────────────┘  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              NotificationService                     │  │
│  │  • showNotificationByType()                          │  │
│  │  • Manages notification state                        │  │
│  │  • Handles notification logic                        │  │
│  └────────────────────────┬─────────────────────────────┘  │
└───────────────────────────┼──────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      WIDGET LAYER                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           InAppNotificationBanner (Existing!)        │  │
│  │  • Beautiful animated banner                         │  │
│  │  • Swipe to dismiss                                  │  │
│  │  • Auto-dismiss after 4 seconds                      │  │
│  │  • Tap to navigate                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🌐 WebSocket Integration

```
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND SERVER                          │
│  • Order status changes                                     │
│  • Driver location updates                                  │
│  • Real-time events                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ WebSocket Connection
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    WEBSOCKET SERVICE                         │
│  • Connects to backend                                      │
│  • Subscribes to order channel                              │
│  • Listens for events                                       │
│  • Emits events to providers                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Event Stream
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  LIVE TRACKING PROVIDER                      │
│  • Receives events                                          │
│  • Updates state                                            │
│  • Shows notifications                                      │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Notification State Management

```
┌─────────────────────────────────────────────────────────────┐
│                  NOTIFICATION PROVIDER                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  State:                                              │  │
│  │  • List<NotificationDto> notifications               │  │
│  │  • int unreadCount                                   │  │
│  │                                                       │  │
│  │  Methods:                                            │  │
│  │  • markAsRead(id)                                    │  │
│  │  • markAllAsRead()                                   │  │
│  │  • clearAll()                                        │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Key Features

### ✅ Automatic Integration
- No manual calls needed in screens
- Providers handle everything automatically
- Context-safe implementation

### ✅ Real-time Updates
- WebSocket for instant notifications
- Polling fallback if WebSocket fails
- Efficient and reliable

### ✅ Beautiful UI
- Animated banner with slide-in effect
- Color-coded by notification type
- Icons for visual clarity
- Auto-dismiss and swipe-to-dismiss

### ✅ Clean Architecture
- Separation of concerns
- Reusable components
- Easy to maintain and extend

---

**This diagram shows the complete flow from order creation to delivery, with all notification touchpoints clearly marked.**
