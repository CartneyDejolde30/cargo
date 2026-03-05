<?php
/**
 * RELEASE ESCROW (Fixed)
 *
 * This file previously contained corrupted PHP (invalid backslashes).
 * Replaced with a thin wrapper around the already-maintained escrow release logic.
 *
 * Accepts:
 *  - POST form: booking_id=123
 *  - POST JSON: {"booking_id":123}
 */

session_start();
header('Content-Type: application/json');

require_once __DIR__ . '/public_html/cargoAdmin/include/config.php';
require_once __DIR__ . '/public_html/cargoAdmin/include/db.php';
require_once __DIR__ . '/public_html/cargoAdmin/api/escrow/release_to_owner.php';

if (!isset($_SESSION['admin_id'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit;
}

$bookingId = null;

// Support JSON payload
$raw = file_get_contents('php://input');
if (!empty($raw)) {
    $decoded = json_decode($raw, true);
    if (json_last_error() === JSON_ERROR_NONE && is_array($decoded) && isset($decoded['booking_id'])) {
        $bookingId = $decoded['booking_id'];
    }
}

// Support regular form POST
if ($bookingId === null && isset($_POST['booking_id'])) {
    $bookingId = $_POST['booking_id'];
}

$bookingId = intval($bookingId ?? 0);
if ($bookingId <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Booking ID is required']);
    exit;
}

$result = releaseEscrowToOwner($bookingId, null, intval($_SESSION['admin_id']));

// Normalize output to {success,message,...}
if (isset($result['success']) && $result['success'] === true) {
    echo json_encode([
        'success' => true,
        'message' => 'Escrow released successfully',
        'data' => $result,
    ]);
    exit;
}

$error = $result['error'] ?? 'Failed to release escrow';
http_response_code(400);
echo json_encode([
    'success' => false,
    'message' => $error,
    'data' => $result,
]);
