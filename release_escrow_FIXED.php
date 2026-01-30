<?php
/**
 * ============================================================================
 * RELEASE ESCROW API - FIXED VERSION
 * Release funds from escrow to owner (schedule payout)
 * 
 * CHANGES FROM ORIGINAL:
 * 1. Added escrow_id retrieval
 * 2. Added escrow_id to payout insert
 * 3. Added escrow table update
 * ============================================================================
 */

session_start();
header('Content-Type: application/json');

// Check authentication
if (!isset(\['admin_id'])) {
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

require_once '../../include/db.php';

// Validate input
if (!isset(\['booking_id']) || empty(\['booking_id'])) {
    echo json_encode(['success' => false, 'message' => 'Booking ID is required']);
    exit;
}

\ = intval(\['booking_id']);
\ = \['admin_id'];

// Start transaction
mysqli_begin_transaction(\);

try {
    // Get booking details
    \ = "
        SELECT 
            b.*,
            p.payment_status,
            u.fullname AS owner_name,
            u.email AS owner_email,
            u.gcash_number AS owner_gcash
        FROM bookings b
        LEFT JOIN payments p ON b.id = p.booking_id
        LEFT JOIN users u ON b.owner_id = u.id
        WHERE b.id = ?
    ";
    
    \ = mysqli_prepare(\, \);
    mysqli_stmt_bind_param(\, "i", \);
    mysqli_stmt_execute(\);
    \ = mysqli_stmt_get_result(\);
    \ = mysqli_fetch_assoc(\);
    
    if (!\) {
        throw new Exception('Booking not found');
    }
    
    // Validate escrow can be released
    if (\['escrow_status'] !== 'held') {
        throw new Exception('Escrow is not in held status. Current status: ' . \['escrow_status']);
    }
    
    // Check if it's on hold
    if (!empty(\['escrow_hold_reason'])) {
        throw new Exception('Cannot release escrow that is on hold. Please resolve the hold first.');
    }
    
    // Check if payment is verified
    if (\['payment_status'] !== 'verified' && \['payment_status'] !== 'paid') {
        throw new Exception('Payment must be verified before releasing escrow');
    }
    
    // Ideally, booking should be completed before releasing
    if (!in_array(\['status'], ['completed', 'ongoing', 'approved'])) {
        throw new Exception('Booking status must be completed, ongoing, or approved. Current: ' . \['status']);
    }
    
    // ✅ FIX #1: Get escrow_id before creating payout
    \ = "SELECT id FROM escrow WHERE booking_id = ? LIMIT 1";
    \ = mysqli_prepare(\, \);
    mysqli_stmt_bind_param(\, "i", \);
    mysqli_stmt_execute(\);
    \ = mysqli_stmt_get_result(\);
    
    if (mysqli_num_rows(\) === 0) {
        throw new Exception('Escrow record not found for this booking');
    }
    
    \ = mysqli_fetch_assoc(\);
    \ = \['id'];
    
    // ✅ FIX #2: Update escrow table (NEW - was missing!)
    \ = "
        UPDATE escrow 
        SET 
            status = 'released',
            released_at = NOW(),
            release_reason = 'Rental completed',
            processed_by = ?
        WHERE booking_id = ?
    ";
    
    \ = mysqli_prepare(\, \);
    mysqli_stmt_bind_param(\, "ii", \, \);
    
    if (!mysqli_stmt_execute(\)) {
        throw new Exception('Failed to update escrow table: ' . mysqli_error(\));
    }
    
    // Update escrow status in bookings
    \ = "
        UPDATE bookings 
        SET 
            escrow_status = 'released_to_owner',
            escrow_released_at = NOW(),
            payout_status = 'pending'
        WHERE id = ?
    ";
    
    \ = mysqli_prepare(\, \);
    mysqli_stmt_bind_param(\, "i", \);
    
    if (!mysqli_stmt_execute(\)) {
        throw new Exception('Failed to update escrow status: ' . mysqli_error(\));
    }
    
    // ✅ FIX #3: Create payout record WITH escrow_id
    \ = "
        INSERT INTO payouts (
            booking_id,
            owner_id,
            escrow_id,
            amount,
            platform_fee,
            net_amount,
            payout_method,
            payout_account,
            status,
            scheduled_at,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, 'gcash', ?, 'pending', NOW(), NOW())
    ";
    
    \ = mysqli_prepare(\, \);
    \ = \['owner_gcash'] ?? 'Not Set';
    
    mysqli_stmt_bind_param(\, "iiiddds", 
        \,
        \['owner_id'],
        \,  // ✅ ADDED - was missing!
        \['total_amount'],
        \['platform_fee'],
        \['owner_payout'],
        \
    );
    
    if (!mysqli_stmt_execute(\)) {
        throw new Exception('Failed to create payout record: ' . mysqli_error(\));
    }
    
    // Log escrow release if escrow_logs table exists
    \ = mysqli_query(\, "SHOW TABLES LIKE 'escrow_logs'");
    if (mysqli_num_rows(\) > 0) {
        \ = "
            INSERT INTO escrow_logs (
                booking_id,
                action,
                previous_status,
                new_status,
                admin_id,
                notes,
                created_at
            ) VALUES (?, 'release', 'held', 'released_to_owner', ?, 'Escrow released to owner', NOW())
        ";
        
        \ = mysqli_prepare(\, \);
        mysqli_stmt_bind_param(\, "ii", \, \);
        mysqli_stmt_execute(\);
    }
    
    // Commit transaction
    mysqli_commit(\);
    
    // TODO: Send notification to owner about payout
    
    echo json_encode([
        'success' => true,
        'message' => 'Escrow released successfully! Payout scheduled for owner.',
        'booking_id' => \,
        'owner_payout' => \['owner_payout'],
        'owner_name' => \['owner_name']
    ]);
    
} catch (Exception \) {
    // Rollback on error
    mysqli_rollback(\);
    
    echo json_encode([
        'success' => false,
        'message' => \->getMessage()
    ]);
}

mysqli_close(\);
?>
