# Processing/Loading UI Screens - Comprehensive Audit

**Generated:** February 19, 2026  
**Purpose:** Complete inventory of all screens with processing/loading UI states

---

## 📊 Summary

This document catalogs all screens in the CarGo app that implement processing or loading UI patterns. The screens are categorized by their loading UI implementation type.

---

## 🎯 Category 1: Screens with `isProcessing` State + Button Loading

These screens use a boolean `isProcessing` flag and show loading indicators inside action buttons.

### **1. GCash Payment Screen**
- **File:** `lib/USERS-UI/Renter/bookings/gcash_payment_screen.dart`
- **State Variable:** `bool isProcessing = false;`
- **Loading UI:** 
  - Button shows `CircularProgressIndicator` with "Processing Payment..." text
  - Button is disabled when `isProcessing || !hasAgreedToTerms`
- **Context:** Rental payment submission

### **2. Late Fee Payment Screen**
- **File:** `lib/USERS-UI/Renter/payments/late_fee_payment_screen.dart`
- **State Variable:** `bool isProcessing = false;`
- **Loading UI:**
  - Button shows `CircularProgressIndicator` during payment processing
  - Button is disabled when `isProcessing || !hasAgreedToTerms`
- **Context:** Late fee payment submission

### **3. Car Submit Screen (Vehicle Listing)**
- **File:** `lib/USERS-UI/Owner/car_listing/car_submit_screen.dart`
- **State Variable:** `bool isSubmitting = false;`
- **Loading UI:**
  - Button shows `CircularProgressIndicator(color: Colors.white)`
  - Button is disabled when `isSubmitting`
- **Context:** Final submission of car/motorcycle listing

---

## 🎯 Category 2: Screens with `isLoading` / `loading` State + Full Screen/Button Loading

These screens use `isLoading` or `loading` boolean and may show full-screen or button-level loading.

### **4. Change Password Screen**
- **File:** `lib/USERS-UI/change_password.dart`
- **State Variable:** `bool loading = false;`
- **Loading UI:**
  - `LinearProgressIndicator` shown at top when loading
  - Button shows `CircularProgressIndicator` and is disabled
- **Context:** Password change operation

### **5. Extension Request Screen**
- **File:** `lib/USERS-UI/Renter/bookings/extension_request_screen.dart`
- **State Variable:** `bool _isLoading = false;`
- **Loading UI:**
  - Button shows `CircularProgressIndicator` during submission
  - Button is disabled when `_isLoading || _selectedDate == null`
- **Context:** Request to extend rental period

### **6. Car Location Screen**
- **File:** `lib/USERS-UI/Owner/car_listing/car_location_screen.dart`
- **State Variable:** `bool _isLoadingLocation = false;`
- **Loading UI:**
  - Location button shows `CircularProgressIndicator` with "Locating..." text
  - Button is disabled during location fetch
- **Context:** Getting current location for vehicle listing

### **7. Payout Settings Screen**
- **File:** `lib/USERS-UI/Owner/payout/payout_settings_screen.dart`
- **State Variables:** `bool _isLoading = true;` and `bool _isSaving = false;`
- **Loading UI:**
  - **Initial Load:** Full-screen `CircularProgressIndicator(color: Colors.black)` centered
  - **Saving:** Button shows `CircularProgressIndicator(color: white, strokeWidth: 2.5)`
- **Context:** Loading and saving payout settings

### **8. Edit Profile (Renter)**
- **File:** `lib/USERS-UI/Renter/edit_profile.dart`
- **Loading UI:**
  - Button shows `CircularProgressIndicator` during save
- **Context:** Updating renter profile information

### **9. Edit Profile Screen (Owner)**
- **File:** `lib/USERS-UI/Owner/edit_profile_screen.dart`
- **Loading UI:**
  - Button shows `CircularProgressIndicator(color: Colors.white)` vs "Save Changes" text
- **Context:** Updating owner profile information

---

## 🎯 Category 3: Screens with Dialog-Based Loading

These screens show a loading dialog (typically non-dismissible) during async operations.

### **10. Login Screen**
- **File:** `lib/login.dart`
- **State Variable:** `bool isLoading`
- **Loading UI:**
  - **Dialog:** `showDialog` with `barrierDismissible: false` and centered `CircularProgressIndicator()`
  - **Buttons:** Google/Facebook sign-in buttons show `CircularProgressIndicator(strokeWidth: 2)` when processing
- **Context:** User authentication (email, Google, Facebook)

### **11. Register Page**
- **File:** `lib/register_page.dart`
- **Loading UI:**
  - **Dialog:** `showDialog` with `barrierDismissible: false` and centered `CircularProgressIndicator()`
  - Dialog dismissed after registration completes
- **Context:** New user registration

### **12. Booking Screen**
- **File:** `lib/USERS-UI/Renter/bookings/booking_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator(color: Theme iconTheme color)` while checking verification
  - Dialog with `CircularProgressIndicator` during booking submission
- **Context:** Creating a new rental booking

### **13. Request Dialog (Owner)**
- **File:** `lib/USERS-UI/Owner/req_model/request_dialog.dart`
- **Loading UI:**
  - Shows dialog with `CircularProgressIndicator(color: Colors.white)` during approve/reject operations
  - Dialog is dismissed after operation completes
- **Context:** Approving or rejecting rental requests

---

## 🎯 Category 4: Screens with Inline/Embedded Loading States

These screens show loading indicators inline within the UI, often while fetching data.

### **14. Refund Request Screen**
- **File:** `lib/USERS-UI/Renter/payments/refund_request_screen.dart`
- **Loading UI:**
  - Button shows `CircularProgressIndicator(color: white, strokeWidth: 2.5)` vs "Submit Refund Request"
- **Context:** Submitting refund request

### **15. Excess Mileage Payment Screen**
- **File:** `lib/USERS-UI/Renter/payments/excess_mileage_payment_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator` during payment processing
- **Context:** Paying for excess mileage charges

### **16. Submit Review Screen**
- **File:** `lib/USERS-UI/Reporting/submit_review_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator` during review submission
- **Context:** Submitting vehicle/host review

### **17. File Claim Screen**
- **File:** `lib/USERS-UI/Renter/insurance/file_claim_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator` during claim submission
- **Context:** Filing insurance claim

### **18. Odometer Input Screen**
- **File:** `lib/USERS-UI/widgets/odometer_input_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator` during odometer reading submission
- **Context:** Recording start/end odometer readings

### **19. Selfie Screen (Owner Verification)**
- **File:** `lib/USERS-UI/Owner/verification/selfie_screen.dart`
- **Loading UI:**
  - Shows `CircularProgressIndicator` during selfie upload
- **Context:** Uploading selfie for identity verification

---

## 🎯 Category 5: Screens with Data Loading States (List/Content Fetching)

These screens show loading while fetching data to display (lists, details, etc.).

### **20. Cache Management Screen**
- **File:** `lib/USERS-UI/services/cache_management_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading cache data

### **21. Saved Searches Screen**
- **File:** `lib/USERS-UI/Renter/saved_searches_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading saved search data

### **22. Receipt Viewer Screen**
- **File:** `lib/USERS-UI/Renter/payments/receipt_viewer_screen.dart`
- **Loading UI:**
  - `Center(child: CircularProgressIndicator(color: colors.primary))`
- **Context:** Loading receipt data

### **23. Motorcycle Screen**
- **File:** `lib/USERS-UI/Renter/motorcycle_screen.dart`
- **Loading UI:**
  - Multiple instances: `const Center(child: CircularProgressIndicator())`
  - Also in list items: `const Center(child: CircularProgressIndicator(strokeWidth: 2))`
- **Context:** Loading motorcycle listings

### **24. Motorcycle List Screen**
- **File:** `lib/USERS-UI/Renter/motorcycle_list_screen.dart`
- **Loading UI:**
  - `_buildLoading() => const Center(child: CircularProgressIndicator())`
- **Context:** Loading motorcycle list

### **25. Motorcycle Detail Screen**
- **File:** `lib/USERS-UI/Renter/motorcycle_detail_screen.dart`
- **Loading UI:**
  - `Center(child: CircularProgressIndicator(color: Colors.black))`
- **Context:** Loading motorcycle details

### **26. Insurance Selection Screen**
- **File:** `lib/USERS-UI/Renter/insurance/insurance_selection_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading insurance options

### **27. Insurance Policy Screen**
- **File:** `lib/USERS-UI/Renter/insurance/insurance_policy_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading insurance policy details

### **28. Host Reviews Screen**
- **File:** `lib/USERS-UI/Renter/host/host_reviews_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator(color: Colors.black))`
- **Context:** Loading host reviews

### **29. Host Cars Screen**
- **File:** `lib/USERS-UI/Renter/host/host_cars_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator(color: Colors.black))`
- **Context:** Loading cars from a specific host

### **30. Favorites Screen**
- **File:** `lib/USERS-UI/Renter/favorites_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading favorite vehicles

### **31. My Booking Screen (History)**
- **File:** `lib/USERS-UI/Renter/bookings/history/my_booking_screen.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading booking history

### **32. Booking Detail Screen**
- **File:** `lib/USERS-UI/Renter/bookings/history/booking_detail_screen.dart`
- **Loading UI:**
  - `Center(child: CircularProgressIndicator(...))`
- **Context:** Loading booking details

### **33. Payout History Screen**
- **File:** `lib/USERS-UI/Owner/payout/payout_history_screen.dart`
- **Loading UI:**
  - `Center(child: CircularProgressIndicator(color: Colors.black))`
- **Context:** Loading payout history

### **34. Vehicle Availability Calendar**
- **File:** `lib/USERS-UI/Owner/calendar/vehicle_availability_calendar.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading calendar data

### **35. Enhanced Vehicle Calendar**
- **File:** `lib/USERS-UI/Owner/calendar/enhanced_vehicle_calendar.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading enhanced calendar data

### **36. Renter Vehicle Availability Widget**
- **File:** `lib/USERS-UI/Renter/widgets/renter_vehicle_availability_widget.dart`
- **Loading UI:**
  - `child: Center(child: CircularProgressIndicator())`
- **Context:** Loading vehicle availability

### **37. Renter Availability Calendar**
- **File:** `lib/USERS-UI/Renter/widgets/renter_availability_calendar.dart`
- **Loading UI:**
  - `const Center(child: CircularProgressIndicator())`
- **Context:** Loading availability calendar

---

## 🎯 Category 6: Special Cases & Other Patterns

### **38. Live Tracking Screen (Owner)**
- **File:** `lib/USERS-UI/Owner/live_tracking_screen.dart`
- **State Variable:** `_isLoading`
- **Loading UI:**
  - Custom `_buildLoadingOverlay()` method that creates an overlay
  - Conditional rendering: `if (_isLoading) _buildLoadingOverlay()`
- **Context:** Loading GPS tracking data

---

## 📈 Statistics

- **Total Screens with Loading UI:** 38
- **Category 1 (isProcessing + Button):** 3 screens
- **Category 2 (isLoading + Mixed):** 9 screens
- **Category 3 (Dialog-Based):** 4 screens
- **Category 4 (Inline/Embedded):** 9 screens
- **Category 5 (Data Loading):** 18 screens
- **Category 6 (Special Cases):** 1 screen

---

## 🔍 Additional Screens Likely to Have Loading (Not Exhaustively Checked)

Based on file naming and patterns, these screens **likely** have loading UI but weren't fully inspected:

1. **Car List Screen** - `lib/USERS-UI/Renter/car_list_screen.dart`
2. **Car Detail Screen** - `lib/USERS-UI/Renter/car_detail_screen.dart`
3. **Cars Map View Screen** - `lib/USERS-UI/Renter/cars_map_view_screen.dart`
4. **Motorcycles Map View Screen** - `lib/USERS-UI/Renter/motorcycles_map_view_screen.dart`
5. **Search Filter Screen** - `lib/USERS-UI/Renter/search_filter_screen.dart`
6. **Motorcycle Filter Screen** - `lib/USERS-UI/Renter/motorcycle_filter_screen.dart`
7. **Profile Screen** - `lib/USERS-UI/Renter/profile_screen.dart`
8. **Notification Screen** - `lib/USERS-UI/Renter/notification_screen.dart`
9. **Review Screen** - `lib/USERS-UI/Renter/review_screen.dart`
10. **Chat Detail Screen** - `lib/USERS-UI/Renter/chats/chat_detail_screen.dart`
11. **Payment History Screen** - `lib/USERS-UI/Renter/payments/payment_history_screen.dart`
12. **Refund History Screen** - `lib/USERS-UI/Renter/payments/refund_history_screen.dart`
13. **Dashboard (Owner)** - `lib/USERS-UI/Owner/dashboard.dart`
14. **Active Booking Page** - `lib/USERS-UI/Owner/active_booking_page.dart`
15. **Pending Requests Page** - `lib/USERS-UI/Owner/pending_requests_page.dart`
16. **Cancelled Bookings Page** - `lib/USERS-UI/Owner/cancelled_bookings_page.dart`
17. **Rejected Bookings Page** - `lib/USERS-UI/Owner/rejected_bookings_page.dart`
18. **MyCar Page** - `lib/USERS-UI/Owner/mycar_page.dart`
19. **Message Page** - `lib/USERS-UI/Owner/message_page.dart`
20. **Notification Page (Owner)** - `lib/USERS-UI/Owner/notification_page.dart`
21. **Enhanced Notification Page** - `lib/USERS-UI/Owner/notification/enhanced_notification_page.dart`
22. **Profile Page (Owner)** - `lib/USERS-UI/Owner/profile_page.dart`
23. **Owner Home Screen** - `lib/USERS-UI/Owner/owner_home_screen.dart`
24. **Owner Insurance Screen** - `lib/USERS-UI/Owner/insurance/owner_insurance_screen.dart`
25. **Payout Dashboard Screen** - `lib/USERS-UI/Owner/payout/payout_dashboard_screen.dart`
26. **Owner Transaction History** - `lib/USERS-UI/Owner/transactions/owner_transaction_history.dart`
27. **Analytics Dashboard Screen** - `lib/USERS-UI/Owner/analytics/analytics_dashboard_screen.dart`
28. **Report Screen** - `lib/USERS-UI/Reporting/report_screen.dart`

---

## 💡 Common Patterns Identified

### **Pattern A: Button Loading State**
```dart
bool isProcessing = false;

// Button implementation
ElevatedButton(
  onPressed: isProcessing ? null : _handleAction,
  child: isProcessing
    ? CircularProgressIndicator(color: Colors.white)
    : Text('Action'),
)
```

### **Pattern B: Full-Screen Loading**
```dart
bool _isLoading = true;

// Body implementation
body: _isLoading
  ? Center(child: CircularProgressIndicator())
  : _buildContent(),
```

### **Pattern C: Dialog Loading**
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => Center(child: CircularProgressIndicator()),
);

// After operation
Navigator.pop(context); // Close dialog
```

### **Pattern D: Linear Progress Bar**
```dart
Column(
  children: [
    if (loading) LinearProgressIndicator(),
    // Rest of content
  ],
)
```

---

## 🎨 Consistency Observations

### ✅ **Consistent Aspects:**
1. All screens use `CircularProgressIndicator` as the primary loading widget
2. Most screens disable buttons during processing
3. Color consistency: `Colors.white` for buttons, `Colors.black` or theme color for screens

### ⚠️ **Inconsistencies:**
1. **Variable naming:** Mix of `isProcessing`, `isLoading`, `loading`, `_isLoading`, `isSubmitting`
2. **strokeWidth:** Some specify `strokeWidth: 2` or `2.5`, others use default
3. **Loading text:** Some show "Processing...", others just show indicator
4. **Dialog patterns:** Some use `barrierDismissible: false`, implementation varies
5. **Centering:** Some use `Center(child: ...)`, others inline

---

## 🔧 Recommendations

1. **Standardize variable naming:** Use consistent naming like `_isLoading` for all screens
2. **Create reusable loading widgets:** 
   - `LoadingButton` widget
   - `LoadingDialog` helper
   - `LoadingOverlay` widget
3. **Consistent styling:** Define loading indicator colors and stroke widths in theme
4. **Loading text patterns:** Standardize when to show text vs. just indicator
5. **Error handling:** Ensure all loading states have proper error handling and state reset

---

## 📝 Notes

- This audit was performed on February 19, 2026
- Some screens may have multiple loading states (initial load + action loading)
- Widget-level loading (like `favorite_button.dart`) not included in main count
- Service-level loading patterns exist but are triggered from screens listed above

---

**End of Report**
