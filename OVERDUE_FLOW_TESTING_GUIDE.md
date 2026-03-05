# Overdue Payment Flow - Testing Guide

## 🎯 Purpose
This guide will help you test the complete overdue payment flow end-to-end to verify everything works correctly.

---

## ✅ Prerequisites

1. **XAMPP Running**
   - Apache server started
   - MySQL server started
   
2. **Test Accounts**
   - Renter account (user_id = 1 or create new)
   - Owner account (user_id = 5 or create new)
   - Admin account for verification

3. **Test Vehicle**
   - At least one car or motorcycle in the system

---

## 📋 Manual Testing Steps

### **STEP 1: Create an Overdue Booking**

**Option A: Via Admin Panel**
1. Go to admin panel → Bookings
2. Create a new booking with:
   - Status: `approved`
   - Payment Status: `paid`
   - Pickup Date: 5 days ago
   - Return Date: 2 days ago (e.g., if today is Feb 16, set to Feb 14)
   - Return Time: `14:00:00`

**Option B: Via SQL**
```sql
INSERT INTO bookings (
    user_id, owner_id, car_id, vehicle_type,
    pickup_date, return_date, return_time,
    total_amount, status, payment_status,
    location, created_at
) VALUES (
    1,                                  -- Your renter user ID
    5,                                  -- Your owner user ID
    1,                                  -- Your test car ID
    'car',
    DATE_SUB(CURDATE(), INTERVAL 5 DAY),
    DATE_SUB(CURDATE(), INTERVAL 2 DAY),
    '14:00:00',
    5000.00,
    'approved',
    'paid',
    'Test Location',
    NOW()
);

-- Get the booking ID
SELECT LAST_INSERT_ID() as booking_id;
```

---

### **STEP 2: Run Overdue Detection Cron**

**Option A: Manual Trigger**
1. Navigate to: `http://localhost/cargo/public_html/cargoAdmin/cron/detect_overdue_rentals.php`
2. The script will:
   - Find your overdue booking
   - Calculate late fee (should be around ₱4,800 for 48 hours)
   - Update `overdue_status`, `overdue_days`, `late_fee_amount`
   - Send notifications

**Option B: Check via SQL**
```sql
-- Verify overdue status was set
SELECT 
    id as booking_id,
    overdue_status,
    overdue_days,
    late_fee_amount,
    late_fee_charged,
    late_fee_payment_status
FROM bookings 
WHERE id = YOUR_BOOKING_ID;
```

**Expected Results:**
- `overdue_status` = 'overdue' or 'severely_overdue'
- `overdue_days` = 2
- `late_fee_amount` = 4800.00 (approximately)
- `late_fee_charged` = 0
- `late_fee_payment_status` = 'none'

---

### **STEP 3: View Overdue Status in App**

**Using Flutter App:**
1. Login as the **renter** (user who made the booking)
2. Go to "My Bookings" → Active Bookings
3. Find your test booking
4. Click to view details

**Expected UI:**
- ❌ Red overdue banner displayed
- Shows days/hours overdue
- Shows late fee amount
- "Pay Now" button visible

**API Test (Optional):**
```bash
# Check overdue bookings API
curl "http://localhost/cargo/public_html/cargoAdmin/api/overdue/get_overdue_bookings.php?severity=all"
```

---

### **STEP 4: Submit Late Fee Payment**

**Using Flutter App:**
1. On the booking detail screen, click "Pay Now"
2. Enter GCash details:
   - GCash Number: `09123456789`
   - Reference Number: `TEST12345`
3. Review total amount (should be ₱4,800)
4. Submit payment

**Expected Results:**
- Success message shown
- Payment status changes to "Pending Verification"

**Verify in Database:**
```sql
-- Check late_fee_payments table
SELECT * FROM late_fee_payments 
WHERE booking_id = YOUR_BOOKING_ID
ORDER BY created_at DESC LIMIT 1;

-- Check booking status
SELECT 
    late_fee_payment_status,
    late_fee_charged
FROM bookings 
WHERE id = YOUR_BOOKING_ID;
```

**Expected:**
- `late_fee_payments.payment_status` = 'pending'
- `bookings.late_fee_payment_status` = 'pending'
- `bookings.late_fee_charged` = 0 (not yet charged)

---

### **STEP 5: Admin Verification**

**Using Admin Panel:**
1. Login to admin panel
2. Go to Payments → Late Fee Payments
3. Find the pending payment
4. Click "Verify" or "Approve"
5. Add notes: "Test approval"
6. Submit

**Using API (Optional):**
```bash
# Approve payment
curl -X POST http://localhost/cargo/public_html/cargoAdmin/api/payment/verify_late_fee_payment.php \
  -d "payment_id=YOUR_PAYMENT_ID" \
  -d "admin_id=1" \
  -d "action=approve" \
  -d "notes=Test approval"
```

**Verify in Database:**
```sql
-- Check payment was verified
SELECT 
    payment_status,
    verified_by,
    verified_at,
    verification_notes
FROM late_fee_payments 
WHERE id = YOUR_PAYMENT_ID;

-- Check booking updated
SELECT 
    late_fee_payment_status,
    late_fee_charged
FROM bookings 
WHERE id = YOUR_BOOKING_ID;
```

**Expected:**
- `late_fee_payments.payment_status` = 'verified'
- `late_fee_payments.verified_by` = 1 (admin ID)
- `bookings.late_fee_payment_status` = 'paid'
- `bookings.late_fee_charged` = 1

---

### **STEP 6: Complete Trip**

**Using Flutter App (Owner):**
1. Login as the **owner**
2. Go to Active Bookings
3. Find your test booking
4. Click "End Trip" or "Complete"

**Using API:**
```bash
curl -X POST http://localhost/cargo/public_html/cargoAdmin/api/bookings/end_trip.php \
  -d "booking_id=YOUR_BOOKING_ID" \
  -d "owner_id=5"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Trip marked as completed successfully",
  "was_overdue": true,
  "hours_overdue": 48,
  "late_fee": 4800,
  "warning": "Vehicle was returned 48 hours late. Late fee of ₱4,800.00 has been added to the booking."
}
```

**Verify Final Status:**
```sql
SELECT 
    status,
    overdue_status,
    late_fee_amount,
    late_fee_charged,
    late_fee_payment_status
FROM bookings 
WHERE id = YOUR_BOOKING_ID;
```

**Expected:**
- `status` = 'completed'
- `late_fee_charged` = 1
- `late_fee_payment_status` = 'paid'

---

## ✅ Success Criteria

After completing all steps, your booking should have:

| Field | Expected Value |
|-------|---------------|
| status | 'completed' |
| overdue_status | 'overdue' or 'severely_overdue' |
| overdue_days | 2 |
| late_fee_amount | ~4800.00 |
| late_fee_charged | 1 |
| late_fee_payment_status | 'paid' |

And in `late_fee_payments` table:

| Field | Expected Value |
|-------|---------------|
| payment_status | 'verified' |
| verified_by | (admin ID) |
| verified_at | (timestamp) |

---

## 🧪 Test Scenarios to Cover

### **Scenario 1: Basic Overdue Flow** ✅
- Booking 2 days overdue
- Submit payment
- Admin approves
- Complete trip
- ✅ All status fields correct

### **Scenario 2: Severely Overdue (3+ days)**
- Booking 3+ days overdue
- Check `overdue_status` = 'severely_overdue'
- Higher late fee charged
- Payment flow same as above

### **Scenario 3: Payment Rejection**
1. Submit payment
2. Admin **rejects** payment with reason
3. Verify `late_fee_payment_status` back to 'none'
4. Renter can resubmit payment
5. Admin approves second submission

### **Scenario 4: Complete Trip Before Payment**
1. Booking overdue
2. Owner completes trip WITHOUT payment submitted
3. Verify late fee still calculated
4. Renter can still pay after completion

### **Scenario 5: Rental Not Paid Yet**
1. Booking with `payment_status` = 'pending'
2. Becomes overdue
3. Submit payment for BOTH rental + late fee
4. Verify both amounts included

---

## 🔍 Debugging Tips

### **Late Fee Not Calculated?**
Check:
1. Cron job ran successfully
2. Return date/time is actually in the past
3. Booking status is 'approved'
4. Database settings table has late fee rates

### **Payment Not Showing?**
Check:
1. `late_fee_payments` table exists
2. `bookings.late_fee_payment_status` field exists
3. API response for errors
4. Network tab in browser dev tools

### **Status Not Updating?**
Check:
1. API returning success
2. Database fields writable
3. No foreign key constraints failing
4. Proper user permissions

---

## 📊 SQL Queries for Monitoring

### View Complete Overdue Flow
```sql
SELECT 
    b.id,
    b.status,
    b.overdue_status,
    b.overdue_days,
    b.late_fee_amount,
    b.late_fee_charged,
    b.late_fee_payment_status,
    lfp.payment_status as payment_record_status,
    lfp.verified_at
FROM bookings b
LEFT JOIN late_fee_payments lfp ON b.id = lfp.booking_id
WHERE b.id = YOUR_BOOKING_ID;
```

### Check All Overdue Bookings
```sql
SELECT 
    id,
    user_id,
    owner_id,
    return_date,
    overdue_status,
    late_fee_amount,
    late_fee_payment_status
FROM bookings
WHERE overdue_status IN ('overdue', 'severely_overdue')
ORDER BY return_date ASC;
```

### Check Pending Payments
```sql
SELECT 
    lfp.*,
    b.overdue_days,
    u.fullname as renter_name
FROM late_fee_payments lfp
JOIN bookings b ON lfp.booking_id = b.id
JOIN users u ON lfp.user_id = u.id
WHERE lfp.payment_status = 'pending'
ORDER BY lfp.created_at DESC;
```

---

## 🎉 What You're Testing

This end-to-end test verifies:

1. ✅ **Overdue Detection** - Cron job finds overdue bookings
2. ✅ **Late Fee Calculation** - Correct tiered rates applied
3. ✅ **Database Updates** - All status fields updated correctly
4. ✅ **API Endpoints** - All APIs working properly
5. ✅ **UI Display** - Flutter app shows overdue status
6. ✅ **Payment Submission** - Renters can submit late fee payments
7. ✅ **Admin Verification** - Admins can approve/reject
8. ✅ **Status Transitions** - Proper state management
9. ✅ **Trip Completion** - End trip works with overdue bookings
10. ✅ **Notifications** - Users notified at each step

---

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Cron job not detecting overdue | Check return_date is in past, status is 'approved' |
| Late fee is 0 | Check hours overdue > grace period (2 hours) |
| Can't submit payment | Check late_fee_amount > 0 in booking |
| Payment stuck in pending | Admin needs to verify via admin panel |
| Can't complete trip | Check booking status is 'approved' or 'ongoing' |

---

## 📝 Test Results Template

Copy this and fill in after testing:

```
=== OVERDUE PAYMENT FLOW TEST RESULTS ===
Date: ___________
Tester: ___________

STEP 1: Create Overdue Booking
  Booking ID: ___________
  Status: [ ] Pass [ ] Fail
  Notes: ___________

STEP 2: Overdue Detection
  Late Fee Calculated: ₱___________
  Status: [ ] Pass [ ] Fail
  Notes: ___________

STEP 3: View in App
  Overdue Banner Shown: [ ] Yes [ ] No
  Status: [ ] Pass [ ] Fail
  Notes: ___________

STEP 4: Submit Payment
  Payment ID: ___________
  Status: [ ] Pass [ ] Fail
  Notes: ___________

STEP 5: Admin Verification
  Verified At: ___________
  Status: [ ] Pass [ ] Fail
  Notes: ___________

STEP 6: Complete Trip
  Final Status: ___________
  Status: [ ] Pass [ ] Fail
  Notes: ___________

OVERALL RESULT: [ ] PASS [ ] FAIL

Issues Found:
1. ___________
2. ___________
```

---

## 🚀 Quick Start

**Fastest way to test:**

1. Start XAMPP (Apache + MySQL)
2. Run this SQL to create test booking:
   ```sql
   INSERT INTO bookings (user_id, owner_id, car_id, vehicle_type, pickup_date, return_date, return_time, total_amount, status, payment_status, location, created_at) 
   VALUES (1, 5, 1, 'car', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_SUB(CURDATE(), INTERVAL 2 DAY), '14:00:00', 5000, 'approved', 'paid', 'Test', NOW());
   SELECT LAST_INSERT_ID();
   ```
3. Visit: `http://localhost/cargo/public_html/cargoAdmin/cron/detect_overdue_rentals.php`
4. Open Flutter app → Login as renter → View booking
5. Pay late fee
6. Admin panel → Verify payment
7. Complete trip

**Total time: ~5 minutes**

---

Ready to start testing? Let me know if you need help with any step!
