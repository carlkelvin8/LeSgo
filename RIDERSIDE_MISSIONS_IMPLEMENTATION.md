# Rider Missions & Rewards System Implementation

## Overview
Implemented a complete missions and rewards system for riders with real backend data processing, progress tracking, and reward claiming functionality.

## Features

### 1. Mission Types
- **Daily Missions**: Reset every day
- **Weekly Missions**: Reset every week
- **Monthly Missions**: Reset every month
- **One-time Missions**: Complete once

### 2. Goal Types
- **complete_orders**: Complete X number of orders
- **specific_service**: Complete orders for specific service (lesride, leseat, lesbuy)
- **get_rating**: Receive a specific star rating
- **refer_friend**: Refer new drivers using referral code

### 3. Real-time Progress Tracking
- Automatically updates progress based on actual driver activity
- Tracks completed orders, ratings, referrals
- Shows progress percentage with visual progress bar

### 4. Reward System
- Rewards in PHP currency
- Claim button appears when mission is completed
- Rewards automatically added to driver's wallet
- Wallet transaction created for audit trail

## Backend Implementation

### Database Tables

#### `mission_templates`
Stores mission definitions created by admin:
- `title`: Mission name
- `description`: Mission details
- `type`: daily, weekly, monthly, one_time
- `goal_type`: complete_orders, get_rating, refer_friend, specific_service
- `goal_target`: Target number to achieve
- `reward_amount`: Reward in currency
- `service_code`: For specific_service type (lesride, leseat, etc.)
- `is_active`: Enable/disable mission

#### `driver_missions`
Tracks individual driver progress:
- `driver_profile_id`: Driver reference
- `mission_template_id`: Mission reference
- `current_progress`: Current progress count
- `goal_target`: Target to achieve
- `is_completed`: Completion status
- `completed_at`: Completion timestamp
- `reward_claimed`: Claim status
- `claimed_at`: Claim timestamp
- `mission_date`: Date for daily missions

### Models

#### `MissionTemplate`
- Defines mission structure
- Relationships: `hasMany(DriverMission)`

#### `DriverMission`
- Tracks driver progress
- Computed property: `progress_percentage`
- Relationships: `belongsTo(DriverProfile)`, `belongsTo(MissionTemplate)`

### API Endpoints

#### `GET /api/v1/driver/missions`
**Authentication**: Required (Bearer token)

**Response**:
```json
{
  "success": true,
  "missions": [
    {
      "id": 1,
      "title": "Book 10 orders today",
      "description": "Complete 10 orders in a single day",
      "reward": "PHP 100.00",
      "reward_amount": 100.00,
      "current_progress": 8,
      "goal_target": 10,
      "progress": 0.8,
      "is_completed": false,
      "reward_claimed": false
    }
  ]
}
```

**Features**:
- Auto-creates missions for driver if not exists
- Updates progress based on actual data
- Returns all active daily missions

#### `POST /api/v1/driver/missions/{id}/claim`
**Authentication**: Required (Bearer token)

**Response**:
```json
{
  "success": true,
  "message": "Reward claimed successfully",
  "reward_amount": 100.00
}
```

**Features**:
- Validates mission completion
- Prevents double claiming
- Adds reward to wallet
- Creates wallet transaction

### Progress Tracking Logic

The system automatically calculates progress based on:

1. **Complete Orders**: Counts completed orders for the day
2. **Specific Service**: Counts completed orders for specific service (lesride, leseat, etc.)
3. **Get Rating**: Checks if driver received target rating today
4. **Refer Friend**: Counts new users who used driver's referral code today

## Frontend Implementation

### Provider: `RiderMissionNotifier`

**State Management**:
```dart
class RiderMissionState {
  final List<RiderMission> missions;
  final bool isLoading;
  final String? error;
}
```

**Methods**:
- `loadMissions()`: Fetches missions from API
- `claimReward(missionId)`: Claims mission reward

### Mission Entity

```dart
class RiderMission {
  final int id;
  final String title;
  final String description;
  final String reward;
  final double rewardAmount;
  final int currentProgress;
  final int goalTarget;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final bool rewardClaimed;
}
```

### UI Components

#### `RiderMissionView`
- Displays list of missions
- Pull-to-refresh functionality
- Loading and error states
- Empty state handling

#### `RiderMissionCard`
- Shows mission title and reward
- Visual progress bar
- "CLAIM" button when completed
- "CLAIMED" badge when reward claimed

### API Service Methods

```dart
// Get driver missions
static Future<Map<String, dynamic>> getDriverMissions()

// Claim mission reward
static Future<Map<String, dynamic>> claimMissionReward(int missionId)
```

## Seeded Data

### Mission Templates
1. **Book 10 orders today** - PHP 100.00
2. **Refer 1 friend today** - PHP 50.00
3. **Achieve 25 bookings** - PHP 250.00
4. **Get 1 Lesride booking today** - PHP 50.00
5. **Get a 5 star rating today** - PHP 50.00

### Test Driver 74 Progress
- Book 10 orders: 8/10 (80%)
- Refer 1 friend: 0/1 (0%)
- Achieve 25 bookings: 20/25 (80%)
- Get 1 Lesride: 1/1 (100%) ✅ COMPLETED
- Get 5 star rating: 0/5 (0%)

## User Flow

1. **View Missions**: Driver opens Mission tab
2. **See Progress**: Real-time progress bars show completion status
3. **Complete Mission**: Progress automatically updates as driver completes orders
4. **Claim Reward**: "CLAIM" button appears when mission is completed
5. **Receive Reward**: Tap claim → reward added to wallet → "CLAIMED" badge shows

## Integration Points

### Wallet Integration
- Rewards automatically added to driver's wallet
- Wallet transaction created with description
- Transaction type: "credit"
- Description: "Mission reward: {mission_title}"

### Order Integration
- System tracks completed orders
- Filters by service type for specific missions
- Counts orders by date for daily missions

### Rating Integration
- Tracks ratings received by driver
- Checks for target rating (e.g., 5 stars)
- Filters by date for daily missions

### Referral Integration
- Tracks new users who used driver's referral code
- Counts referrals by date

## Files Created/Modified

### Backend
- ✅ `database/migrations/2026_04_23_000002_create_driver_missions_table.php`
- ✅ `app/Models/MissionTemplate.php`
- ✅ `app/Models/DriverMission.php`
- ✅ `database/seeders/MissionTemplateSeeder.php`
- ✅ `app/Http/Controllers/Api/DriverMissionController.php`
- ✅ `routes/api.php` (added mission routes)
- ✅ `seed_driver_missions.php` (test data seeder)

### Frontend (RIDERSIDE)
- ✅ `lib/presentation/provider/main/riderside/rider_mission_provider.dart`
- ✅ `lib/presentation/screens/main/riderside/views/rider_mission_view.dart` (updated)
- ✅ `lib/presentation/widgets/main/riderside/mission/rider_mission_card.dart` (updated)
- ✅ `lib/core/services/api_service.dart` (added mission methods)

## Testing

### Test Scenarios

1. **View Missions**
   - Login as driver 74
   - Navigate to Mission tab
   - Verify 5 missions display with correct progress

2. **Claim Completed Mission**
   - Find "Get 1 Lesride booking today" (100% complete)
   - Tap "CLAIM" button
   - Verify success message
   - Verify "CLAIMED" badge appears
   - Check wallet balance increased

3. **Progress Updates**
   - Complete an order
   - Refresh missions
   - Verify progress updated

4. **Error Handling**
   - Try claiming incomplete mission (should fail)
   - Try claiming already claimed mission (should fail)
   - Test network error scenarios

## Future Enhancements

1. **Weekly/Monthly Missions**: Implement weekly and monthly mission tracking
2. **Push Notifications**: Notify drivers when missions are completed
3. **Mission History**: Show completed missions history
4. **Leaderboard**: Show top drivers by missions completed
5. **Special Events**: Limited-time missions with bonus rewards
6. **Achievement Badges**: Visual badges for milestone achievements
7. **Mission Categories**: Group missions by type (earnings, service, social)
8. **Custom Missions**: Allow partners to create custom missions

## Notes

- Missions are automatically created for drivers on first API call
- Progress updates happen in real-time when fetching missions
- Rewards are added to wallet immediately upon claiming
- Daily missions reset at midnight
- System prevents double-claiming of rewards
- All mission data is persisted in database

## Security

- Authentication required for all mission endpoints
- Drivers can only view/claim their own missions
- Reward amounts validated against mission templates
- Wallet transactions logged for audit trail
- Mission completion verified before allowing claims
