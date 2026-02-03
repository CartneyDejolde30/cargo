# Remaining Hardcoded URLs to Update

This file lists all remaining hardcoded URLs that should be updated manually or via bulk find/replace.

## 📊 Status Summary
- ✅ **Core Config Files:** Updated (api_config.dart, api_constants.dart, config.php, db.php)
- ✅ **Core Services:** Updated (auth, booking, insurance, overdue, GPS)
- ⚠️ **Remaining Files:** 40+ files with hardcoded URLs

## 🔧 Bulk Update Strategy

### Option 1: Find and Replace All (Recommended)

Use your IDE's "Find in Files" feature:

**Pattern 1: Base URL**
```
Find: "http://10.218.197.49/carGOAdmin/"
Replace: GlobalApiConfig.baseUrl + "/"
```

**Pattern 2: API Endpoints**
```
Find: "http://10.218.197.49/carGOAdmin/api/
Replace: GlobalApiConfig.apiUrl + "/
```

**Pattern 3: Uploads**
```
Find: "http://10.218.197.49/carGOAdmin/uploads/
Replace: GlobalApiConfig.uploadsUrl + "/
```

**Pattern 4: Image URLs**
```
Find: "http://10.218.197.49/carGOAdmin/uploads/$
Replace: GlobalApiConfig.getImageUrl(
```

### Option 2: Update by Category

## 📁 Files Needing Updates

### Renter UI Files (20 files)
```
lib/USERS-UI/Renter/
├── car_list_screen.dart
├── car_detail_screen.dart
├── motorcycle_list_screen.dart
├── motorcycle_screen.dart
├── motorcycle_detail_screen.dart
├── motorcycle_filter_screen.dart
├── search_filter_screen.dart
├── cars_map_view_screen.dart
├── motorcycles_map_view_screen.dart
├── edit_profile.dart
├── review_screen.dart
├── bookings/
│   ├── booking_screen.dart (line 170, 1580)
│   ├── gcash_payment_screen.dart
│   └── history/
│       └── booking_detail_screen.dart
├── payments/
│   ├── late_fee_payment_screen.dart
│   ├── excess_mileage_payment_screen.dart
│   ├── payment_history_screen.dart
│   ├── receipt_viewer_screen.dart
│   ├── refund_request_screen.dart
│   └── refund_history_screen.dart
├── host/
│   ├── host_profile_screen.dart
│   ├── host_cars_screen.dart
│   └── host_reviews_screen.dart
└── widgets/
    └── renter_availability_calendar.dart
```

### Owner UI Files (8 files)
```
lib/USERS-UI/Owner/
├── edit_profile_screen.dart
├── models/
│   └── submit_car_api.dart
├── req_model/
│   ├── request_dialog.dart
│   └── request_details_page.dart
├── payout/
│   ├── payout_dashboard_screen.dart
│   ├── payout_history_screen.dart
│   └── payout_settings_screen.dart
├── transactions/
│   └── owner_transaction_history.dart
├── services/
│   └── verification_service.dart
└── widgets/
    └── verify_popup.dart
```

### Reporting & Widgets (3 files)
```
lib/USERS-UI/
├── Reporting/
│   ├── report_screen.dart
│   └── submit_review_screen.dart
└── widgets/
    └── odometer_input_screen.dart
```

## 🎯 Quick Fix Script

Create a file `tmp_rovodev_fix_urls.dart` and run:

```dart
void main() {
  final files = [
    'lib/USERS-UI/Renter/car_list_screen.dart',
    'lib/USERS-UI/Renter/car_detail_screen.dart',
    // ... add all files
  ];
  
  for (var file in files) {
    print('Processing: $file');
    // Replace URLs with GlobalApiConfig
  }
}
```

## 📝 Manual Update Pattern

For each file:

1. **Add import at top:**
```dart
import 'package:flutter_application_1/config/api_config.dart';
```

2. **Replace baseUrl declarations:**
```dart
// FROM:
final String baseUrl = "http://10.218.197.49/carGOAdmin/";

// TO:
final String baseUrl = GlobalApiConfig.baseUrl + "/";
```

3. **Replace direct URLs:**
```dart
// FROM:
"http://10.218.197.49/carGOAdmin/api/get_cars.php"

// TO:
GlobalApiConfig.getCarsEndpoint
```

4. **Replace image URLs:**
```dart
// FROM:
"http://10.218.197.49/carGOAdmin/uploads/$path"

// TO:
GlobalApiConfig.getImageUrl(path)
```

## ⚡ Priority Files (Update First)

These are the most critical files for core functionality:

1. ✅ `lib/login.dart` - Already updated
2. ✅ `lib/register_page.dart` - Already updated
3. ✅ `lib/USERS-UI/Renter/renters.dart` - Already updated
4. ⚠️ `lib/USERS-UI/Renter/car_list_screen.dart` - Update needed
5. ⚠️ `lib/USERS-UI/Renter/bookings/booking_screen.dart` - Update needed
6. ⚠️ `lib/USERS-UI/Owner/models/submit_car_api.dart` - Update needed

## 🔍 How to Find Remaining URLs

Run this command in your terminal:
```bash
# Find all occurrences
grep -r "10.218.197.49" lib/ --include="*.dart"

# Count occurrences
grep -r "10.218.197.49" lib/ --include="*.dart" | wc -l
```

Or in PowerShell:
```powershell
Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | Select-String -Pattern "10.218.197.49"
```

## ✅ Testing After Updates

After updating all files:

1. **Test compilation:**
```bash
flutter clean
flutter pub get
flutter analyze
```

2. **Test in development:**
```dart
// Set to true temporarily
static const bool isDevelopment = true;
```

3. **Test in production:**
```dart
// Set to false
static const bool isDevelopment = false;
```

4. **Build and test:**
```bash
flutter build apk --debug
# Install and test all features
```

## 📦 Full Replacement Commands

Using VS Code or similar IDE:

**Search:**
```regex
http://10\.218\.197\.49/carGOAdmin/
```

**Replace with context:**
- If in base URL: `GlobalApiConfig.baseUrl + "/"`
- If in API call: Use specific endpoint from `GlobalApiConfig`
- If in image URL: `GlobalApiConfig.getImageUrl(path)`

## 🎉 Completion Checklist

- [ ] All `.dart` files updated
- [ ] Imports added where needed
- [ ] App compiles without errors
- [ ] App runs in development mode
- [ ] App runs in production mode
- [ ] All features tested
- [ ] No hardcoded URLs remain

## 🔍 Verification

Run this to verify no hardcoded URLs remain:
```bash
# Should return 0 or only comments
grep -r "10.218.197.49" lib/ --include="*.dart" | grep -v "^//"
```

---

**Note:** The core configuration is complete. These remaining updates are for UI files that reference the backend directly. They will automatically use the production domain once `isDevelopment = false` is set in `api_config.dart`.
