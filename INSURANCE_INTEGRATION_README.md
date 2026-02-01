# Insurance System Integration - Implementation Guide

## Overview

This document describes the comprehensive insurance system integration for the Cargo vehicle rental platform. The system is designed to meet legal requirements for vehicle rental insurance in the Philippines.

## ✅ What Has Been Implemented

### 1. Database Schema (`cargoAdmin/database_migrations/insurance_system_migration.sql`)

#### Tables Created:
- **`insurance_providers`** - Manages insurance provider information
- **`insurance_policies`** - Stores policy details for each booking
- **`insurance_claims`** - Handles insurance claim submissions and processing
- **`insurance_coverage_types`** - Defines available coverage types (Basic, Standard, Premium, Comprehensive)
- **`insurance_audit_log`** - Tracks all insurance-related actions for compliance

#### Booking Table Extensions:
Added fields to `bookings` table:
- `insurance_required` (mandatory flag)
- `insurance_policy_id` (links to policy)
- `insurance_premium` (amount paid)
- `insurance_coverage_type` (selected coverage)
- `insurance_verified` (verification status)

### 2. Backend API Endpoints (`cargoAdmin/api/insurance/`)

#### Created Files:
1. **`create_policy.php`**
   - Creates insurance policy for a booking
   - Calculates premiums based on coverage type
   - Validates booking and user authentication
   - Generates unique policy numbers

2. **`get_policy.php`**
   - Retrieves policy details by booking ID or policy ID
   - Returns comprehensive coverage information
   - Calculates expiration status

3. **`get_coverage_types.php`**
   - Returns available insurance coverage options
   - Includes pricing and feature details
   - Shows mandatory vs optional coverage

4. **`file_claim.php`**
   - Allows users to file insurance claims
   - Validates claim against policy coverage limits
   - Generates unique claim numbers
   - Creates admin notifications

5. **`get_claims.php`**
   - Retrieves claim history for users
   - Supports filtering by status
   - Returns detailed claim information

### 3. Flutter Frontend (`lib/USERS-UI/`)

#### Models (`models/insurance_models.dart`):
- `InsuranceCoverage` - Coverage type details
- `InsurancePolicy` - Policy information
- `InsuranceClaim` - Claim details
- `CoverageFeatures` - Feature breakdown

#### Service (`services/insurance_service.dart`):
- API communication layer
- Premium calculation utilities
- Currency formatting helpers

#### Screens:
1. **`insurance/insurance_selection_screen.dart`**
   - Interactive coverage selection UI
   - Real-time premium calculation
   - Coverage comparison
   - Feature breakdown display

2. **`insurance/insurance_policy_screen.dart`**
   - Detailed policy information view
   - Coverage details display
   - Claim filing access
   - Provider contact information

## 🎯 Coverage Types Implemented

### Basic Coverage (12% premium - MANDATORY)
- Collision Damage: Up to ₱50,000
- Third-Party Liability: Up to ₱50,000
- Deductible: ₱5,000

### Standard Coverage (18% premium)
- Collision Damage: Up to ₱150,000
- Third-Party Liability: Up to ₱100,000
- Theft Protection: Up to ₱50,000
- Deductible: ₱3,000

### Premium Coverage (25% premium)
- Collision Damage: Up to ₱250,000
- Third-Party Liability: Up to ₱150,000
- Theft Protection: Up to ₱75,000
- Personal Injury: Up to ₱25,000
- Deductible: ₱2,000

### Comprehensive Coverage (35% premium)
- Collision Damage: Up to ₱500,000
- Third-Party Liability: Up to ₱300,000
- Theft Protection: Up to ₱150,000
- Personal Injury: Up to ₱50,000
- 24/7 Roadside Assistance
- Deductible: ₱1,000

## 📋 Installation & Setup

### Step 1: Database Migration

Run the SQL migration script:

```sql
-- Execute in your MySQL database
mysql -u root -p dbcargo < cargoAdmin/database_migrations/insurance_system_migration.sql
```

Or manually execute the file in phpMyAdmin.

### Step 2: Verify Database Tables

Check that these tables were created:
```sql
SHOW TABLES LIKE 'insurance_%';
```

Expected output:
- insurance_providers
- insurance_policies
- insurance_claims
- insurance_coverage_types
- insurance_audit_log

### Step 3: Update API Configuration

Update the base URL in `lib/USERS-UI/services/insurance_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS/carGOAdmin/api/insurance';
```

Replace `YOUR_IP_ADDRESS` with your server IP.

### Step 4: Integration with Booking Flow

The system is ready to integrate with your booking flow. Here's how:

#### In `booking_screen.dart`:

```dart
// Add insurance selection before payment
void _proceedToInsuranceSelection() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => InsuranceSelectionScreen(
        bookingId: bookingId,
        userId: int.parse(widget.userId!),
        rentalAmount: priceBreakdown!.totalAmount,
        onInsuranceSelected: (coverageType, premium) {
          // Update total amount
          setState(() {
            insurancePremium = premium;
            totalAmount = priceBreakdown!.totalAmount + premium;
          });
          _proceedToPayment();
        },
      ),
    ),
  );
}
```

## 🔄 User Flow

### Renter Flow:
1. User selects vehicle and dates
2. System calculates rental price
3. **Insurance selection screen appears** (NEW)
   - User views coverage options
   - System shows real-time premium calculation
   - User selects coverage type (Basic is mandatory)
4. Booking summary includes insurance premium
5. User proceeds to payment (rental + insurance)
6. Upon payment verification:
   - Booking is created
   - Insurance policy is automatically generated
   - Policy number is assigned
7. User can view policy details in booking section

### Claim Filing Flow:
1. User navigates to active booking
2. User clicks "View Insurance Policy"
3. User clicks "File Insurance Claim"
4. User fills claim form:
   - Incident type
   - Incident date & location
   - Description
   - Claimed amount
   - Evidence photos
   - Police report (if applicable)
5. Claim is submitted for admin review
6. Admin reviews and approves/rejects claim

## 🛠️ Testing Instructions

### Test 1: Create Insurance Policy

```bash
# Using curl or Postman
curl -X POST http://YOUR_IP/carGOAdmin/api/insurance/create_policy.php \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 1,
    "user_id": 7,
    "coverage_type": "basic"
  }'
```

### Test 2: Get Coverage Types

```bash
curl http://YOUR_IP/carGOAdmin/api/insurance/get_coverage_types.php
```

### Test 3: Get Policy Details

```bash
curl "http://YOUR_IP/carGOAdmin/api/insurance/get_policy.php?booking_id=1&user_id=7"
```

### Test 4: File a Claim

```bash
curl -X POST http://YOUR_IP/carGOAdmin/api/insurance/file_claim.php \
  -H "Content-Type: application/json" \
  -d '{
    "policy_id": 1,
    "booking_id": 1,
    "user_id": 7,
    "claim_type": "collision",
    "incident_date": "2026-02-01T10:30:00",
    "incident_description": "Minor collision at parking lot",
    "claimed_amount": 15000,
    "incident_location": "Manila, Philippines"
  }'
```

## 📊 Admin Dashboard Integration

### Recommended Admin Features (To Be Implemented):

1. **Insurance Management Page**
   - View all active policies
   - Search by policy number
   - Filter by status
   - Export policy data

2. **Claims Management Page**
   - View pending claims
   - Review evidence
   - Approve/reject claims
   - Process payouts
   - View claim history

3. **Insurance Analytics**
   - Total policies issued
   - Premium revenue
   - Claims ratio
   - Coverage type distribution

## 🔐 Security Considerations

1. **Data Encryption**: Sensitive insurance data should be encrypted
2. **User Authentication**: All API endpoints verify user identity
3. **Audit Trail**: All insurance actions are logged
4. **Policy Validation**: Claims are validated against policy limits
5. **Transaction Logging**: All insurance transactions are tracked

## 📱 Mobile App Features

### Current Features:
- ✅ Coverage type selection
- ✅ Real-time premium calculation
- ✅ Policy details view
- ✅ Claim filing interface
- ✅ Coverage comparison

### Recommended Enhancements:
- 📄 PDF policy document generation
- 📸 Photo upload for claims
- 📬 Push notifications for claim status
- 💳 Separate insurance payment option
- 📞 In-app provider contact

## 💡 Best Practices

### For Developers:
1. Always validate user authentication
2. Check policy expiration before allowing claims
3. Validate claimed amounts against coverage limits
4. Log all insurance-related actions
5. Handle API errors gracefully

### For Testing:
1. Test with various coverage types
2. Test claim filing with different amounts
3. Test policy expiration scenarios
4. Test with invalid data
5. Test concurrent policy creation

## 🐛 Troubleshooting

### Issue: Policy not created after payment
**Solution**: Check that `create_policy.php` is called after booking creation

### Issue: Premium calculation incorrect
**Solution**: Verify `insurance_coverage_types` table has correct rates

### Issue: Cannot file claim
**Solution**: Check policy status is 'active' and not expired

### Issue: Coverage types not showing
**Solution**: Verify `insurance_coverage_types` table has data (run migration script)

## 📞 API Response Examples

### Successful Policy Creation:
```json
{
  "success": true,
  "message": "Insurance policy created successfully",
  "data": {
    "policy_id": 1,
    "policy_number": "INS-2026-000001-BAS",
    "coverage_type": "basic",
    "premium_amount": 252.00,
    "coverage_limit": 100000.00,
    "deductible": 5000.00
  }
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Insurance policy already exists for this booking"
}
```

## 📚 Legal Compliance

This implementation follows Philippine insurance regulations:
- ✅ Mandatory third-party liability coverage
- ✅ Clear policy terms and conditions
- ✅ Deductible disclosure
- ✅ Claims process documentation
- ✅ Provider contact information

## 🚀 Future Enhancements

1. **Multi-Provider Support**: Integrate with multiple insurance providers
2. **Dynamic Pricing**: Adjust premiums based on vehicle value, driver age, location
3. **Claims Automation**: Automatic approval for claims under threshold
4. **Telematics Integration**: Use GPS data for claim verification
5. **Instant Coverage Certificates**: Generate digital certificates
6. **Renewal System**: Auto-renew for extended bookings

## 📄 Files Created Summary

### Backend (PHP):
- `cargoAdmin/database_migrations/insurance_system_migration.sql`
- `cargoAdmin/api/insurance/create_policy.php`
- `cargoAdmin/api/insurance/get_policy.php`
- `cargoAdmin/api/insurance/get_coverage_types.php`
- `cargoAdmin/api/insurance/file_claim.php`
- `cargoAdmin/api/insurance/get_claims.php`

### Frontend (Flutter):
- `lib/USERS-UI/models/insurance_models.dart`
- `lib/USERS-UI/services/insurance_service.dart`
- `lib/USERS-UI/Renter/insurance/insurance_selection_screen.dart`
- `lib/USERS-UI/Renter/insurance/insurance_policy_screen.dart`

### Documentation:
- `INSURANCE_INTEGRATION_README.md` (this file)

## ✅ Checklist for Go-Live

- [ ] Database migration executed successfully
- [ ] API endpoints tested and working
- [ ] Flutter screens integrated with booking flow
- [ ] Insurance premium added to payment calculation
- [ ] Policy creation happens after payment verification
- [ ] Admin dashboard updated to show insurance data
- [ ] Legal review of policy terms completed
- [ ] Insurance provider contract in place
- [ ] Customer support trained on insurance features
- [ ] Testing completed on production-like environment

## 📧 Support

For questions or issues with this integration, please contact the development team or refer to the inline code documentation.

---

**Version**: 1.0  
**Last Updated**: February 1, 2026  
**Status**: ✅ Ready for Integration Testing
