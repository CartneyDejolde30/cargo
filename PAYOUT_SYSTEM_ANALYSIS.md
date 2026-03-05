# Payout System Analysis & Issues

## Overview
The payout system manages payments from the platform to car/motorcycle owners after bookings are completed. The flow involves escrow release, payout scheduling, and payout completion.

## Current Flow

### 1. **Escrow Release** (Step 1)
- When a booking is completed, admin can release escrow to owner
- File: `public_html/cargoAdmin/api/payment/release_escrow.php`
- Creates a payout record with status: **'scheduled'**
- Sets `scheduled_at` timestamp
- Updates booking: `payout_status = 'processing'`

### 2. **Admin Processes Payout** (Step 2)
- Admin views pending payouts in `public_html/cargoAdmin/payouts.php`
- Admin transfers money via GCash manually
- Admin submits payout with:
  - GCash reference number
  - Optional: GCash number override
  - Optional: Proof of transfer (screenshot)
- File: `public_html/cargoAdmin/api/payment/complete_payout.php`

### 3. **Owner Views Payout** (Step 3)
- Owner checks payout history in Flutter app
- File: `lib/USERS-UI/Owner/payout/payout_history_screen.dart`
- API: `public_html/cargoAdmin/api/payout/get_owner_payout_history.php`

---

## 🔴 IDENTIFIED ISSUES

### Issue #1: Misleading Status Display
**Problem:** Payouts show as "scheduled" but admin can immediately submit the payout without waiting.

**Root Cause:**
- When escrow is released, payout record is created with `status = 'scheduled'`
- However, there's no actual scheduling mechanism or delay
- Admin can immediately process the payout
- The status jumps from 'scheduled' → 'processing' → 'completed' instantly

**User Impact:**
- Confusing terminology - "scheduled" implies it will happen automatically later
- No clear indication that admin needs to manually process it
- Creates expectation that payment is automatic when it's actually manual

**Current Status Flow:**
```
Escrow Released → Payout Created (status: 'scheduled')
                ↓
Admin Submits → Payout Updated (status: 'processing' then 'completed')
```

**Recommended Fix:**
- Change initial status from 'scheduled' to **'pending'**
- This accurately reflects that it's waiting for admin action
- Update status flow: pending → processing → completed

---

### Issue #2: Transfer Proof Not Saved to Database
**Problem:** Admin uploads proof of transfer image, but it's NOT saved to the `payouts` table.

**Root Cause:**
In `complete_payout.php` line 234-236:
```php
// Store proof path in metadata if provided
if ($proofPath) {
    // We can log this in the transaction logger metadata
    // or store it in a separate payout_proofs table if needed in the future
}
```

**What Happens:**
1. ✅ File is uploaded successfully to `uploads/payout_proofs/`
2. ✅ `$proofPath` variable contains the file path
3. ❌ **BUT** the path is NEVER saved to the database
4. ❌ Only logged in transaction_logger metadata (not accessible to owners)

**Database Schema:**
The `payouts` table HAS a `transfer_proof` column (VARCHAR 255), but it's never populated!

**Impact:**
- Owner cannot see proof of transfer in their app
- No way to verify the payment was actually made
- Trust issues - owner receives notification but no proof
- Admin uploaded image is stored on server but not linked to payout record

---

### Issue #3: Owner Cannot View Transfer Proof
**Problem:** Even if proof was saved, the Flutter app doesn't display it.

**Root Cause:**

1. **API doesn't return transfer_proof:**
   - `get_owner_payout_history.php` queries the `transfer_proof` column
   - But it's NULL because Issue #2 (not saved)
   
2. **Flutter UI doesn't display image:**
   - `payout_history_screen.dart` only shows:
     - Net amount
     - Platform fee
     - Status
     - Date
     - Reference number
   - NO code to display transfer_proof image

**What's Missing:**
```dart
// Current code shows:
final reference = payout['completion_reference'] ?? 'N/A';

// But there's no:
final transferProof = payout['transfer_proof'];
// No Image.network() or CachedNetworkImage to display it
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ ADMIN SIDE                                                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Release Escrow                                            │
│    └─> Creates payout (status: 'scheduled') ❌ MISLEADING   │
│                                                               │
│ 2. View Payouts Page (payouts.php)                          │
│    └─> Shows pending payouts                                 │
│                                                               │
│ 3. Process Payout Modal                                      │
│    ├─> Enter GCash reference                                │
│    ├─> Upload proof image ✅ UPLOADED                       │
│    └─> Submit                                                │
│         ├─> File saved to disk ✅                           │
│         ├─> BUT NOT to database ❌                          │
│         └─> Status → 'completed'                            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ OWNER SIDE (Flutter App)                                     │
├─────────────────────────────────────────────────────────────┤
│ 1. Receives notification "Payout Completed"                  │
│                                                               │
│ 2. Views Payout History                                      │
│    ├─> Shows: Amount, Fee, Date, Reference ✅              │
│    └─> Does NOT show: Proof image ❌                        │
│                                                               │
│ 3. Cannot verify actual transfer                             │
│    └─> Must trust notification                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 REQUIRED FIXES

### Fix #1: Change Status from 'scheduled' to 'pending'
**Files to modify:**
1. `public_html/cargoAdmin/api/payment/release_escrow.php`
2. `public_html/cargoAdmin/api/escrow/release_to_owner.php`
3. `public_html/cargoAdmin/api/escrow/batch_release_escrows.php`
4. `public_html/cargoAdmin/payouts.php` (filter labels)

**Change:**
```php
// OLD:
status = 'scheduled'

// NEW:
status = 'pending'
```

---

### Fix #2: Save transfer_proof to Database
**File:** `public_html/cargoAdmin/api/payment/complete_payout.php`

**Current (line 217-223):**
```php
$stmt = $conn->prepare("
    UPDATE payouts SET
        status = 'completed',
        completion_reference = ?,
        payout_account = ?,
        processed_at = NOW(),
        processed_by = ?
    WHERE id = ?
");
```

**Fixed:**
```php
$stmt = $conn->prepare("
    UPDATE payouts SET
        status = 'completed',
        completion_reference = ?,
        payout_account = ?,
        transfer_proof = ?,
        processed_at = NOW(),
        processed_by = ?
    WHERE id = ?
");

// Bind parameters with proof path
$stmt->bind_param(
    "sssii",  // Changed from "ssii"
    $payoutReference,
    $gcashToUse,
    $proofPath,  // Add this
    $adminId,
    $payoutId
);
```

---

### Fix #3: Return transfer_proof in API
**File:** `public_html/cargoAdmin/api/payout/get_owner_payout_history.php`

Already includes `transfer_proof` in query - just needs Fix #2 to work! ✅

---

### Fix #4: Display transfer_proof in Flutter App
**File:** `lib/USERS-UI/Owner/payout/payout_history_screen.dart`

**Add to _buildPayoutCard:**
```dart
Widget _buildPayoutCard(Map<String, dynamic> payout) {
  final amount = double.tryParse(payout['net_amount']?.toString() ?? '0') ?? 0;
  final platformFee = double.tryParse(payout['platform_fee']?.toString() ?? '0') ?? 0;
  final status = payout['status'] ?? 'pending';
  final bookingId = payout['booking_id'] ?? 0;
  final date = payout['processed_at'] ?? payout['created_at'];
  final reference = payout['completion_reference'] ?? 'N/A';
  final transferProof = payout['transfer_proof'];  // ADD THIS

  // ... existing code ...

  // ADD AFTER REFERENCE:
  if (status == 'completed' && transferProof != null && transferProof.isNotEmpty) {
    const SizedBox(height: 8),
    _buildDetailRow('Proof of Transfer', 'View Image'),
    const SizedBox(height: 8),
    GestureDetector(
      onTap: () => _showTransferProof(transferProof),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            '${GlobalApiConfig.baseUrl}/$transferProof',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text('Image not available'),
              );
            },
          ),
        ),
      ),
    ),
  ],
}

// ADD METHOD:
void _showTransferProof(String imagePath) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text('Proof of Transfer'),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              child: Image.network(
                '${GlobalApiConfig.baseUrl}/$imagePath',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## Summary

| Issue | Current State | Impact | Fix Required |
|-------|--------------|--------|--------------|
| **Status Misleading** | Shows 'scheduled' but processable immediately | Confusing UX | Change to 'pending' |
| **Proof Not Saved** | Uploaded but not saved to DB | Owner can't verify | Update SQL query |
| **Proof Not Visible** | No UI to display image | Low trust | Add image viewer |

---

## Testing Checklist

After fixes:
- [ ] Create new payout - verify status is 'pending' not 'scheduled'
- [ ] Admin uploads proof - verify saved to `payouts.transfer_proof` column
- [ ] Owner views history - verify can see and tap to enlarge proof image
- [ ] Check `uploads/payout_proofs/` folder has images
- [ ] Verify proof URL in API response
- [ ] Test without proof upload (optional field)
