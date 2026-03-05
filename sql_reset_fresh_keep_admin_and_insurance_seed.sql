-- Fresh data reset (keeps admin accounts + insurance seed/config tables)
--
-- What this does:
--   - Clears transactional/app data so you start "fresh"
--   - Preserves:
--       * `admin` (your admin login)
--       * `insurance_providers`
--       * `insurance_coverage_types`
--
-- What this clears (important):
--   - `insurance_policies`, `insurance_claims`, `insurance_audit_log` are cleared because they depend on
--     `bookings` (FK ON DELETE CASCADE). If we kept them while clearing bookings, you'd end up with
--     broken/dangling references.
--
-- Notes:
--   - This script does NOT drop tables, procedures, triggers, or views.
--   - It temporarily disables FK checks to avoid ordering issues during TRUNCATE.
--
-- Usage:
--   Run on the target database (MySQL/MariaDB):
--     SOURCE sql_reset_fresh_keep_admin_and_insurance_seed.sql;
--

SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;

-- Core app data
TRUNCATE TABLE `archived_notifications`;
TRUNCATE TABLE `admin_action_logs`;
TRUNCATE TABLE `admin_notifications`;

TRUNCATE TABLE `favorites`;
TRUNCATE TABLE `notifications`;

TRUNCATE TABLE `car_photos`;
TRUNCATE TABLE `car_ratings`;
TRUNCATE TABLE `car_rules`;

TRUNCATE TABLE `gps_locations`;
TRUNCATE TABLE `gps_distance_tracking`;

TRUNCATE TABLE `mileage_logs`;
TRUNCATE TABLE `mileage_disputes`;

TRUNCATE TABLE `overdue_logs`;
TRUNCATE TABLE `late_fee_payments`;

TRUNCATE TABLE `receipts`;
TRUNCATE TABLE `refunds`;
TRUNCATE TABLE `payout_requests`;
TRUNCATE TABLE `payouts`;

TRUNCATE TABLE `payment_transactions`;
TRUNCATE TABLE `payment_transactions_deleted_backup`;
TRUNCATE TABLE `payment_attempts`;
TRUNCATE TABLE `payments_incomplete_backup`;
TRUNCATE TABLE `payments`;

TRUNCATE TABLE `escrow_transactions`;
TRUNCATE TABLE `escrow_logs`;
TRUNCATE TABLE `escrow`;

TRUNCATE TABLE `rental_extensions`;

-- Insurance runtime data (cleared; keep only seed/config tables)
TRUNCATE TABLE `insurance_audit_log`;
TRUNCATE TABLE `insurance_claims`;
TRUNCATE TABLE `insurance_policies`;

-- Bookings and inventory
TRUNCATE TABLE `bookings`;
TRUNCATE TABLE `vehicle_availability`;

TRUNCATE TABLE `cars`;
TRUNCATE TABLE `motorcycles`;

-- User-generated content and users
TRUNCATE TABLE `reviews`;
TRUNCATE TABLE `reports`;
TRUNCATE TABLE `report_logs`;
TRUNCATE TABLE `user_verifications`;
TRUNCATE TABLE `password_resets`;
TRUNCATE TABLE `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- Optional: keep `platform_settings` as-is (NOT truncated here)
-- If you want to reset settings too, uncomment:
-- TRUNCATE TABLE `platform_settings`;
