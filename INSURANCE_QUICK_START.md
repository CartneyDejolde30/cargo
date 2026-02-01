# 🚀 Insurance System - Quick Start Guide

## Step-by-Step Installation (5 Minutes)

### Step 1: Run Database Migration
```bash
# Open phpMyAdmin or MySQL command line
# Navigate to your database: dbcargo
# Execute the migration file
```

Or copy-paste this SQL:
```sql
SOURCE cargoAdmin/database_migrations/insurance_system_migration.sql;
```

### Step 2: Verify Installation
Check if tables were created:
```sql
SELECT COUNT(*) FROM insurance_coverage_types;
-- Should return: 4 (Basic, Standard, Premium, Comprehensive)

SELECT COUNT(*) FROM insurance_providers;
-- Should return: 1 (Cargo Platform Insurance)
```

### Step 3: Update API URL
Edit `lib/USERS-UI/services/insurance_service.dart`:
```dart
// Line 8: Update with your server IP
static const String baseUrl = 'http://YOUR_IP_HERE/carGOAdmin/api/insurance';
```

### Step 4: Test API (Optional)
```bash
# Test coverage types endpoint
curl http://YOUR_IP/carGOAdmin/api/insurance/get_coverage_types.php
```

### Step 5: Integrate with Booking Flow

Add this to your `booking_screen.dart` after calculating the total:

```dart
// Show insurance selection before payment
void _showInsuranceSelection() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InsuranceSelectionScreen(
        bookingId: 0, // Will be created after booking
        userId: int.parse(widget.userId!),
        rentalAmount: priceBreakdown!.totalAmount,
        onInsuranceSelected: (coverageType, premium) {
          // Add insurance premium to total
          setState(() {
            selectedInsurance = coverageType;
            insurancePremium = premium;
            finalTotal = priceBreakdown!.totalAmount + premium;
          });
          Navigator.pop(context);
          _proceedToPayment();
        },
      ),
    ),
  );
}
```

## 📊 What You Get

### For Renters:
- ✅ 4 insurance coverage options
- ✅ Real-time premium calculation
- ✅ Clear coverage breakdown
- ✅ Policy details after booking
- ✅ Claim filing system

### For Owners:
- ✅ Protected against damages
- ✅ Insurance verification for bookings
- ✅ Claim notifications

### For Admins:
- ✅ Policy management
- ✅ Claim review system
- ✅ Insurance analytics
- ✅ Audit trail

## 🎯 Coverage Options Summary

| Coverage Type | Premium Rate | Max Coverage | Deductible |
|--------------|--------------|--------------|------------|
| **Basic** (Required) | 12% | ₱100,000 | ₱5,000 |
| Standard | 18% | ₱300,000 | ₱3,000 |
| Premium | 25% | ₱500,000 | ₱2,000 |
| Comprehensive | 35% | ₱1,000,000 | ₱1,000 |

## 🧪 Quick Test

After installation, test with this example:
- Rental Amount: ₱2,100
- Coverage: Basic (12%)
- Insurance Premium: ₱252
- **Total: ₱2,352**

## 📞 Need Help?

Refer to `INSURANCE_INTEGRATION_README.md` for detailed documentation.

---
**Installation Time**: ~5 minutes  
**Status**: Ready to Use ✅
