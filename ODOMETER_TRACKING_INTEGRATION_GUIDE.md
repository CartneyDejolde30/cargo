# Odometer Tracking Integration Guide

## 📍 Current Status

### ✅ What's Already Built:
- **Widget**: `lib/USERS-UI/widgets/odometer_input_screen.dart` - Fully functional odometer input screen with photo upload
- **Backend APIs**:
  - `api/mileage/record_start_odometer.php` - Records starting odometer
  - `api/mileage/record_end_odometer.php` - Records ending odometer
  - `api/mileage/get_mileage_details.php` - Retrieves mileage data
- **Database**: All odometer fields exist in `bookings` table
- **Admin Panel**: `mileage_verification.php` - Admin can view and verify mileage

### ❌ What's Missing:
- **Owner App Integration** - Odometer screen is NOT called from Owner's active bookings
- **Renter App Integration** - Renter also needs to record odometer at pickup/return
- **Visual Indicators** - No buttons or prompts to record odometer readings

---

## 🎯 Where Odometer Should Appear

### **For OWNER:**

#### **1. When Starting a Rental (Pickup)**
**Location**: `lib/USERS-UI/Owner/active_booking_page.dart`
- **Current**: Owner clicks "Start Rent / Picked Up" button
- **Should Add**: After clicking, prompt owner to record START odometer
- **Flow**: 
  ```
  Owner clicks "Start Rent" 
  → Show confirmation dialog
  → Navigate to OdometerInputScreen (start)
  → Record reading + photo
  → Mark trip as started
  ```

#### **2. When Ending a Rental (Return)**
**Location**: `ActiveBookingDetailsPage` in same file
- **Current**: Owner clicks "End Trip" button
- **Should Add**: Prompt owner to record END odometer before ending
- **Flow**:
  ```
  Owner clicks "End Trip"
  → Navigate to OdometerInputScreen (end)
  → Record reading + photo
  → Calculate distance
  → Mark trip as completed
  ```

#### **3. View Mileage Details**
**Location**: `ActiveBookingDetailsPage`
- **Should Add**: Section showing:
  - Starting odometer reading + photo
  - Ending odometer reading + photo (if recorded)
  - Total distance traveled
  - Expected vs actual mileage

---

## 🔧 Implementation Code

### **Step 1: Import the Odometer Screen**

Add to `lib/USERS-UI/Owner/active_booking_page.dart`:

```dart
import 'package:cargo/USERS-UI/widgets/odometer_input_screen.dart';
```

### **Step 2: Modify Start Trip Handler**

Replace the `_handleStartTrip` method:

```dart
Future<void> _handleStartTrip(Map<String, dynamic> booking) async {
  // Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      // ... existing dialog code ...
    ),
  );

  if (confirmed != true || !mounted) return;

  // ✅ NEW: Navigate to odometer input screen
  final odometerRecorded = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => OdometerInputScreen(
        bookingId: int.parse(booking['booking_id'].toString()),
        vehicleName: booking['car_full_name'] ?? 'Vehicle',
        vehicleImage: booking['car_image'] ?? '',
        isStartOdometer: true, // Recording START odometer
        userId: int.parse(_ownerId!),
        userType: 'owner',
      ),
    ),
  );

  if (odometerRecorded != true) {
    // User cancelled odometer recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Odometer recording cancelled. Trip not started.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final result = await _bookingService.startTrip(
      booking['booking_id'].toString(),
      _ownerId!,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      await _handleRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to start trip'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### **Step 3: Modify End Trip Handler**

Update `_handleEndTrip` in `_ActiveBookingDetailsPageState`:

```dart
Future<void> _handleEndTrip() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('End Trip?'),
      content: Text('Record the final odometer reading to complete this rental.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Record Odometer'),
        ),
      ],
    ),
  );

  if (confirmed != true || !mounted) return;

  // ✅ NEW: Get the starting odometer from booking
  final startOdometer = int.tryParse(widget.booking['odometer_start']?.toString() ?? '0');
  
  if (startOdometer == null || startOdometer == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting odometer not found. Cannot end trip.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Navigate to odometer input screen for END reading
  final odometerRecorded = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => OdometerInputScreen(
        bookingId: int.parse(widget.booking['booking_id'].toString()),
        vehicleName: widget.booking['car_full_name'] ?? 'Vehicle',
        vehicleImage: widget.booking['car_image'] ?? '',
        isStartOdometer: false, // Recording END odometer
        startOdometer: startOdometer, // Pass starting odometer for validation
        userId: int.parse(widget.ownerId),
        userType: 'owner',
      ),
    ),
  );

  if (odometerRecorded != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Odometer recording cancelled.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isEnding = true);

  try {
    final result = await _bookingService.endTrip(
      widget.booking['booking_id'].toString(),
      widget.ownerId,
    );

    if (!mounted) return;
    setState(() => _isEnding = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to end trip'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _isEnding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Network error. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### **Step 4: Add Mileage Display Section**

Add this method to `_ActiveBookingDetailsPageState`:

```dart
Widget _buildMileageSection() {
  final odometerStart = widget.booking['odometer_start'];
  final odometerEnd = widget.booking['odometer_end'];
  final startPhoto = widget.booking['odometer_start_photo'];
  final endPhoto = widget.booking['odometer_end_photo'];
  
  if (odometerStart == null) {
    return SizedBox(); // Don't show if no odometer data
  }
  
  final distance = odometerEnd != null 
      ? (int.parse(odometerEnd.toString()) - int.parse(odometerStart.toString()))
      : null;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Mileage Tracking',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Starting Odometer
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting Odometer',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$odometerStart km',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (startPhoto != null)
                  GestureDetector(
                    onTap: () {
                      // Show full image
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Image.network(
                            'https://cargoph.online/cargoAdmin/$startPhoto',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        'https://cargoph.online/cargoAdmin/$startPhoto',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (odometerEnd != null) ...[
              Divider(height: 24),
              // Ending Odometer
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ending Odometer',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$odometerEnd km',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (endPhoto != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Image.network(
                              'https://cargoph.online/cargoAdmin/$endPhoto',
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://cargoph.online/cargoAdmin/$endPhoto',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              
              Divider(height: 24),
              // Total Distance
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Distance',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$distance km',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      SizedBox(height: 20),
    ],
  );
}
```

Then add it to the `build` method in the details page, before the "Trip Details" section:

```dart
_buildMileageSection(),
_buildSection('Trip Details', [
  // ... existing trip details
]),
```

---

## 📱 Visual Flow

### **Owner Flow:**

```
┌─────────────────────────────────────┐
│   Active Bookings Page              │
│                                      │
│   ┌────────────────────────────┐   │
│   │  Toyota Vios               │   │
│   │  ₱800/day                  │   │
│   │  Renter: John Doe          │   │
│   │                            │   │
│   │  [Start Rent / Picked Up]  │ ◄─── Click this
│   └────────────────────────────┘   │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│   Odometer Input Screen             │
│                                      │
│   📷 Take Photo of Odometer          │
│   ┌────────────────────────────┐   │
│   │ [Camera placeholder]        │   │
│   └────────────────────────────┘   │
│                                      │
│   Odometer Reading (km)              │
│   ┌────────────────────────────┐   │
│   │  12,345                     │   │
│   └────────────────────────────┘   │
│                                      │
│   [Submit Reading]                   │
└─────────────────────────────────────┘
                ↓
          Trip Started!
```

### **When Ending:**

```
┌─────────────────────────────────────┐
│   Booking Details Page              │
│                                      │
│   Starting Odometer: 12,345 km      │
│   [Photo thumbnail]                  │
│                                      │
│   [End Trip] ◄────────────────────── Click this
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│   Odometer Input Screen             │
│                                      │
│   📷 Take Photo of Final Odometer    │
│   ┌────────────────────────────┐   │
│   │ [Camera placeholder]        │   │
│   └────────────────────────────┘   │
│                                      │
│   Ending Odometer (km)               │
│   Must be > 12,345 km                │
│   ┌────────────────────────────┐   │
│   │  12,450                     │   │
│   └────────────────────────────┘   │
│                                      │
│   Distance: 105 km                   │
│   [Submit Reading]                   │
└─────────────────────────────────────┘
                ↓
     Trip Completed!
     Distance: 105 km
```

---

## 🎯 Summary

### **Current Situation:**
- ❌ Odometer tracking exists but is NOT integrated into Owner app
- ❌ No buttons or prompts to record odometer
- ❌ Owner cannot see mileage data

### **What Needs to be Done:**
1. **Import OdometerInputScreen** into active_booking_page.dart
2. **Modify _handleStartTrip()** to navigate to odometer screen before starting
3. **Modify _handleEndTrip()** to navigate to odometer screen before ending
4. **Add _buildMileageSection()** to show odometer readings and photos
5. **Test the flow** with a real booking

### **Files to Modify:**
- `lib/USERS-UI/Owner/active_booking_page.dart` (1 file, ~100 lines of changes)

---

## 🚀 Quick Implementation Checklist

- [ ] Add import statement for OdometerInputScreen
- [ ] Update _handleStartTrip() method
- [ ] Update _handleEndTrip() method  
- [ ] Add _buildMileageSection() widget
- [ ] Add mileage section to details page UI
- [ ] Test start odometer recording
- [ ] Test end odometer recording
- [ ] Verify photos appear correctly
- [ ] Test distance calculation

---

**Would you like me to implement these changes for you?**
