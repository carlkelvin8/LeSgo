# Design Document: Driver Has Arrived Status

## Overview

This feature implements the "Driver Has Arrived" status functionality for the ride-sharing application, allowing drivers to mark when they've arrived at pickup or delivery locations and automatically notifying customers in real-time. The feature integrates with the existing order tracking system across the Laravel backend API, Flutter customer app (FRONTEND/), and Flutter rider app (RIDERSIDE/).

## Main Algorithm/Workflow

```mermaid
sequenceDiagram
    participant Driver as Driver App
    participant API as Backend API
    participant DB as Database
    participant Event as Event System
    participant Customer as Customer App
    participant Push as Push Notification
    
    Driver->>API: PATCH /orders/{id}/status (driver_arrived_at_pickup)
    API->>API: Validate driver owns order
    API->>API: Validate current status (accepted)
    API->>DB: Update order status & timestamp
    DB-->>API: Order updated
    API->>Event: Broadcast OrderStatusUpdated
    Event->>Customer: WebSocket notification
    Event->>Push: FCM push notification
    API-->>Driver: Success response
    Customer->>Customer: Show "Driver has arrived" UI
    Customer->>API: Optional: Acknowledge arrival
    
    Note over Driver,Customer: Later: Driver marks picked up
    
    Driver->>API: PATCH /orders/{id}/status (picked_up)
    API->>DB: Update to picked_up status
    API->>Event: Broadcast status change
    Event->>Customer: Update UI to "In Transit"
