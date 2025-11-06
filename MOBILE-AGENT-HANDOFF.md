# Mobile Agent Handoff Document

**Date**: October 29, 2025
**From**: interactive-coach (web) agent
**To**: interactive-coach-mobile agent
**Purpose**: Continue Apple Watch Series 9 + Flutter integration

---

## 🎯 **MISSION**

Implement Apple Watch Series 9 health data integration for Interactive Coach mobile app:
- ✅ Fetch vitals from Apple Watch (HR, HRV, SpO2, sleep, steps, etc.)
- ✅ Display health dashboard in Flutter app
- ✅ Sync data to FastAPI backend
- ✅ Enable Hera (AI coach) to use health data in conversations

---

## 📁 **PROJECT CONTEXT**

### **Repository:**
- Location: `/Users/vijay/venv/interactive-coach-mobile`
- Git: Separate repository from web app
- Branch: `wip` (development branch)
- GitHub: https://github.com/vjnadkarni/interactive-coach-mobile

### **Tech Stack:**
- **Framework**: Flutter 3.27+ (Dart 3.9.2+)
- **Platform**: iOS only (iPhone 12 + Apple Watch Series 9)
- **HealthKit Integration**: `health` package v13.2.0
- **Backend**: Shared FastAPI backend at http://localhost:8000 (development)
- **Database**: Shared Supabase (same as web app)

### **Key Files:**
- `CLAUDE.md` - Project instructions (read this first!)
- `HEALTHKIT-SETUP.md` - Xcode configuration guide
- `APPLE-WATCH-INTEGRATION-STATUS.md` - Current progress report
- `pubspec.yaml` - Flutter dependencies

---

## ✅ **COMPLETED WORK (Phases 1-2)**

### **Phase 1: iOS Configuration (DONE)**

**File Modified:** `ios/Runner/Info.plist`
```xml
<key>NSHealthShareUsageDescription</key>
<string>Interactive Coach needs access to your health data from Apple Watch to provide personalized fitness coaching...</string>

<key>NSHealthUpdateUsageDescription</key>
<string>Interactive Coach may save workout and health data to your Health app...</string>
```

**Documentation Created:**
- `HEALTHKIT-SETUP.md` - Complete Xcode setup instructions

---

### **Phase 2: HealthService Implementation (DONE)**

**File Created:** `lib/services/health_service.dart` (409 lines)

**Key Features:**
- Singleton service for HealthKit access
- Permission management (request/check)
- Data fetching for 19 health metrics:
  - **Vitals**: HR, HRV, SpO2, resting HR, walking HR, respiratory rate
  - **Activity**: Steps, active energy, exercise time, distance
  - **Sleep**: Asleep, awake, in bed, deep sleep, REM sleep
  - **Events**: Workouts, high/low HR events, irregular HR events

**Public Methods:**
```dart
// Permissions
Future<bool> requestPermissions()
Future<bool> hasPermissions()

// Vitals
Future<List<HealthDataPoint>> getHeartRateData({DateTime start, DateTime end})
Future<double?> getLatestHeartRate()
Future<List<HealthDataPoint>> getHRVData({DateTime start, DateTime end})
Future<double?> getLatestHRV()
Future<List<HealthDataPoint>> getSpO2Data({DateTime start, DateTime end})
Future<double?> getLatestSpO2()

// Activity
Future<int?> getStepsForDate(DateTime date)
Future<double?> getActiveEnergyForDate(DateTime date)

// Summary
Future<Map<String, dynamic>> getDailySummary(DateTime date)

// Testing
Future<void> testHealthKitConnection()
```

---

**File Created:** `lib/screens/health_test_screen.dart` (253 lines)

**Purpose:** Test HealthKit integration before building full dashboard

**Features:**
- Request permissions button
- Test connection button
- Display latest health readings
- Show daily summary
- Status indicators (connected/not connected)
- User-friendly error messages

**Navigation:** Added floating action button to `avatar_screen.dart` for easy access

---

## ⏳ **PENDING WORK (Your Tasks)**

### **IMMEDIATE: Manual User Action Required**

**Step 1: Enable HealthKit in Xcode (CRITICAL)**

Follow instructions in `HEALTHKIT-SETUP.md`:

```bash
cd /Users/vijay/venv/interactive-coach-mobile
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Runner" target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability"
4. Add "HealthKit"
5. Verify `Runner.entitlements` file created with:
   ```xml
   <key>com.apple.developer.healthkit</key>
   <true/>
   ```

⚠️ **CRITICAL**: This MUST be done manually in Xcode. Cannot be automated.

---

**Step 2: Test on iPhone 12**

```bash
flutter run --release
```

Testing checklist:
- [ ] App builds without errors
- [ ] App runs on iPhone 12 (real device)
- [ ] Tap "Health Test" button (red floating button)
- [ ] Tap "Request Permissions"
- [ ] Permission dialog appears
- [ ] Grant all permissions
- [ ] Status shows "HealthKit Connected"
- [ ] Tap "Test Connection"
- [ ] Health data appears (HR, HRV, SpO2, steps, etc.)

**Expected Output:**
```
❤️ Heart Rate: [X] BPM
📊 HRV (SDNN): [X] ms
🫁 SpO2: [X]%
👣 Steps Today: [X]
🔥 Active Energy Today: [X] kcal
```

---

### **Phase 3: Backend API Endpoints (NEXT AFTER TESTING)**

**Backend Location:** `/Users/vijay/venv/interactive-coach/backend`

**New File to Create:** `backend/health/vitals.py`

**Endpoints to Implement:**

1. **POST /api/health/vitals**
   - Store heart rate, HRV, SpO2, resting HR
   - Request body:
     ```json
     {
       "user_id": "uuid",
       "timestamp": "2025-10-29T12:34:56Z",
       "heart_rate": 72,
       "hrv": 45,
       "spo2": 98,
       "resting_hr": 62
     }
     ```

2. **POST /api/health/activity**
   - Store steps, calories, exercise minutes
   - Request body:
     ```json
     {
       "user_id": "uuid",
       "date": "2025-10-29",
       "steps": 8542,
       "active_calories": 456,
       "exercise_minutes": 32,
       "stand_hours": 10,
       "distance_meters": 6234
     }
     ```

3. **POST /api/health/sleep**
   - Store sleep stages and duration
   - Request body:
     ```json
     {
       "user_id": "uuid",
       "sleep_start": "2025-10-29T22:30:00Z",
       "sleep_end": "2025-10-30T06:45:00Z",
       "deep_sleep_minutes": 98,
       "rem_sleep_minutes": 112,
       "core_sleep_minutes": 256,
       "awake_minutes": 23
     }
     ```

4. **GET /api/health/vitals/{user_id}**
   - Retrieve vitals history
   - Query params: `start_date`, `end_date`, `data_type`

5. **GET /api/health/summary/{user_id}/{date}**
   - Get daily health summary
   - Returns aggregated vitals + activity + sleep

**Database Schema:**

```sql
-- Migration 010: Create health tables

CREATE TABLE health_vitals (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  heart_rate INTEGER,  -- BPM
  hrv REAL,  -- SDNN in milliseconds
  spo2 INTEGER,  -- Percentage (95-100)
  resting_hr INTEGER,  -- BPM
  walking_hr INTEGER,  -- BPM
  respiratory_rate REAL,  -- Breaths per minute
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, timestamp, heart_rate)  -- Prevent duplicates
);

CREATE INDEX idx_health_vitals_user_timestamp ON health_vitals(user_id, timestamp DESC);

CREATE TABLE health_activity (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  date DATE NOT NULL,
  steps INTEGER,
  active_calories REAL,  -- kcal
  exercise_minutes INTEGER,
  stand_hours INTEGER,
  distance_meters REAL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)  -- One record per day per user
);

CREATE INDEX idx_health_activity_user_date ON health_activity(user_id, date DESC);

CREATE TABLE health_sleep (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sleep_start TIMESTAMP WITH TIME ZONE NOT NULL,
  sleep_end TIMESTAMP WITH TIME ZONE NOT NULL,
  deep_sleep_minutes INTEGER,
  rem_sleep_minutes INTEGER,
  core_sleep_minutes INTEGER,
  awake_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, sleep_start)  -- Prevent duplicate sleep sessions
);

CREATE INDEX idx_health_sleep_user_start ON health_sleep(user_id, sleep_start DESC);

-- Row-Level Security (RLS)
ALTER TABLE health_vitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_sleep ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own data
CREATE POLICY "users_own_vitals" ON health_vitals
  FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "users_own_activity" ON health_activity
  FOR ALL TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "users_own_sleep" ON health_sleep
  FOR ALL TO authenticated
  USING (user_id = auth.uid());
```

---

### **Phase 4: Mobile-to-Backend Sync (AFTER PHASE 3)**

**Task:** Add backend API calls to HealthService

**New File to Create:** `lib/services/health_sync_service.dart`

**Methods:**
```dart
class HealthSyncService {
  final HealthService _healthService = HealthService();
  final ApiService _apiService = ApiService();

  Future<void> syncVitalsToBackend(String userId);
  Future<void> syncActivityToBackend(String userId);
  Future<void> syncSleepToBackend(String userId);
  Future<void> syncAllHealthData(String userId);
  Future<DateTime?> getLastSyncTimestamp();
  Future<void> saveLastSyncTimestamp(DateTime timestamp);
}
```

**Integration:**
- Call backend API after fetching HealthKit data
- Store last sync timestamp locally
- Only upload new data (since last sync)
- Implement retry logic for failed uploads
- Show sync status in UI

---

### **Phase 5: Health Dashboard UI (AFTER PHASE 4)**

**New File to Create:** `lib/screens/health_dashboard_screen.dart`

**Features:**
- **Today's Summary Card**: HR, HRV, SpO2, Steps
- **Vitals Section**:
  - Heart rate graph (line chart, last 24 hours)
  - HRV reading with trend indicator
  - SpO2 reading with color coding (red if <95%)
- **Activity Section**:
  - Activity rings (Steps, Exercise, Stand)
  - Daily step count progress bar
  - Active calories burned
- **Sleep Section**:
  - Sleep duration bar chart
  - Sleep stages breakdown (Deep, REM, Core, Awake)
  - Sleep score/quality indicator
- **Sync Status**:
  - Last synced timestamp
  - Manual sync button
  - Auto-sync toggle
- **Pull-to-Refresh**: Fetch latest data from HealthKit

**UI Package to Add:**
```yaml
dependencies:
  fl_chart: ^0.69.0  # For charts and graphs
```

---

### **Phase 6: Charts & Visualizations (AFTER PHASE 5)**

**Charts to Implement:**

1. **Heart Rate Line Chart** (24-hour view)
   - X-axis: Time (hourly intervals)
   - Y-axis: BPM
   - Show min/max/avg zones

2. **Sleep Stages Bar Chart**
   - X-axis: Sleep stages (Deep, REM, Core, Awake)
   - Y-axis: Minutes
   - Color-coded bars

3. **Activity Rings** (Apple Watch style)
   - Move ring (steps goal)
   - Exercise ring (exercise minutes goal)
   - Stand ring (stand hours goal)

4. **Weekly Trends** (optional)
   - Line chart showing 7-day trends
   - Compare metrics week-over-week

---

### **Phase 7: Background Sync (FINAL PHASE)**

**Features:**
- Automatic sync every 4 hours (when app active)
- Sync on app launch
- Sync after workout completion (detected via HealthKit)
- Offline queue (store locally, upload when online)
- Batch upload (reduce API calls)

**Implementation:**
- Use Flutter background tasks
- Store unsent data in local SQLite database
- Implement exponential backoff for retries
- Show notification when sync fails

---

## 🔧 **BACKEND API CONTRACT**

### **Shared Backend:**
- **Development**: http://localhost:8000
- **Production**: https://coach.galenogen.com/api

### **Authentication:**
All health endpoints require JWT token from Supabase Auth.

```dart
// Get auth headers
final authHeaders = await getAuthHeaders();

// Make API call
final response = await http.post(
  Uri.parse('$backendUrl/api/health/vitals'),
  headers: authHeaders,
  body: jsonEncode(payload),
);
```

### **User ID:**
Use authenticated user's UUID from Supabase:
```dart
final user = await getCurrentUser();
final userId = user!.id;  // UUID string
```

---

## 📱 **DEVICE SETUP**

### **Hardware:**
- iPhone 12 (testing device)
- Apple Watch Series 9 (paired with iPhone)

### **Software:**
- iOS 17+ on iPhone
- watchOS 10+ on Apple Watch
- Xcode 15+ on Mac
- Flutter 3.27+ with Dart 3.9.2+

### **Configuration:**
- Health app enabled and syncing
- Apple Watch paired and syncing
- Recent health data available (wear watch for testing)

---

## 🚨 **CRITICAL NOTES**

### **HealthKit Limitations:**

1. **⚠️ Simulator NOT Supported**
   - HealthKit does NOT work on iOS Simulator
   - MUST use real iPhone 12

2. **⚠️ Blood Pressure NOT Available**
   - Apple Watch Series 9 cannot directly measure BP
   - Can detect hypertension patterns (41% sensitivity)
   - Can read manually-entered BP from Health app

3. **⚠️ SpO2 Sleep-Only**
   - Blood oxygen measured primarily during sleep
   - Not continuous monitoring

4. **⚠️ HRV Accuracy**
   - Apple Watch tends to underestimate HRV by ~8ms
   - Acceptable for trends, not clinical use

---

## 📂 **FILES TO REVIEW**

Before starting, read these files in this order:

1. **CLAUDE.md** - Project instructions (MUST READ FIRST)
2. **HEALTHKIT-SETUP.md** - Xcode setup guide
3. **APPLE-WATCH-INTEGRATION-STATUS.md** - Current progress
4. **lib/services/health_service.dart** - HealthKit service implementation
5. **lib/screens/health_test_screen.dart** - Testing UI
6. **pubspec.yaml** - Dependencies

---

## ✅ **HANDOFF CHECKLIST**

Before continuing work, verify:

- [ ] Read CLAUDE.md (project instructions)
- [ ] Read HEALTHKIT-SETUP.md (Xcode setup)
- [ ] Read APPLE-WATCH-INTEGRATION-STATUS.md (current status)
- [ ] Reviewed health_service.dart (understand API)
- [ ] Reviewed health_test_screen.dart (understand testing)
- [ ] Understand backend API contract (what endpoints to call)
- [ ] Understand database schema (what tables exist)

---

## 🎯 **IMMEDIATE NEXT STEPS**

### **Step 1: User must enable HealthKit in Xcode (MANUAL)**
Follow HEALTHKIT-SETUP.md instructions.

### **Step 2: User must test on iPhone 12 (MANUAL)**
Run app, test permissions, verify data fetching.

### **Step 3: Implement backend API (AGENT TASK)**
Once testing succeeds, create `/api/health/*` endpoints.

### **Step 4: Implement sync service (AGENT TASK)**
Add mobile-to-backend data upload.

### **Step 5: Build health dashboard UI (AGENT TASK)**
Create health_dashboard_screen.dart with charts.

---

## 📞 **QUESTIONS FOR USER**

When user starts new conversation, ask:

1. **Have you completed Xcode setup?**
   - Did you enable HealthKit capability?
   - Did Runner.entitlements file get created?

2. **Have you tested on iPhone 12?**
   - Did permissions dialog appear?
   - Did you grant all permissions?
   - Did test connection retrieve health data?

3. **What were the test results?**
   - Share console output or screenshots
   - Any errors encountered?
   - Which metrics have data, which don't?

4. **Ready to proceed to backend API?**
   - If testing passed, start Phase 3
   - If testing failed, debug HealthKit integration first

---

## 🔗 **RESOURCES**

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Flutter `health` package](https://pub.dev/packages/health)
- [HealthKit Data Types](https://developer.apple.com/documentation/healthkit/data_types)
- [Apple Watch Series 9 Specs](https://www.apple.com/apple-watch-series-9/specs/)

---

## ✅ **SUMMARY**

**What's Done:**
- ✅ iOS configuration (Info.plist permissions)
- ✅ HealthService implementation (complete, 409 lines)
- ✅ Health Test Screen (complete, 253 lines)
- ✅ Integration with main app (floating button)
- ✅ Documentation (setup guide, status report)

**What's Next:**
- ⏳ User: Enable HealthKit in Xcode (manual)
- ⏳ User: Test on iPhone 12
- ✅ Agent: Implement backend API (Phase 3) - **COMPLETE**
- ⏳ User: Run database migration (backend/migrations/010_create_health_tables.sql)
- ⏳ User: Test backend endpoints (backend/test_health_endpoints.sh)
- ⏳ Agent: Implement sync service (Phase 4)
- ⏳ Agent: Build health dashboard UI (Phase 5)

**Current Status:** 🟢 PHASE 3 COMPLETE - Backend API Ready for Testing

---

**Good luck with the mobile development!** 🚀

---

**Handoff complete. Mobile agent can now take over from here.**
