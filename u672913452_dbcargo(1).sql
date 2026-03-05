-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Feb 11, 2026 at 12:19 PM
-- Server version: 11.8.3-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u672913452_dbcargo`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`u672913452_ethan`@`127.0.0.1` PROCEDURE `sp_check_escrow_release_eligibility` (IN `p_booking_id` INT, OUT `p_can_release` BOOLEAN, OUT `p_failure_reason` VARCHAR(255))   BEGIN
    DECLARE v_booking_status VARCHAR(50);
    DECLARE v_escrow_status VARCHAR(50);
    DECLARE v_escrow_hold_reason VARCHAR(100);
    DECLARE v_owner_gcash VARCHAR(255);
    DECLARE v_payment_verified_at DATETIME;
    
    -- Get booking details
    SELECT 
        b.status,
        b.escrow_status,
        b.escrow_hold_reason,
        u.gcash_number,
        b.payment_verified_at
    INTO 
        v_booking_status,
        v_escrow_status,
        v_escrow_hold_reason,
        v_owner_gcash,
        v_payment_verified_at
    FROM bookings b
    LEFT JOIN users u ON b.owner_id = u.id
    WHERE b.id = p_booking_id;
    
    -- Check requirements
    SET p_can_release = TRUE;
    SET p_failure_reason = NULL;
    
    -- Requirement 1: Booking completed
    IF v_booking_status != 'completed' THEN
        SET p_can_release = FALSE;
        SET p_failure_reason = 'Booking not completed (current status: ' + v_booking_status + ')';
    
    -- Requirement 2: Escrow status = held
    ELSEIF v_escrow_status != 'held' THEN
        SET p_can_release = FALSE;
        SET p_failure_reason = 'Escrow not in held status (current: ' + v_escrow_status + ')';
    
    -- Requirement 3: No active holds
    ELSEIF v_escrow_hold_reason IS NOT NULL AND v_escrow_hold_reason != '' THEN
        SET p_can_release = FALSE;
        SET p_failure_reason = 'Escrow on hold: ' + v_escrow_hold_reason;
    
    -- Requirement 4: Owner GCash configured
    ELSEIF v_owner_gcash IS NULL OR v_owner_gcash = '' THEN
        SET p_can_release = FALSE;
        SET p_failure_reason = 'Owner GCash not configured';
    
    -- Requirement 5: Payment verified
    ELSEIF v_payment_verified_at IS NULL THEN
        SET p_can_release = FALSE;
        SET p_failure_reason = 'Payment not verified';
    END IF;
    
END$$

CREATE DEFINER=`u672913452_ethan`@`127.0.0.1` PROCEDURE `sp_get_vehicle_availability` (IN `p_vehicle_id` INT, IN `p_vehicle_type` VARCHAR(20), IN `p_start_date` DATE, IN `p_end_date` DATE)   BEGIN
    -- Get blocked dates
    SELECT 
        blocked_date as date,
        'blocked' as status,
        reason
    FROM vehicle_availability
    WHERE vehicle_id = p_vehicle_id
        AND vehicle_type = p_vehicle_type
        AND blocked_date BETWEEN p_start_date AND p_end_date
    
    UNION ALL
    
    -- Get booked dates (expanded to include all dates in booking range)
    SELECT 
        DATE_ADD(b.pickup_date, INTERVAL n.n DAY) as date,
        'booked' as status,
        CONCAT('Booked (Booking #', b.id, ')') as reason
    FROM bookings b
    CROSS JOIN (
        SELECT 0 as n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
        SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL 
        SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL 
        SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL 
        SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL 
        SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL 
        SELECT 28 UNION ALL SELECT 29 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL 
        SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL 
        SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL 
        SELECT 40 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL 
        SELECT 44 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL 
        SELECT 48 UNION ALL SELECT 49 UNION ALL SELECT 50 UNION ALL SELECT 51 UNION ALL 
        SELECT 52 UNION ALL SELECT 53 UNION ALL SELECT 54 UNION ALL SELECT 55 UNION ALL 
        SELECT 56 UNION ALL SELECT 57 UNION ALL SELECT 58 UNION ALL SELECT 59 UNION ALL 
        SELECT 60 UNION ALL SELECT 61 UNION ALL SELECT 62 UNION ALL SELECT 63 UNION ALL 
        SELECT 64 UNION ALL SELECT 65 UNION ALL SELECT 66 UNION ALL SELECT 67 UNION ALL 
        SELECT 68 UNION ALL SELECT 69 UNION ALL SELECT 70 UNION ALL SELECT 71 UNION ALL 
        SELECT 72 UNION ALL SELECT 73 UNION ALL SELECT 74 UNION ALL SELECT 75 UNION ALL 
        SELECT 76 UNION ALL SELECT 77 UNION ALL SELECT 78 UNION ALL SELECT 79 UNION ALL 
        SELECT 80 UNION ALL SELECT 81 UNION ALL SELECT 82 UNION ALL SELECT 83 UNION ALL 
        SELECT 84 UNION ALL SELECT 85 UNION ALL SELECT 86 UNION ALL SELECT 87 UNION ALL 
        SELECT 88 UNION ALL SELECT 89 UNION ALL SELECT 90
    ) n
    WHERE b.car_id = p_vehicle_id
        AND b.vehicle_type = p_vehicle_type
        AND b.status IN ('pending', 'approved', 'ongoing')
        AND DATE_ADD(b.pickup_date, INTERVAL n.n DAY) <= b.return_date
        AND DATE_ADD(b.pickup_date, INTERVAL n.n DAY) BETWEEN p_start_date AND p_end_date
    
    ORDER BY date;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `id` int(11) NOT NULL,
  `fullname` varchar(100) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `phone` varchar(11) NOT NULL,
  `profile_image` varchar(300) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`id`, `fullname`, `email`, `password`, `phone`, `profile_image`) VALUES
(1, 'cartney dejolde', 'cartney@gmail.com', '12345678', '09770433849', 'uploads/admin/admin_1_1770126911.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `admin_action_logs`
--

CREATE TABLE `admin_action_logs` (
  `id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `action_type` varchar(50) NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `admin_notifications`
--

CREATE TABLE `admin_notifications` (
  `id` int(11) NOT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `type` enum('booking','payment','verification','report','car','user','system') NOT NULL DEFAULT 'system',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `link` varchar(255) DEFAULT NULL,
  `icon` varchar(50) DEFAULT 'bi-bell',
  `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
  `read_status` enum('read','unread') DEFAULT 'unread',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin_notifications`
--

INSERT INTO `admin_notifications` (`id`, `admin_id`, `type`, `title`, `message`, `link`, `icon`, `priority`, `read_status`, `created_at`, `read_at`) VALUES
(1, NULL, 'system', 'Welcome to CarGo Admin', 'Notifications will appear here when there are new payments to verify, verifications to review, reports, and system alerts.', 'dashboard.php', 'bi-bell', 'low', 'read', '2026-02-10 13:55:26', '2026-02-10 13:56:07');

-- --------------------------------------------------------

--
-- Table structure for table `archived_notifications`
--

CREATE TABLE `archived_notifications` (
  `id` int(11) NOT NULL,
  `original_id` int(11) NOT NULL COMMENT 'Original notification ID',
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) DEFAULT 'info',
  `read_status` enum('read','unread') DEFAULT 'unread',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When notification was originally created',
  `archived_at` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'When notification was archived'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `car_id` int(11) NOT NULL,
  `vehicle_type` enum('car','motorcycle') NOT NULL,
  `car_image` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `contact` varchar(50) DEFAULT NULL,
  `gender` varchar(20) NOT NULL DEFAULT 'Male',
  `book_with_driver` tinyint(1) NOT NULL DEFAULT 0,
  `rental_period` varchar(50) NOT NULL DEFAULT 'Day',
  `needs_delivery` tinyint(1) DEFAULT 0,
  `delivery_address` varchar(500) DEFAULT NULL,
  `special_requests` text DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `rejected_at` timestamp NULL DEFAULT NULL,
  `pickup_date` date NOT NULL,
  `return_date` date NOT NULL,
  `actual_return_date` datetime DEFAULT NULL COMMENT 'Actual vehicle return date/time',
  `pickup_time` time NOT NULL,
  `trip_started_at` datetime DEFAULT NULL COMMENT 'Timestamp when owner confirmed vehicle pickup by renter',
  `return_time` time NOT NULL,
  `price_per_day` decimal(10,2) NOT NULL,
  `driver_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `status` enum('pending','approved','ongoing','rejected','completed','cancelled') NOT NULL DEFAULT 'pending',
  `trip_started` tinyint(1) DEFAULT 0 COMMENT 'Whether trip has started',
  `payment_status` enum('unpaid','paid','partial','refunded','pending','escrowed','released') DEFAULT 'unpaid',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `payment_id` int(11) DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `payment_date` timestamp NULL DEFAULT NULL,
  `rating` int(11) DEFAULT NULL,
  `cancellation_reason` text DEFAULT NULL,
  `cancelled_by` enum('renter','owner','admin') DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `gcash_number` varbinary(255) DEFAULT NULL,
  `gcash_reference` varbinary(255) DEFAULT NULL,
  `gcash_screenshot` varchar(255) DEFAULT NULL,
  `escrow_status` enum('pending','held','released_to_owner','refunded','released') DEFAULT 'pending',
  `platform_fee` decimal(10,2) DEFAULT 0.00,
  `owner_payout` decimal(10,2) DEFAULT 0.00,
  `payout_reference` varchar(100) DEFAULT NULL,
  `payout_date` timestamp NULL DEFAULT NULL,
  `escrow_held_at` datetime DEFAULT NULL,
  `escrow_released_at` datetime DEFAULT NULL,
  `payout_status` enum('pending','processing','completed','failed') DEFAULT 'pending',
  `payout_completed_at` datetime DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `payment_verified_at` datetime DEFAULT NULL,
  `payment_verified_by` int(11) DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `is_reviewed` tinyint(1) NOT NULL DEFAULT 0,
  `refund_requested` tinyint(1) DEFAULT 0,
  `refund_status` varchar(20) DEFAULT NULL,
  `refund_amount` decimal(10,2) DEFAULT 0.00,
  `escrow_refunded_at` datetime DEFAULT NULL,
  `escrow_hold_reason` varchar(100) DEFAULT NULL,
  `escrow_hold_details` text DEFAULT NULL,
  `overdue_status` enum('on_time','overdue','severely_overdue') DEFAULT 'on_time' COMMENT 'Current overdue status',
  `overdue_days` int(11) DEFAULT 0 COMMENT 'Number of days overdue',
  `late_fee_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'Calculated late fee',
  `late_fee_charged` tinyint(1) DEFAULT 0 COMMENT 'Whether late fee was charged',
  `overdue_detected_at` timestamp NULL DEFAULT NULL COMMENT 'When system first detected overdue',
  `extension_requested` tinyint(1) DEFAULT 0 COMMENT 'Renter requested extension',
  `extension_approved` tinyint(1) DEFAULT 0 COMMENT 'Extension was approved',
  `extended_return_date` date DEFAULT NULL COMMENT 'New return date if extended',
  `extension_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'Fee for extension',
  `late_fee_payment_status` enum('none','pending','paid','verified') DEFAULT 'none' COMMENT 'Status of late fee payment: none=no late fee, pending=submitted, paid=verified',
  `reminder_count` int(11) DEFAULT 0,
  `last_reminder_sent` datetime DEFAULT NULL,
  `late_fee_confirmed` tinyint(1) DEFAULT 0,
  `late_fee_confirmed_at` datetime DEFAULT NULL,
  `late_fee_confirmed_by` int(11) DEFAULT NULL,
  `late_fee_waived` tinyint(1) DEFAULT 0,
  `late_fee_waived_by` int(11) DEFAULT NULL,
  `late_fee_waived_at` datetime DEFAULT NULL,
  `late_fee_waived_reason` text DEFAULT NULL,
  `late_fee_adjusted` tinyint(1) DEFAULT 0,
  `late_fee_adjusted_by` int(11) DEFAULT NULL,
  `late_fee_adjusted_at` datetime DEFAULT NULL,
  `late_fee_adjustment_reason` text DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `odometer_start` int(11) DEFAULT NULL COMMENT 'Starting odometer reading in KM',
  `odometer_end` int(11) DEFAULT NULL COMMENT 'Ending odometer reading in KM',
  `odometer_start_photo` varchar(255) DEFAULT NULL COMMENT 'Photo of starting odometer',
  `odometer_end_photo` varchar(255) DEFAULT NULL COMMENT 'Photo of ending odometer',
  `odometer_start_timestamp` datetime DEFAULT NULL COMMENT 'When start odometer was recorded',
  `odometer_end_timestamp` datetime DEFAULT NULL COMMENT 'When end odometer was recorded',
  `actual_mileage` int(11) DEFAULT NULL COMMENT 'Calculated distance driven (end - start)',
  `allowed_mileage` int(11) DEFAULT NULL COMMENT 'Total allowed mileage for this booking',
  `excess_mileage` int(11) DEFAULT 0 COMMENT 'Mileage over limit (0 if within)',
  `excess_mileage_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'Excess mileage charge in PHP',
  `excess_mileage_paid` tinyint(1) DEFAULT 0 COMMENT '1 if excess fee paid',
  `mileage_verified_by` int(11) DEFAULT NULL COMMENT 'Admin ID who verified mileage',
  `mileage_verified_at` datetime DEFAULT NULL COMMENT 'When mileage was verified',
  `mileage_notes` text DEFAULT NULL COMMENT 'Notes about mileage (disputes, adjustments, etc.)',
  `gps_distance` decimal(10,2) DEFAULT NULL COMMENT 'Distance calculated from GPS tracking (KM)',
  `insurance_required` tinyint(1) DEFAULT 1 COMMENT 'Insurance is mandatory',
  `insurance_policy_id` int(11) DEFAULT NULL COMMENT 'Link to insurance policy',
  `insurance_premium` decimal(10,2) DEFAULT 0.00 COMMENT 'Insurance premium paid',
  `insurance_coverage_type` varchar(50) DEFAULT 'basic' COMMENT 'Type of coverage selected',
  `insurance_verified` tinyint(1) DEFAULT 0 COMMENT 'Policy verified and active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`id`, `user_id`, `owner_id`, `car_id`, `vehicle_type`, `car_image`, `location`, `full_name`, `email`, `contact`, `gender`, `book_with_driver`, `rental_period`, `needs_delivery`, `delivery_address`, `special_requests`, `approved_at`, `approved_by`, `rejection_reason`, `rejected_at`, `pickup_date`, `return_date`, `actual_return_date`, `pickup_time`, `trip_started_at`, `return_time`, `price_per_day`, `driver_fee`, `total_amount`, `status`, `trip_started`, `payment_status`, `created_at`, `updated_at`, `payment_id`, `payment_method`, `payment_date`, `rating`, `cancellation_reason`, `cancelled_by`, `cancelled_at`, `gcash_number`, `gcash_reference`, `gcash_screenshot`, `escrow_status`, `platform_fee`, `owner_payout`, `payout_reference`, `payout_date`, `escrow_held_at`, `escrow_released_at`, `payout_status`, `payout_completed_at`, `verified_at`, `payment_verified_at`, `payment_verified_by`, `verified_by`, `is_reviewed`, `refund_requested`, `refund_status`, `refund_amount`, `escrow_refunded_at`, `escrow_hold_reason`, `escrow_hold_details`, `overdue_status`, `overdue_days`, `late_fee_amount`, `late_fee_charged`, `overdue_detected_at`, `extension_requested`, `extension_approved`, `extended_return_date`, `extension_fee`, `late_fee_payment_status`, `reminder_count`, `last_reminder_sent`, `late_fee_confirmed`, `late_fee_confirmed_at`, `late_fee_confirmed_by`, `late_fee_waived`, `late_fee_waived_by`, `late_fee_waived_at`, `late_fee_waived_reason`, `late_fee_adjusted`, `late_fee_adjusted_by`, `late_fee_adjusted_at`, `late_fee_adjustment_reason`, `completed_at`, `odometer_start`, `odometer_end`, `odometer_start_photo`, `odometer_end_photo`, `odometer_start_timestamp`, `odometer_end_timestamp`, `actual_mileage`, `allowed_mileage`, `excess_mileage`, `excess_mileage_fee`, `excess_mileage_paid`, `mileage_verified_by`, `mileage_verified_at`, `mileage_notes`, `gps_distance`, `insurance_required`, `insurance_policy_id`, `insurance_premium`, `insurance_coverage_type`, `insurance_verified`) VALUES
(1, 7, 1, 26, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-13', '2025-12-14', NULL, '09:00:00', NULL, '05:00:00', 0.00, 0.00, 2100.00, 'completed', 0, 'unpaid', '2025-12-13 06:50:29', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, '', 48, 109900.00, 1, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'paid', 1, '2026-01-31 21:30:02', 1, '2026-01-31 21:29:56', 1, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-01-31 21:32:57', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 1, 252.00, 'basic', 1),
(2, 7, 1, 31, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-13', '2025-12-14', NULL, '09:00:00', NULL, '05:00:00', 0.00, 0.00, 1680.00, 'rejected', 0, 'unpaid', '2025-12-13 07:32:31', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(3, 7, 1, 31, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-13', '2025-12-14', NULL, '09:00:00', '2025-12-13 09:00:00', '05:00:00', 0.00, 0.00, 1680.00, 'approved', 0, 'unpaid', '2025-12-13 07:33:18', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 48, 109900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(4, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09128515463', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-18', '2025-12-19', NULL, '09:00:00', '2025-12-18 09:00:00', '05:00:00', 0.00, 0.00, 2100.00, 'approved', 0, 'unpaid', '2025-12-13 08:14:35', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 43, 99900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(5, 7, 1, 33, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2025-12-22', '2025-12-23', NULL, '09:00:00', NULL, '05:00:00', 0.00, 0.00, 1743.00, 'rejected', 0, 'pending', '2025-12-22 04:54:45', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 174.30, 1568.70, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(6, 11, 1, 33, 'car', NULL, NULL, 'Ethan James Estino', 'saberu1213@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-03', '2026-01-04', NULL, '09:00:00', NULL, '17:00:00', 830.00, 0.00, 1743.00, 'cancelled', 0, 'paid', '2026-01-03 13:01:25', '2026-02-06 06:18:27', 2, 'gcash', '2026-01-03 13:02:22', 0, 'Booking cancelled by user', NULL, '2026-01-05 02:26:13', 0x3039343531353437333438, 0x31323334353637383931323334, NULL, 'held', 174.30, 1568.70, NULL, NULL, '2026-01-03 21:41:07', NULL, 'pending', NULL, NULL, '2026-01-03 21:41:07', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(7, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-11', '2026-01-12', NULL, '09:00:00', NULL, '17:00:00', 122.00, 0.00, 256.20, 'cancelled', 0, 'paid', '2026-01-11 07:04:50', '2026-02-06 07:28:51', 4, 'gcash', '2026-01-11 07:05:05', 0, 'Escrow refunded - Reason: car_unavailable', NULL, '2026-02-06 07:28:51', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'refunded', 25.62, 230.58, NULL, NULL, '2026-01-21 10:45:08', NULL, 'pending', NULL, NULL, '2026-01-21 10:45:08', 1, NULL, 1, 0, NULL, 0.00, '2026-02-06 07:28:51', NULL, NULL, 'severely_overdue', 18, 55900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(8, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-12', '2026-01-13', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'rejected', 0, 'pending', '2026-01-12 02:41:48', '2026-02-08 04:22:30', 6, 'gcash', '2026-01-12 02:42:00', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(9, 7, 1, 26, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-12', '2026-01-13', NULL, '09:00:00', '2026-01-12 09:00:00', '17:00:00', 1000.00, 0.00, 2100.00, 'approved', 0, '', '2026-01-12 02:47:38', '2026-02-08 04:22:30', 8, 'gcash', '2026-01-12 02:47:52', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 17, 53900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(10, 7, 1, 31, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-12', '2026-01-13', NULL, '09:00:00', NULL, '17:00:00', 800.00, 0.00, 1680.00, 'rejected', 0, 'pending', '2026-01-12 05:38:38', '2026-02-08 04:22:30', 10, 'gcash', '2026-01-12 05:38:53', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(11, 7, 1, 33, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-12', '2026-01-13', NULL, '09:00:00', NULL, '17:00:00', 830.00, 0.00, 1743.00, 'rejected', 0, 'pending', '2026-01-12 08:54:57', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 174.30, 1568.70, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(14, 7, 1, 1, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-12', '2026-01-13', NULL, '09:00:00', NULL, '17:00:00', 800.00, 0.00, 1680.00, 'pending', 0, 'pending', '2026-01-12 10:45:21', '2026-02-08 04:22:30', 13, 'gcash', '2026-01-12 10:45:37', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(15, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', '2026-01-13 09:00:00', '17:00:00', 122.00, 0.00, 256.20, 'approved', 0, 'paid', '2026-01-12 23:14:35', '2026-02-07 02:19:47', 15, 'gcash', '2026-01-12 23:15:16', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 25.62, 230.58, NULL, NULL, '2026-01-21 10:47:34', NULL, 'pending', NULL, NULL, '2026-01-21 10:47:34', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 16, 51900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(16, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', '2026-01-13 09:00:00', '14:00:00', 122.00, 0.00, 256.20, 'approved', 0, 'paid', '2026-01-12 23:15:52', '2026-02-07 02:19:47', 17, 'gcash', '2026-01-12 23:16:15', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 25.62, 230.58, NULL, NULL, '2026-01-21 10:48:09', NULL, 'pending', NULL, NULL, '2026-01-21 10:48:09', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 17, 44200.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(17, 7, 1, 25, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'cancelled', 0, 'pending', '2026-01-13 02:03:58', '2026-02-08 04:22:30', 19, 'gcash', '2026-01-13 02:04:12', 0, 'Booking cancelled by user', NULL, '2026-01-21 00:13:37', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(18, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', NULL, '17:00:00', 122.00, 0.00, 1680.00, 'cancelled', 0, 'pending', '2026-01-13 05:26:16', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, 'Booking cancelled by user', NULL, '2026-01-21 00:10:34', NULL, NULL, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(19, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', '2026-01-13 09:00:00', '17:00:00', 122.00, 0.00, 1680.00, 'approved', 0, 'paid', '2026-01-13 05:26:39', '2026-02-07 02:19:47', 22, 'gcash', '2026-01-13 05:26:51', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 168.00, 1512.00, NULL, NULL, '2026-01-21 10:46:19', NULL, 'pending', NULL, NULL, '2026-01-21 10:46:19', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 16, 51900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(23, 7, 1, 35, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', '2026-01-13 09:00:00', '17:00:00', 800.00, 0.00, 1680.00, 'approved', 0, 'paid', '2026-01-13 07:24:40', '2026-02-08 04:22:30', 30, 'gcash', '2026-01-13 07:24:53', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 16, 51900.00, 1, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'paid', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(24, 7, 1, 2, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-13', '2026-01-14', NULL, '09:00:00', NULL, '17:00:00', 500.00, 0.00, 1050.00, 'rejected', 0, 'pending', '2026-01-13 07:25:16', '2026-02-08 04:22:30', 32, 'gcash', '2026-01-13 07:25:29', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 105.00, 945.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(25, 7, 1, 1, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770436849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-17', '2026-01-18', NULL, '09:00:00', NULL, '17:00:00', 800.00, 0.00, 1680.00, 'rejected', 0, 'paid', '2026-01-17 00:56:31', '2026-01-21 11:42:47', 34, 'gcash', '2026-01-17 00:56:45', 0, NULL, NULL, NULL, 0x3039373730343336383439, 0x31323334353637383930313233, NULL, 'held', 168.00, 1512.00, NULL, NULL, '2026-01-21 10:55:31', NULL, 'pending', NULL, NULL, '2026-01-21 10:55:31', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(26, 7, 1, 1, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-17', '2026-01-18', NULL, '09:00:00', NULL, '17:00:00', 800.00, 0.00, 1680.00, 'rejected', 0, 'pending', '2026-01-17 01:09:56', '2026-02-08 04:22:30', 36, 'gcash', '2026-01-17 01:10:17', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(27, 7, 1, 31, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-17', '2026-01-18', NULL, '09:00:00', NULL, '17:00:00', 800.00, 0.00, 1680.00, 'rejected', 0, 'pending', '2026-01-17 01:11:03', '2026-02-08 04:22:30', 38, 'gcash', '2026-01-17 01:11:13', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 168.00, 1512.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(28, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433846', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-24', '2026-01-25', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'cancelled', 0, 'paid', '2026-01-18 11:37:05', '2026-02-06 06:18:27', 40, 'gcash', '2026-01-18 11:37:19', 0, 'Booking cancelled by user', NULL, '2026-01-30 10:23:09', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-01-20 18:14:44', NULL, 'pending', NULL, NULL, '2026-01-20 18:14:44', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(29, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-20', '2026-01-21', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'cancelled', 0, 'pending', '2026-01-20 11:41:41', '2026-02-08 04:22:30', 42, 'gcash', '2026-01-20 11:41:53', 0, 'Booking cancelled by user', NULL, '2026-01-20 23:55:17', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 210.00, 1890.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(30, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-29', '2026-01-30', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'rejected', 0, 'paid', '2026-01-20 11:44:53', '2026-01-29 12:15:10', 44, 'gcash', '2026-01-20 11:45:03', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 210.00, 1890.00, NULL, NULL, '2026-01-21 10:54:30', NULL, 'pending', NULL, NULL, '2026-01-21 10:54:30', 1, NULL, 0, 1, 'completed', 2100.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(31, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-31', '2026-02-01', NULL, '09:00:00', '2026-01-31 09:00:00', '17:00:00', 1000.00, 0.00, 2100.00, 'approved', 0, 'paid', '2026-01-20 12:13:30', '2026-02-07 02:19:47', 46, 'gcash', '2026-01-20 12:13:42', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 210.00, 1890.00, NULL, NULL, '2026-01-21 10:01:57', NULL, 'pending', NULL, NULL, '2026-01-21 10:01:57', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(32, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-24', '2026-01-25', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'completed', 0, 'paid', '2026-01-20 12:45:29', '2026-02-08 04:22:30', 48, 'gcash', '2026-01-20 12:45:41', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'released_to_owner', 210.00, 1890.00, NULL, NULL, '2026-01-21 09:42:38', '2026-01-30 19:30:02', 'pending', NULL, NULL, '2026-01-21 09:42:38', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-01-30 11:30:02', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(33, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-25', '2026-01-26', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'completed', 0, 'pending', '2026-01-21 02:56:09', '2026-02-08 04:22:30', 50, 'gcash', '2026-01-21 02:56:25', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 315.00, 2835.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-02-08 04:22:30', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(34, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-27', '2026-01-28', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'completed', 0, 'pending', '2026-01-21 02:58:41', '2026-02-08 04:22:30', 52, 'gcash', '2026-01-21 02:58:54', 0, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'pending', 315.00, 2835.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-02-08 04:22:30', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(35, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-21', '2026-01-22', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'completed', 0, 'pending', '2026-01-21 03:07:11', '2026-02-08 04:22:30', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 315.00, 2835.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-02-08 04:22:30', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(36, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-21', '2026-01-22', NULL, '09:00:00', '2026-01-21 09:00:00', '17:00:00', 1500.00, 0.00, 3150.00, 'cancelled', 0, 'paid', '2026-01-21 03:07:11', '2026-02-11 08:45:40', 54, 'gcash', '2026-01-21 03:07:25', 0, 'Cancelled by renter', NULL, '2026-02-11 08:45:40', 0x3039373730343333383436, 0x31323334353637383930313233, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-01-22 09:17:46', NULL, 'pending', NULL, NULL, '2026-01-22 09:17:46', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'severely_overdue', 8, 35900.00, 0, '2026-01-30 13:07:54', 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(37, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-31', '2026-02-01', NULL, '09:00:00', '2026-01-31 09:00:00', '17:00:00', 1500.00, 0.00, 3150.00, 'cancelled', 0, 'paid', '2026-01-21 03:19:58', '2026-02-11 08:45:18', 56, 'gcash', '2026-01-21 03:20:13', 0, 'Cancelled by renter', NULL, '2026-02-11 08:45:18', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-01-21 11:54:28', NULL, 'pending', NULL, NULL, '2026-01-21 11:54:28', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(38, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433846', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-31', '2026-02-01', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'rejected', 0, 'paid', '2026-01-21 03:26:20', '2026-01-29 11:56:39', 58, 'gcash', '2026-01-21 03:26:39', NULL, NULL, NULL, NULL, 0x3039313233343536373839, 0x30393132333435363738393132, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-01-21 11:53:44', NULL, 'pending', NULL, NULL, '2026-01-21 11:53:44', 1, NULL, 0, 1, 'approved', 3150.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(39, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-28', '2026-01-29', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'completed', 0, 'paid', '2026-01-21 03:32:32', '2026-02-08 04:22:30', 60, 'gcash', '2026-01-21 03:32:45', NULL, NULL, NULL, NULL, 0x3039313233343536373839, 0x30393132333435363738393132, NULL, 'released_to_owner', 315.00, 2835.00, '1234567890909', NULL, '2026-01-21 11:52:31', '2026-01-30 19:29:59', 'completed', '2026-01-30 21:42:31', NULL, '2026-01-21 11:52:31', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-01-30 13:42:31', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(40, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-23', '2026-01-24', NULL, '09:00:00', NULL, '17:00:00', 1000.00, 0.00, 2100.00, 'cancelled', 0, 'paid', '2026-01-21 10:46:30', '2026-02-06 06:18:27', 62, 'gcash', '2026-01-21 10:46:46', NULL, 'Booking cancelled by user', NULL, '2026-01-24 07:16:37', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 210.00, 1890.00, NULL, NULL, '2026-01-24 15:16:37', NULL, 'pending', NULL, NULL, '2026-01-24 15:16:37', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(41, 7, 5, 17, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-31', '2026-01-31', NULL, '09:00:00', NULL, '13:33:18', 1000.00, 0.00, 30450.00, 'completed', 0, 'paid', '2026-01-21 10:51:43', '2026-02-08 02:22:12', 64, 'gcash', '2026-01-21 10:51:55', NULL, NULL, NULL, NULL, 0x3039313233343536373839, 0x30393132333435363738393132, NULL, 'released_to_owner', 3045.00, 27405.00, NULL, NULL, '2026-01-22 09:17:14', '2026-02-01 10:25:43', 'processing', NULL, NULL, '2026-01-22 09:17:14', 1, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, '', 0, 300.00, 1, '2026-01-31 08:33:19', 0, 0, NULL, 0.00, 'paid', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, '2026-01-31 21:33:24', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(42, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-29', '2026-01-30', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'rejected', 0, 'paid', '2026-01-29 11:53:36', '2026-01-30 10:39:56', 66, 'gcash', '2026-01-29 11:53:53', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-01-30 18:39:56', NULL, 'pending', NULL, NULL, '2026-01-30 18:39:56', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(43, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-29', '2026-01-30', NULL, '09:00:00', NULL, '17:00:00', 122.00, 0.00, 256.20, 'rejected', 0, 'paid', '2026-01-29 12:16:06', '2026-01-29 12:26:23', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'held', 25.62, 230.58, NULL, NULL, '2026-01-29 20:25:49', NULL, 'pending', NULL, NULL, '2026-01-29 20:25:49', 1, NULL, 0, 1, 'completed', 256.20, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(44, 7, 1, 34, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-01-29', '2026-01-30', NULL, '09:00:00', NULL, '17:00:00', 122.00, 0.00, 256.20, 'rejected', 0, 'paid', '2026-01-29 12:16:40', '2026-01-29 12:25:23', 69, 'gcash', '2026-01-29 12:16:57', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 25.62, 230.58, NULL, NULL, '2026-01-29 20:25:23', NULL, 'pending', NULL, NULL, '2026-01-29 20:25:23', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(45, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-01', '2026-02-02', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'pending', 0, 'paid', '2026-02-01 04:57:57', '2026-02-07 14:09:08', 91, 'gcash', '2026-02-01 04:58:13', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-02-07 14:09:08', NULL, 'pending', NULL, NULL, '2026-02-07 14:09:08', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(46, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-01', '2026-02-02', NULL, '09:00:00', NULL, '23:00:00', 1500.00, 0.00, 3150.00, 'pending', 0, 'paid', '2026-02-01 13:43:47', '2026-02-07 14:09:05', 93, 'gcash', '2026-02-01 13:44:05', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-02-07 14:09:05', NULL, 'pending', NULL, NULL, '2026-02-07 14:09:05', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(47, 15, 16, 6, 'motorcycle', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451547348', 'Male', 0, 'Monthly', 1, NULL, NULL, NULL, NULL, 'Payment verification failed', '2026-02-07 07:38:42', '2026-02-14', '2026-02-15', NULL, '09:00:00', NULL, '17:00:00', 500.00, 0.00, 1443.75, 'rejected', 0, '', '2026-02-06 02:07:38', '2026-02-07 07:38:42', 95, 'gcash', '2026-02-06 02:11:44', NULL, 'Cancelled by renter', NULL, '2026-02-06 04:32:42', 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'refunded', 144.38, 1299.37, NULL, NULL, '2026-02-06 03:05:05', NULL, 'pending', NULL, NULL, '2026-02-06 03:05:05', 1, NULL, 0, 1, 'completed', 1443.75, '2026-02-06 08:23:52', NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(48, 15, 16, 6, 'motorcycle', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, 'Payment verification failed', '2026-02-07 07:38:39', '2026-02-07', '2026-02-08', NULL, '10:31:00', '2026-02-07 02:48:21', '17:00:00', 500.00, 0.00, 1050.00, 'rejected', 0, '', '2026-02-07 02:24:42', '2026-02-07 07:38:39', 97, 'gcash', '2026-02-07 02:25:04', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 105.00, 945.00, NULL, NULL, '2026-02-07 02:25:39', NULL, 'pending', NULL, NULL, '2026-02-07 02:25:39', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 1, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(49, 15, 16, 6, 'motorcycle', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451517348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, 'Payment verification failed', '2026-02-07 07:38:35', '2026-02-07', '2026-02-08', NULL, '15:10:00', NULL, '17:00:00', 500.00, 0.00, 1050.00, 'rejected', 0, '', '2026-02-07 07:09:00', '2026-02-08 04:22:30', 99, 'gcash', '2026-02-07 07:09:17', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'pending', 105.00, 945.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(50, 15, 16, 6, 'motorcycle', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, 'Payment verification failed', '2026-02-07 07:45:49', '2026-02-07', '2026-02-08', NULL, '15:40:00', NULL, '17:00:00', 500.00, 0.00, 1050.00, 'rejected', 0, '', '2026-02-07 07:40:05', '2026-02-08 04:22:30', 101, 'gcash', '2026-02-07 07:40:29', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'pending', 105.00, 945.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(51, 15, 16, 6, 'motorcycle', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-07', '2026-02-08', NULL, '15:48:00', '2026-02-07 07:50:25', '17:00:00', 500.00, 0.00, 1050.00, 'completed', 0, 'paid', '2026-02-07 07:48:13', '2026-02-11 08:46:10', 103, 'gcash', '2026-02-07 07:48:31', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'released_to_owner', 105.00, 945.00, NULL, NULL, '2026-02-07 07:48:48', '2026-02-11 08:46:10', 'pending', NULL, NULL, '2026-02-07 07:48:48', 1, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 20400.00, 1, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 2, 126.00, 'basic', 1),
(52, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09', '2026-02-10', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'approved', 0, 'paid', '2026-02-09 11:29:11', '2026-02-11 08:59:49', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-02-11 08:59:31', NULL, 'pending', NULL, NULL, '2026-02-11 08:59:31', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 7, 378.00, 'basic', 1),
(53, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-28', '2026-03-01', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'pending', 0, 'paid', '2026-02-09 11:32:14', '2026-02-11 08:59:28', 106, 'gcash', '2026-02-09 11:32:25', NULL, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-02-11 08:59:28', NULL, 'pending', NULL, NULL, '2026-02-11 08:59:28', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0),
(54, 7, 16, 6, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Weekly', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09', '2026-02-10', NULL, '09:00:00', '2026-02-09 12:06:17', '17:00:00', 500.00, 0.00, 1050.00, 'completed', 0, 'paid', '2026-02-09 12:04:33', '2026-02-09 12:08:01', 108, 'gcash', '2026-02-09 12:04:41', NULL, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'released_to_owner', 105.00, 945.00, '1234567890123', NULL, '2026-02-09 12:05:12', '2026-02-09 12:07:49', 'completed', '2026-02-09 12:08:01', NULL, '2026-02-09 12:05:12', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 1, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 3, 126.00, 'basic', 1),
(55, 7, 16, 6, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-27', '2026-02-28', NULL, '09:00:00', NULL, '17:00:00', 500.00, 0.00, 1050.00, 'cancelled', 0, 'paid', '2026-02-09 12:09:25', '2026-02-09 12:13:55', 110, 'gcash', '2026-02-09 12:10:00', NULL, 'Cancelled by renter', NULL, '2026-02-09 12:13:02', 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'held', 105.00, 945.00, NULL, NULL, '2026-02-09 12:10:26', NULL, 'pending', NULL, NULL, '2026-02-09 12:10:26', 1, NULL, 0, 1, 'approved', 1050.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 4, 126.00, 'basic', 1),
(56, 7, 16, 6, 'motorcycle', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09770433849', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-09', '2026-02-10', NULL, '09:00:00', '2026-02-09 12:15:50', '17:00:00', 500.00, 0.00, 1050.00, 'completed', 0, 'paid', '2026-02-09 12:14:38', '2026-02-11 09:10:49', 112, 'gcash', '2026-02-09 12:14:49', NULL, NULL, NULL, NULL, 0x3039373730343333383439, 0x31323334353637383930313233, NULL, 'released_to_owner', 105.00, 945.00, '1212121212121', NULL, '2026-02-09 12:15:20', '2026-02-11 09:10:26', 'completed', '2026-02-11 09:10:49', NULL, '2026-02-09 12:15:20', 1, NULL, 1, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 1, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 5, 126.00, 'basic', 1),
(57, 15, 1, 37, 'car', NULL, NULL, 'Ethan james Estino', 'ethanjamesestino@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-15', '2026-02-16', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'approved', 0, 'paid', '2026-02-10 01:48:23', '2026-02-11 08:56:21', 114, 'gcash', '2026-02-10 01:48:38', NULL, NULL, NULL, NULL, 0x3039343531353437333438, 0x31323132313231323132313231, NULL, 'held', 315.00, 2835.00, NULL, NULL, '2026-02-11 08:55:56', NULL, 'pending', NULL, NULL, '2026-02-11 08:55:56', 1, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, 6, 378.00, 'basic', 1),
(58, 7, 1, 37, 'car', NULL, NULL, 'ethan jr', 'renter@gmail.com', '09451547348', 'Male', 0, 'Day', 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-20', '2026-02-21', NULL, '09:00:00', NULL, '17:00:00', 1500.00, 0.00, 3150.00, 'pending', 0, 'pending', '2026-02-11 11:22:01', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 0.00, 0.00, NULL, NULL, NULL, NULL, 'pending', NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 0.00, NULL, NULL, NULL, 'on_time', 0, 0.00, 0, NULL, 0, 0, NULL, 0.00, 'none', 0, NULL, 0, NULL, NULL, 0, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0.00, 0, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 'basic', 0);

--
-- Triggers `bookings`
--
DELIMITER $$
CREATE TRIGGER `trg_calculate_actual_mileage` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    -- Only calculate if both start and end are set, and actual hasn't been manually set
    IF NEW.odometer_start IS NOT NULL 
       AND NEW.odometer_end IS NOT NULL 
       AND NEW.odometer_end > NEW.odometer_start
       AND NEW.actual_mileage IS NULL THEN
        SET NEW.actual_mileage = NEW.odometer_end - NEW.odometer_start;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calculate_allowed_mileage` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    DECLARE v_daily_limit INT;
    DECLARE v_rental_days INT;
    
    -- Calculate rental days
    IF NEW.pickup_date IS NOT NULL AND NEW.return_date IS NOT NULL THEN
        SET v_rental_days = DATEDIFF(NEW.return_date, NEW.pickup_date) + 1;
        
        -- Get daily limit based on vehicle type
        IF NEW.vehicle_type = 'car' THEN
            SELECT daily_mileage_limit INTO v_daily_limit 
            FROM cars 
            WHERE id = NEW.car_id;
        ELSE
            SELECT daily_mileage_limit INTO v_daily_limit 
            FROM motorcycles 
            WHERE id = NEW.car_id;
        END IF;
        
        -- Calculate allowed mileage (NULL if unlimited)
        IF v_daily_limit IS NOT NULL THEN
            SET NEW.allowed_mileage = v_daily_limit * v_rental_days;
        ELSE
            SET NEW.allowed_mileage = NULL;
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calculate_excess_mileage` BEFORE UPDATE ON `bookings` FOR EACH ROW BEGIN
    DECLARE v_excess_rate DECIMAL(10,2);
    
    -- Only calculate if actual mileage is set and allowed is set
    IF NEW.actual_mileage IS NOT NULL AND NEW.allowed_mileage IS NOT NULL THEN
        -- Calculate excess mileage
        IF NEW.actual_mileage > NEW.allowed_mileage THEN
            SET NEW.excess_mileage = NEW.actual_mileage - NEW.allowed_mileage;
            
            -- Get excess rate
            IF NEW.vehicle_type = 'car' THEN
                SELECT excess_mileage_rate INTO v_excess_rate 
                FROM cars 
                WHERE id = NEW.car_id;
            ELSE
                SELECT excess_mileage_rate INTO v_excess_rate 
                FROM motorcycles 
                WHERE id = NEW.car_id;
            END IF;
            
            -- Calculate fee
            IF v_excess_rate IS NOT NULL THEN
                SET NEW.excess_mileage_fee = NEW.excess_mileage * v_excess_rate;
            END IF;
        ELSE
            SET NEW.excess_mileage = 0;
            SET NEW.excess_mileage_fee = 0.00;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cars`
--

CREATE TABLE `cars` (
  `id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `color` varchar(100) NOT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `car_year` varchar(50) NOT NULL,
  `body_style` varchar(200) DEFAULT NULL,
  `brand` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `trim` varchar(100) NOT NULL,
  `plate_number` varchar(30) DEFAULT NULL,
  `price_per_day` decimal(10,2) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `issues` varchar(255) DEFAULT 'None',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `advance_notice` varchar(100) DEFAULT NULL,
  `min_trip_duration` varchar(100) DEFAULT NULL,
  `max_trip_duration` varchar(100) DEFAULT NULL,
  `delivery_types` text DEFAULT NULL,
  `features` text DEFAULT NULL,
  `rules` text DEFAULT NULL,
  `has_unlimited_mileage` tinyint(1) DEFAULT 1,
  `mileage_limit` varchar(50) DEFAULT NULL,
  `daily_rate` decimal(10,2) DEFAULT 0.00,
  `unlimited_mileage` tinyint(1) DEFAULT 0,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `address` text DEFAULT NULL,
  `official_receipt` text DEFAULT NULL,
  `certificate_of_registration` text DEFAULT NULL,
  `extra_images` text DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `seat` int(11) DEFAULT 4,
  `status` enum('pending','approved','rejected','disabled') DEFAULT 'pending',
  `rating` float DEFAULT 5,
  `transmission` varchar(200) NOT NULL DEFAULT 'Automatic',
  `fuel_type` varchar(200) NOT NULL DEFAULT 'Gasoline',
  `report_count` int(11) DEFAULT 0,
  `daily_mileage_limit` int(11) DEFAULT NULL COMMENT 'Daily mileage limit in KM (NULL if unlimited)',
  `excess_mileage_rate` decimal(10,2) DEFAULT 10.00 COMMENT 'Cost per excess KM in PHP'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cars`
--

INSERT INTO `cars` (`id`, `owner_id`, `color`, `description`, `car_year`, `body_style`, `brand`, `model`, `trim`, `plate_number`, `price_per_day`, `image`, `location`, `issues`, `created_at`, `advance_notice`, `min_trip_duration`, `max_trip_duration`, `delivery_types`, `features`, `rules`, `has_unlimited_mileage`, `mileage_limit`, `daily_rate`, `unlimited_mileage`, `latitude`, `longitude`, `address`, `official_receipt`, `certificate_of_registration`, `extra_images`, `remarks`, `seat`, `status`, `rating`, `transmission`, `fuel_type`, `report_count`, `daily_mileage_limit`, `excess_mileage_rate`) VALUES
(3, 1, 'yellow', NULL, '2020', '4 setter', 'Audi', 'A3', '', '1234-5647', 600.00, 'uploads/car_1763279764.png', 'P1 Lapinigan ADS', 'None', '2025-11-16 07:43:16', NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, 0.00, 0, NULL, NULL, NULL, NULL, NULL, NULL, '', 0, 'approved', 5, '', '', 2, NULL, 10.00),
(16, 1, 'red', 'wow', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '12345', 2000.00, 'uploads/car_1763396591_4187.jpg', NULL, 'None', '2025-11-17 16:23:11', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\",\"Guest Pickup & Host Collection\"]', '[\"All-wheel drive\",\"Android auto\",\"AUX input\"]', '[\"No pets allowed\",\"No off-roading or driving through flooded areas\"]', 1, '0', 0.00, 0, 8.4312419, 125.9831042, '0', 'uploads/or_1763396591_3720.jpg', 'uploads/cr_1763396591_3812.jpg', '[]', '', 0, 'approved', 5, '', '', 0, NULL, 10.00),
(17, 5, 'ref', 'wee', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '123', 1000.00, 'uploads/car_1763430946_7051.jpg', NULL, 'None', '2025-11-18 01:55:46', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\",\"All-wheel drive\"]', '[\"No Littering\"]', 1, '0', 0.00, 0, 8.430187499999999, 125.98298439999998, '0', 'uploads/or_1763430946_2587.jpg', 'uploads/cr_1763430946_5849.jpg', '[]', '', 0, 'approved', 5, '', '', 1, NULL, 10.00),
(18, 5, 'black', 'wow', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '1233678900', 100.00, 'uploads/car_1763433044_8701.jpg', NULL, 'None', '2025-11-18 02:30:44', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\"]', '[\"Clean As You Go (CLAYGO)\"]', 1, '0', 0.00, 0, 8.429774758408513, 125.98353150875825, '0', 'uploads/or_1763433044_9642.jpg', 'uploads/cr_1763433044_9489.jpg', '[]', '', 0, 'rejected', 5, '', '', 0, NULL, 10.00),
(24, 8, 'red', 'wow', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '12334', 5000.00, 'uploads/car_1763532624_4856.jpg', NULL, 'None', '2025-11-19 06:10:24', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"All-wheel drive\",\"AUX input\"]', '[\"Clean As You Go (CLAYGO)\"]', 1, '0', 0.00, 0, 8.5104666, 125.9732381, '0', 'uploads/or_1763532624_2368.jpg', 'uploads/cr_1763532624_4208.jpg', '[]', '', 0, 'approved', 5, '', '', 0, NULL, 10.00),
(25, 1, 'red', 'wow', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '12344', 1000.00, 'uploads/car_1763534450_8284.jpg', NULL, 'None', '2025-11-19 06:40:50', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"Pet-friendly\",\"Keyless entry\"]', '[\"No vaping/smoking\",\"No pets allowed\"]', 1, '0', 0.00, 0, 8.5104666, 125.9732381, '0', 'uploads/or_1763534450_1401.jpg', 'uploads/cr_1763534450_6478.jpg', '[]', '', 0, 'approved', 5, '', '', 0, NULL, 10.00),
(26, 1, 'yellow', 'wow', '2025', '3-Door Hatchback', 'Audi', 'A1', 'N/A', '12234', 1000.00, 'uploads/car_1764057686_2758.jpg', NULL, 'None', '2025-11-25 08:01:26', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\"]', '[\"No Littering\"]', 1, '0', 0.00, 0, 8.5095913, 125.9726732, '0', 'uploads/or_1764057686_7059.jpg', 'uploads/cr_1764057686_8209.jpg', '[]', '', 0, 'approved', 5, '', '', 0, NULL, 10.00),
(28, 1, 'yellow', 'wow', '2017', 'Sedan', 'Toyota', 'Vios', 'Base', '051204', 500.00, 'uploads/car_1764161507_3067.jpg', NULL, 'None', '2025-11-26 12:51:47', '1 hour', '1', '1', '[\"Guest Pickup & Guest Return\"]', '[\"All-wheel drive\",\"AUX input\"]', '[\"Clean As You Go (CLAYGO)\"]', 1, '0', 0.00, 0, 8.4312419, 125.9831042, NULL, 'uploads/or_1764161507_8565.jpg', 'uploads/cr_1764161507_7810.jpg', '[]', '', 4, 'approved', 5, '', '', 0, NULL, 10.00),
(30, 1, 'black', 'wow', '2025', 'Crossover', 'Subaru', 'BRZ', 'Sport', '12345', 600.00, 'uploads/car_1764162427_5356.jpg', 'CXJM+G7X Lapinigan, San Francisco, Caraga', 'None', '2025-11-26 13:07:07', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\",\"All-wheel drive\"]', '[\"Clean As You Go (CLAYGO)\",\"No Littering\"]', 1, '0', 0.00, 0, 8.4312419, 125.9831042, NULL, 'uploads/or_1764162427_2393.jpg', 'uploads/cr_1764162427_5538.jpg', '[]', '', 4, 'approved', 5, '', '', 0, NULL, 10.00),
(31, 1, 'red', 'wow', '2025', 'Sedan', 'Toyota', 'Vios', 'N/A', '11234', 800.00, 'uploads/car_1764549818_8688.jpg', 'Purok 4, San Francisco, Caraga', 'None', '2025-12-01 00:43:38', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\",\"All-wheel drive\"]', '[\"Clean As You Go (CLAYGO)\"]', 1, '0', 0.00, 0, 8.4319398, 125.9830886, NULL, 'uploads/or_1764549818_5991.jpg', 'uploads/cr_1764549818_2590.jpg', '[]', '', 4, 'approved', 5, '', '', 0, NULL, 10.00),
(32, 1, 'blue', 'wow', '2025', 'Sedan', 'Toyota', 'Vios', 'Sport', '4566778', 900.00, 'uploads/car_1764549889_5758.jpg', 'Purok 4, San Francisco, Caraga', 'None', '2025-12-01 00:44:49', '1 hour', '1', '1', '[\"Guest Pickup & Guest Return\"]', '[\"All-wheel drive\"]', '[\"No eating or drinking inside\"]', 1, '0', 0.00, 0, 8.4319398, 125.9830886, NULL, 'uploads/or_1764549889_3847.jpg', 'uploads/cr_1764549889_1909.jpg', '[]', 'dont match', 4, 'rejected', 5, '', '', 0, NULL, 10.00),
(33, 1, 'yellow', 'wow', '2025', 'Sedan', 'Toyota', 'Vios', 'N/A', '09876544', 830.00, 'uploads/car_1765107943_3989.jpg', 'P2-Lapinigan, SFADS', 'None', '2025-12-07 11:45:43', '1 hour', '2', '1', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\"]', '[\"Clean As You Go (CLAYGO)\",\"No eating or drinking inside\"]', 1, '0', 0.00, 0, 8.430216699999999, 125.9751094, NULL, 'uploads/or_1765107943_9142.jpg', 'uploads/cr_1765107943_2706.jpg', '[]', '', 4, 'approved', 5, '', '', 0, NULL, 10.00),
(34, 1, 'red', 'a', '2025', 'Scooter', 'Honda', 'Click 125i', '100-125cc', '1', 122.00, 'uploads/car_1767582182_4309.jpg', '1600 Amphitheatre Pkwy, Mountain View, California', 'None', '2026-01-05 03:03:02', '1 hour', '1', '5', '[\"Guest Pickup & Guest Return\"]', '[\"ABS Brakes\"]', '[\"No Littering\"]', 1, '0', 0.00, 0, 37.4219983, -122.084, NULL, 'uploads/or_1767582182_1623.jpg', 'uploads/cr_1767582182_4905.jpg', '[]', '', 4, 'approved', 5, 'Automatic', 'Gasoline', 0, NULL, 10.00),
(35, 1, 'red', 'wee', '2025', 'Sedan', 'Toyota', 'Vios', 'N/A', '12345', 800.00, 'uploads/car_main_6962ff99bf708.jpg', 'CXJM+G7X, San Francisco, Caraga', 'None', '2026-01-11 01:40:41', '1 hour', '2 days', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"AUX input\"]', '[\"No Littering\"]', 1, NULL, 0.00, 0, 8.431944, 125.9831046, NULL, 'uploads/or_6962ff99c04bf.jpg', 'uploads/cr_6962ff99c0729.jpg', '[]', '', 4, 'approved', 5, 'Automatic', 'Gasoline', 2, NULL, 10.00),
(36, 1, 'yellow', 'wow', '2025', 'Sedan', 'Toyota', 'Vios', 'N/A', '167e8e9qoqe', 750.00, 'uploads/car_main_69632368c3936.jpg', 'Purok 4, San Francisco, Caraga', 'None', '2026-01-11 04:13:28', '1 hour', '2 days', '5 days', '[\"Guest Pickup & Guest Return\"]', '[\"All-wheel drive\"]', '[\"No Littering\"]', 1, NULL, 0.00, 0, 8.4324983, 125.9820836, NULL, 'uploads/or_69632368c498a.jpg', 'uploads/cr_69632368c4a95.jpg', '[]', NULL, 4, 'pending', 5, 'Automatic', 'Gasoline', 0, NULL, 10.00),
(37, 1, 'red', 'amazing', '2025', 'Sedan', 'Mercedes-Benz', 'A-Class', 'Base', '1463829192', 1500.00, 'uploads/car_main_696cb9e818fae.jpg', 'CXJM+G7X, San Francisco, Caraga', 'None', '2026-01-18 10:46:00', '1 hour', '2 days', '5 days', '[\"Guest Pickup & Guest Return\"]', '[\"All-wheel drive\",\"AUX input\"]', '[\"Clean As You Go (CLAYGO)\",\"No Littering\",\"No eating or drinking inside\"]', 1, NULL, 0.00, 0, 8.4319229, 125.9830948, NULL, 'uploads/or_696cb9e819155.jpg', 'uploads/cr_696cb9e819258.jpg', '[\"uploads\\/extra_696cb9e81934c.jpg\",\"uploads\\/extra_696cb9e81944f.jpg\",\"uploads\\/extra_696cb9e819536.jpg\"]', '', 4, 'approved', 5, 'Automatic', 'Gasoline', 4, NULL, 10.00);

-- --------------------------------------------------------

--
-- Table structure for table `car_photos`
--

CREATE TABLE `car_photos` (
  `id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `spot_number` int(11) NOT NULL,
  `label` varchar(100) NOT NULL,
  `image_path` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `car_ratings`
--

CREATE TABLE `car_ratings` (
  `id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` between 1 and 5),
  `review` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `car_rules`
--

CREATE TABLE `car_rules` (
  `id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `rule` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `escrow`
--

CREATE TABLE `escrow` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `payment_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('held','released','refunded') DEFAULT 'held',
  `held_at` datetime NOT NULL,
  `released_at` datetime DEFAULT NULL,
  `release_reason` text DEFAULT NULL,
  `refunded_at` datetime DEFAULT NULL,
  `refund_reason` text DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `escrow`
--

INSERT INTO `escrow` (`id`, `booking_id`, `payment_id`, `amount`, `status`, `held_at`, `released_at`, `release_reason`, `refunded_at`, `refund_reason`, `processed_by`, `created_at`, `updated_at`) VALUES
(3, 28, 40, 3150.00, 'held', '2026-01-20 17:54:53', NULL, NULL, NULL, NULL, 1, '2026-01-20 09:54:53', '2026-01-20 09:54:53'),
(5, 32, 48, 2100.00, 'released', '2026-01-21 09:42:13', '2026-01-30 19:30:02', 'Normal release - rental completed', NULL, NULL, 1, '2026-01-21 01:42:13', '2026-01-30 11:30:02'),
(7, 31, 46, 2100.00, 'held', '2026-01-21 09:52:05', NULL, NULL, NULL, NULL, 1, '2026-01-21 01:52:05', '2026-01-21 01:52:05'),
(9, 7, 4, 256.20, 'held', '2026-01-21 10:44:34', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:44:34', '2026-01-21 02:44:34'),
(11, 19, 22, 1680.00, 'held', '2026-01-21 10:46:19', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:46:19', '2026-01-21 02:46:19'),
(12, 15, 15, 256.20, 'held', '2026-01-21 10:47:34', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:47:34', '2026-01-21 02:47:34'),
(13, 16, 17, 256.20, 'held', '2026-01-21 10:48:09', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:48:09', '2026-01-21 02:48:09'),
(14, 30, 44, 2100.00, 'held', '2026-01-21 10:54:30', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:54:30', '2026-01-21 02:54:30'),
(15, 25, 34, 1680.00, 'held', '2026-01-21 10:55:18', NULL, NULL, NULL, NULL, 1, '2026-01-21 02:55:18', '2026-01-21 02:55:18'),
(17, 39, 60, 3150.00, 'released', '2026-01-21 11:52:28', '2026-01-30 21:42:31', 'Payout completed to owner', NULL, NULL, 1, '2026-01-21 03:52:28', '2026-01-30 13:42:31'),
(19, 38, 58, 3150.00, 'held', '2026-01-21 11:52:48', NULL, NULL, NULL, NULL, 1, '2026-01-21 03:52:48', '2026-01-21 03:52:48'),
(21, 37, 56, 3150.00, 'held', '2026-01-21 11:54:22', NULL, NULL, NULL, NULL, 1, '2026-01-21 03:54:22', '2026-01-21 03:54:22'),
(23, 41, 64, 30450.00, 'released', '2026-01-22 09:17:14', '2026-02-01 10:25:43', 'Rental completed successfully', NULL, NULL, 1, '2026-01-22 01:17:14', '2026-02-01 02:25:43'),
(24, 36, 54, 3150.00, 'held', '2026-01-22 09:17:46', NULL, NULL, NULL, NULL, 1, '2026-01-22 01:17:46', '2026-01-22 01:17:46'),
(25, 40, 62, 2100.00, 'held', '2026-01-24 15:16:37', NULL, NULL, NULL, NULL, 1, '2026-01-24 07:16:37', '2026-01-24 07:16:37'),
(26, 44, 69, 256.20, 'held', '2026-01-29 20:25:14', NULL, NULL, NULL, NULL, 1, '2026-01-29 12:25:14', '2026-01-29 12:25:14'),
(28, 43, 67, 256.20, 'held', '2026-01-29 20:25:49', NULL, NULL, NULL, NULL, 1, '2026-01-29 12:25:49', '2026-01-29 12:25:49'),
(29, 42, 66, 3150.00, 'held', '2026-01-30 18:39:56', NULL, NULL, NULL, NULL, 1, '2026-01-30 10:39:56', '2026-01-30 10:39:56'),
(32, 47, 95, 1443.75, 'held', '2026-02-06 03:05:05', NULL, NULL, NULL, NULL, 1, '2026-02-06 03:05:05', '2026-02-06 03:05:05'),
(33, 48, 97, 1050.00, 'held', '2026-02-07 02:25:39', NULL, NULL, NULL, NULL, 1, '2026-02-07 02:25:39', '2026-02-07 02:25:39'),
(34, 51, 103, 1050.00, 'released', '2026-02-07 07:48:48', '2026-02-11 08:46:10', 'Normal release - rental completed', NULL, NULL, 1, '2026-02-07 07:48:48', '2026-02-11 08:46:10'),
(35, 46, 93, 3150.00, 'held', '2026-02-07 14:09:05', NULL, NULL, NULL, NULL, 1, '2026-02-07 14:09:05', '2026-02-07 14:09:05'),
(36, 45, 91, 3150.00, 'held', '2026-02-07 14:09:08', NULL, NULL, NULL, NULL, 1, '2026-02-07 14:09:08', '2026-02-07 14:09:08'),
(37, 54, 108, 1050.00, 'released', '2026-02-09 12:05:12', '2026-02-09 12:08:01', 'Payout completed to owner', NULL, NULL, 1, '2026-02-09 12:05:12', '2026-02-09 12:08:01'),
(38, 55, 110, 1050.00, 'held', '2026-02-09 12:10:26', NULL, NULL, NULL, NULL, 1, '2026-02-09 12:10:26', '2026-02-09 12:10:26'),
(39, 56, 112, 1050.00, 'released', '2026-02-09 12:15:20', '2026-02-11 09:10:49', 'Payout completed to owner', NULL, NULL, 1, '2026-02-09 12:15:20', '2026-02-11 09:10:49'),
(40, 57, 114, 3150.00, 'held', '2026-02-11 08:55:56', NULL, NULL, NULL, NULL, 1, '2026-02-11 08:55:56', '2026-02-11 08:55:56'),
(41, 53, 106, 3150.00, 'held', '2026-02-11 08:59:28', NULL, NULL, NULL, NULL, 1, '2026-02-11 08:59:28', '2026-02-11 08:59:28'),
(42, 52, 104, 3150.00, 'held', '2026-02-11 08:59:31', NULL, NULL, NULL, NULL, 1, '2026-02-11 08:59:31', '2026-02-11 08:59:31');

-- --------------------------------------------------------

--
-- Table structure for table `escrow_logs`
--

CREATE TABLE `escrow_logs` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `action` enum('hold','release','refund','resume','verify') NOT NULL,
  `previous_status` varchar(50) DEFAULT NULL,
  `new_status` varchar(50) DEFAULT NULL,
  `admin_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `escrow_logs`
--

INSERT INTO `escrow_logs` (`id`, `booking_id`, `action`, `previous_status`, `new_status`, `admin_id`, `notes`, `created_at`) VALUES
(1, 39, 'release', 'held', 'released_to_owner', 1, 'Escrow released to owner', '2026-01-30 11:29:59'),
(2, 32, 'release', 'held', 'released_to_owner', 1, 'Escrow released to owner', '2026-01-30 11:30:02'),
(3, 7, 'refund', 'held', 'refunded', 1, 'Refunded to renter - Reason: car_unavailable - asdasd', '2026-02-06 07:28:51'),
(5, 1, '', 'none', 'complete', NULL, 'Escrow system migration completed successfully at 2026-02-08 04:25:29', '2026-02-08 04:25:29'),
(6, 54, 'release', 'held', 'released_to_owner', 1, 'Escrow released to owner', '2026-02-09 12:07:49'),
(7, 51, 'release', 'held', 'released_to_owner', 1, 'Escrow released to owner', '2026-02-11 08:46:10'),
(8, 56, 'release', 'held', 'released_to_owner', 1, 'Escrow released to owner', '2026-02-11 09:10:26');

-- --------------------------------------------------------

--
-- Table structure for table `escrow_transactions`
--

CREATE TABLE `escrow_transactions` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `transaction_type` enum('payment_received','payment_verified','funds_held','payout_to_owner','refund_to_renter') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `gcash_reference` varchar(100) DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL COMMENT 'Admin ID who processed',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `favorites`
--

CREATE TABLE `favorites` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `vehicle_type` enum('car','motorcycle') NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gps_distance_tracking`
--

CREATE TABLE `gps_distance_tracking` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `total_distance_km` decimal(10,2) DEFAULT 0.00 COMMENT 'Cumulative distance in KM',
  `last_latitude` double DEFAULT NULL,
  `last_longitude` double DEFAULT NULL,
  `last_updated` datetime DEFAULT NULL,
  `waypoints_count` int(11) DEFAULT 0 COMMENT 'Number of GPS points recorded',
  `calculation_method` varchar(50) DEFAULT 'haversine' COMMENT 'Distance calculation algorithm used',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `gps_locations`
--

CREATE TABLE `gps_locations` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `speed` decimal(5,2) DEFAULT NULL,
  `accuracy` decimal(6,2) DEFAULT NULL,
  `timestamp` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Dumping data for table `gps_locations`
--

INSERT INTO `gps_locations` (`id`, `booking_id`, `latitude`, `longitude`, `speed`, `accuracy`, `timestamp`) VALUES
(1, 52, 8.50926190, 125.97261860, 0.00, 10.44, '2026-02-11 09:01:05'),
(2, 52, 8.50926190, 125.97261860, 0.00, 37.35, '2026-02-11 09:01:17');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_audit_log`
--

CREATE TABLE `insurance_audit_log` (
  `id` int(11) NOT NULL,
  `policy_id` int(11) DEFAULT NULL,
  `claim_id` int(11) DEFAULT NULL,
  `action_type` varchar(50) NOT NULL,
  `action_by` int(11) DEFAULT NULL COMMENT 'User/Admin ID',
  `action_details` text DEFAULT NULL COMMENT 'JSON details',
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance_audit_log`
--

INSERT INTO `insurance_audit_log` (`id`, `policy_id`, `claim_id`, `action_type`, `action_by`, `action_details`, `ip_address`, `created_at`) VALUES
(1, NULL, 2, 'claim_rejected', 1, '{\"rejection_reason\":\"Insufficient evidence provided. Incident does not fall under policy coverage.\"}', NULL, '2026-02-01 12:35:36'),
(2, NULL, 2, 'claim_rejected', 1, '{\"rejection_reason\":\"Insufficient evidence provided. Incident does not fall under policy coverage.\"}', NULL, '2026-02-01 12:39:35'),
(3, NULL, 2, 'claim_rejected', 1, '{\"rejection_reason\":\"Insufficient evidence provided. Incident does not fall under policy coverage.\"}', NULL, '2026-02-01 12:45:12'),
(4, 1, NULL, 'policy_created', 7, '{\"coverage_type\":\"basic\",\"premium_amount\":252,\"policy_number\":\"INS-2026-000001-BAS\"}', NULL, '2026-02-01 12:57:45'),
(5, NULL, 1, 'claim_filed', 7, '{\"claim_type\":\"collision\",\"claimed_amount\":5000,\"claim_number\":\"CLM-2026-000001-9CE9\"}', NULL, '2026-02-01 13:02:04'),
(6, NULL, 1, 'claim_approved', 1, '{\"approved_amount\":4500,\"payout_amount\":0,\"review_notes\":\"Claim verified. Approved for payout after deductible.\"}', NULL, '2026-02-01 13:02:15'),
(7, NULL, 2, 'claim_rejected', 1, '{\"rejection_reason\":\"Insufficient evidence provided. Incident does not fall under policy coverage.\"}', NULL, '2026-02-01 13:02:17'),
(8, NULL, 2, 'claim_filed', 15, '{\"claim_type\":\"collision\",\"claimed_amount\":2000,\"claim_number\":\"CLM-2026-000051-E879\"}', NULL, '2026-02-07 07:54:59');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_claims`
--

CREATE TABLE `insurance_claims` (
  `id` int(11) NOT NULL,
  `claim_number` varchar(100) NOT NULL,
  `policy_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `claim_type` enum('collision','theft','liability','personal_injury','property_damage','other') NOT NULL,
  `incident_date` datetime NOT NULL,
  `incident_location` varchar(500) DEFAULT NULL,
  `incident_description` text NOT NULL,
  `police_report_number` varchar(100) DEFAULT NULL,
  `police_report_file` varchar(500) DEFAULT NULL,
  `claimed_amount` decimal(10,2) NOT NULL,
  `approved_amount` decimal(10,2) DEFAULT 0.00,
  `deductible_paid` decimal(10,2) DEFAULT 0.00,
  `payout_amount` decimal(10,2) DEFAULT 0.00,
  `evidence_photos` text DEFAULT NULL COMMENT 'JSON array of photo paths',
  `witness_statements` text DEFAULT NULL COMMENT 'JSON array of witness info',
  `damage_assessment` text DEFAULT NULL COMMENT 'JSON assessment details',
  `status` enum('submitted','under_review','approved','rejected','paid','closed') DEFAULT 'submitted',
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal',
  `reviewed_by` int(11) DEFAULT NULL COMMENT 'Admin/adjuster ID',
  `reviewed_at` datetime DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `paid_at` datetime DEFAULT NULL,
  `payout_reference` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance_claims`
--

INSERT INTO `insurance_claims` (`id`, `claim_number`, `policy_id`, `booking_id`, `user_id`, `claim_type`, `incident_date`, `incident_location`, `incident_description`, `police_report_number`, `police_report_file`, `claimed_amount`, `approved_amount`, `deductible_paid`, `payout_amount`, `evidence_photos`, `witness_statements`, `damage_assessment`, `status`, `priority`, `reviewed_by`, `reviewed_at`, `review_notes`, `rejection_reason`, `paid_at`, `payout_reference`, `created_at`, `updated_at`) VALUES
(1, 'CLM-2026-000001-9CE9', 1, 1, 7, 'collision', '2026-02-01 00:00:00', 'San Francisco, Caraga', 'Vehicle collision with another car during rental period. Front bumper and headlight damaged.', '', NULL, 5000.00, 4500.00, 0.00, 0.00, '[]', NULL, NULL, 'approved', 'normal', 1, '2026-02-01 21:02:15', 'Claim verified. Approved for payout after deductible.', NULL, NULL, NULL, '2026-02-01 13:02:04', '2026-02-01 13:02:15'),
(2, 'CLM-2026-000051-E879', 2, 51, 15, 'collision', '2026-02-07 15:51:33', 'brgy', 'bangaajsjsjsjsjsnsnsavvavahsb', NULL, NULL, 2000.00, 0.00, 0.00, 0.00, '[\"\\/data\\/user\\/0\\/com.example.flutter_application_1\\/cache\\/scaled_Screenshot_2026-02-07-11-09-00-77.jpg\"]', NULL, NULL, 'submitted', 'normal', NULL, NULL, NULL, NULL, NULL, NULL, '2026-02-07 07:54:59', '2026-02-07 07:54:59');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_coverage_types`
--

CREATE TABLE `insurance_coverage_types` (
  `id` int(11) NOT NULL,
  `coverage_name` varchar(100) NOT NULL,
  `coverage_code` varchar(50) NOT NULL,
  `description` text DEFAULT NULL,
  `base_premium_rate` decimal(5,4) NOT NULL COMMENT 'Rate as decimal (e.g., 0.12 = 12%)',
  `min_coverage_amount` decimal(10,2) DEFAULT 0.00,
  `max_coverage_amount` decimal(12,2) DEFAULT 0.00,
  `is_mandatory` tinyint(1) DEFAULT 0 COMMENT 'Required by law',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance_coverage_types`
--

INSERT INTO `insurance_coverage_types` (`id`, `coverage_name`, `coverage_code`, `description`, `base_premium_rate`, `min_coverage_amount`, `max_coverage_amount`, `is_mandatory`, `is_active`, `created_at`) VALUES
(1, 'Basic Coverage', 'BASIC', 'Covers third-party liability and basic collision damage up to ₱100,000', 0.1200, 50000.00, 100000.00, 1, 1, '2026-02-01 11:53:12'),
(2, 'Standard Coverage', 'STANDARD', 'Includes comprehensive collision, theft protection up to ₱300,000', 0.1800, 100000.00, 300000.00, 0, 1, '2026-02-01 11:53:12'),
(3, 'Premium Coverage', 'PREMIUM', 'Full coverage including personal injury protection up to ₱500,000', 0.2500, 300000.00, 500000.00, 0, 1, '2026-02-01 11:53:12'),
(4, 'Comprehensive Coverage', 'COMPREHENSIVE', 'Maximum protection including roadside assistance up to ₱1,000,000', 0.3500, 500000.00, 1000000.00, 0, 1, '2026-02-01 11:53:12');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_policies`
--

CREATE TABLE `insurance_policies` (
  `id` int(11) NOT NULL,
  `policy_number` varchar(100) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `vehicle_type` enum('car','motorcycle') NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT 'Renter',
  `owner_id` int(11) NOT NULL,
  `coverage_type` enum('basic','standard','premium','comprehensive') NOT NULL DEFAULT 'basic',
  `policy_start` datetime NOT NULL,
  `policy_end` datetime NOT NULL,
  `premium_amount` decimal(10,2) NOT NULL,
  `coverage_limit` decimal(12,2) NOT NULL COMMENT 'Maximum coverage amount',
  `deductible` decimal(10,2) DEFAULT 0.00 COMMENT 'Amount renter pays before insurance kicks in',
  `collision_coverage` decimal(10,2) DEFAULT 0.00 COMMENT 'Collision damage coverage',
  `liability_coverage` decimal(10,2) DEFAULT 0.00 COMMENT 'Third-party liability',
  `theft_coverage` decimal(10,2) DEFAULT 0.00 COMMENT 'Theft protection',
  `personal_injury_coverage` decimal(10,2) DEFAULT 0.00 COMMENT 'Personal injury protection',
  `roadside_assistance` tinyint(1) DEFAULT 0,
  `status` enum('active','expired','cancelled','claimed') DEFAULT 'active',
  `policy_document` varchar(500) DEFAULT NULL COMMENT 'Path to policy PDF',
  `terms_accepted` tinyint(1) DEFAULT 0,
  `terms_accepted_at` datetime DEFAULT NULL,
  `issued_at` datetime NOT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `cancellation_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance_policies`
--

INSERT INTO `insurance_policies` (`id`, `policy_number`, `provider_id`, `booking_id`, `vehicle_type`, `vehicle_id`, `user_id`, `owner_id`, `coverage_type`, `policy_start`, `policy_end`, `premium_amount`, `coverage_limit`, `deductible`, `collision_coverage`, `liability_coverage`, `theft_coverage`, `personal_injury_coverage`, `roadside_assistance`, `status`, `policy_document`, `terms_accepted`, `terms_accepted_at`, `issued_at`, `cancelled_at`, `cancellation_reason`, `created_at`, `updated_at`) VALUES
(1, 'INS-2026-000001-BAS', 1, 1, 'car', 26, 7, 1, '', '2025-12-13 00:00:00', '2025-12-14 00:00:00', 252.00, 100000.00, 5000.00, 50000.00, 50000.00, 0.00, 0.00, 0, 'claimed', NULL, 1, '2026-02-01 20:57:45', '2026-02-01 20:57:45', NULL, NULL, '2026-02-01 12:57:45', '2026-02-01 13:02:04'),
(2, 'POL-20260207-000051', 1, 51, 'motorcycle', 6, 15, 16, 'basic', '2026-02-07 00:00:00', '2026-02-08 00:00:00', 126.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'claimed', NULL, 1, NULL, '2026-02-07 07:49:53', NULL, NULL, '2026-02-07 07:49:53', '2026-02-07 08:49:56'),
(3, 'POL-20260209-000054', 1, 54, '', 6, 7, 16, 'basic', '2026-02-09 00:00:00', '2026-02-10 00:00:00', 126.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'active', NULL, 1, NULL, '2026-02-09 12:05:21', NULL, NULL, '2026-02-09 12:05:21', '2026-02-09 12:05:21'),
(4, 'POL-20260209-000055', 1, 55, '', 6, 7, 16, 'basic', '2026-02-27 00:00:00', '2026-02-28 00:00:00', 126.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'active', NULL, 1, NULL, '2026-02-09 12:10:42', NULL, NULL, '2026-02-09 12:10:42', '2026-02-09 12:10:42'),
(5, 'POL-20260209-000056', 1, 56, '', 6, 7, 16, 'basic', '2026-02-09 00:00:00', '2026-02-10 00:00:00', 126.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'active', NULL, 1, NULL, '2026-02-09 12:15:43', NULL, NULL, '2026-02-09 12:15:43', '2026-02-09 12:15:43'),
(6, 'POL-20260211-000057', 1, 57, '', 37, 15, 1, 'basic', '2026-02-15 00:00:00', '2026-02-16 00:00:00', 378.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'active', NULL, 1, NULL, '2026-02-11 08:56:21', NULL, NULL, '2026-02-11 08:56:21', '2026-02-11 08:56:21'),
(7, 'POL-20260211-000052', 1, 52, '', 37, 7, 1, 'basic', '2026-02-09 00:00:00', '2026-02-10 00:00:00', 378.00, 100000.00, 5000.00, 50000.00, 100000.00, 0.00, 0.00, 0, 'active', NULL, 1, NULL, '2026-02-11 08:59:49', NULL, NULL, '2026-02-11 08:59:49', '2026-02-11 08:59:49');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_providers`
--

CREATE TABLE `insurance_providers` (
  `id` int(11) NOT NULL,
  `provider_name` varchar(255) NOT NULL,
  `provider_code` varchar(50) NOT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `contact_phone` varchar(50) DEFAULT NULL,
  `license_number` varchar(100) NOT NULL COMMENT 'Insurance Commission License',
  `api_endpoint` varchar(500) DEFAULT NULL COMMENT 'API endpoint for integration',
  `api_key` varchar(255) DEFAULT NULL COMMENT 'Encrypted API key',
  `status` enum('active','inactive','suspended') DEFAULT 'active',
  `coverage_types` text DEFAULT NULL COMMENT 'JSON array of coverage types offered',
  `base_rate` decimal(10,2) DEFAULT 0.00 COMMENT 'Base rate percentage',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `insurance_providers`
--

INSERT INTO `insurance_providers` (`id`, `provider_name`, `provider_code`, `contact_email`, `contact_phone`, `license_number`, `api_endpoint`, `api_key`, `status`, `coverage_types`, `base_rate`, `created_at`, `updated_at`) VALUES
(1, 'Cargo Platform Insurance', 'CARGO_INS', 'insurance@cargo.ph', '+63-XXX-XXXX', 'IC-2025-XXXXX', NULL, NULL, 'active', NULL, 12.00, '2026-02-01 11:53:12', '2026-02-01 11:53:12');

-- --------------------------------------------------------

--
-- Table structure for table `late_fee_payments`
--

CREATE TABLE `late_fee_payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `late_fee_amount` decimal(10,2) NOT NULL,
  `rental_amount` decimal(10,2) DEFAULT 0.00 COMMENT 'Rental amount if not yet paid',
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL DEFAULT 'gcash',
  `payment_reference` varchar(100) DEFAULT NULL,
  `gcash_number` varchar(20) DEFAULT NULL,
  `payment_status` enum('pending','verified','paid','rejected','failed') DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `is_rental_paid` tinyint(1) DEFAULT 0 COMMENT '1 if rental already paid, 0 if paying rental + late fee',
  `hours_overdue` int(11) DEFAULT NULL,
  `days_overdue` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `payment_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mileage_disputes`
--

CREATE TABLE `mileage_disputes` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL COMMENT 'Renter who filed dispute',
  `owner_id` int(11) NOT NULL COMMENT 'Vehicle owner',
  `dispute_type` enum('incorrect_reading','odometer_tampered','calculation_error','photo_unclear','other') NOT NULL,
  `reported_odometer_start` int(11) DEFAULT NULL COMMENT 'Owner/system reported start',
  `reported_odometer_end` int(11) DEFAULT NULL COMMENT 'Owner/system reported end',
  `claimed_odometer_start` int(11) DEFAULT NULL COMMENT 'Renter claimed start',
  `claimed_odometer_end` int(11) DEFAULT NULL COMMENT 'Renter claimed end',
  `reported_mileage` int(11) NOT NULL COMMENT 'Mileage calculated by system',
  `claimed_mileage` int(11) NOT NULL COMMENT 'Mileage claimed by renter',
  `gps_distance` decimal(10,2) DEFAULT NULL COMMENT 'GPS-tracked distance for reference',
  `evidence_photos` text DEFAULT NULL COMMENT 'JSON array of additional photo paths',
  `description` text NOT NULL COMMENT 'Detailed explanation of dispute',
  `status` enum('pending','under_review','resolved_favor_renter','resolved_favor_owner','rejected','withdrawn') DEFAULT 'pending',
  `resolution` text DEFAULT NULL COMMENT 'Admin decision and explanation',
  `resolved_by` int(11) DEFAULT NULL COMMENT 'Admin ID who resolved',
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `mileage_logs`
--

CREATE TABLE `mileage_logs` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `log_type` enum('start_recorded','end_recorded','excess_calculated','excess_paid','dispute_filed','admin_verified','admin_adjusted') NOT NULL,
  `recorded_by` int(11) NOT NULL COMMENT 'User or admin ID',
  `recorded_by_type` enum('renter','owner','admin') NOT NULL,
  `odometer_value` int(11) DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `gps_latitude` double DEFAULT NULL,
  `gps_longitude` double DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `metadata` text DEFAULT NULL COMMENT 'JSON data: device info, timestamp, etc.',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `motorcycles`
--

CREATE TABLE `motorcycles` (
  `id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `color` varchar(100) NOT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `motorcycle_year` varchar(50) NOT NULL,
  `body_style` varchar(200) DEFAULT NULL,
  `brand` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `engine_displacement` varchar(100) NOT NULL,
  `plate_number` varchar(30) DEFAULT NULL,
  `price_per_day` decimal(10,2) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `advance_notice` varchar(100) DEFAULT NULL,
  `min_trip_duration` varchar(100) DEFAULT NULL,
  `max_trip_duration` varchar(100) DEFAULT NULL,
  `delivery_types` text DEFAULT NULL,
  `features` text DEFAULT NULL,
  `rules` text DEFAULT NULL,
  `has_unlimited_mileage` tinyint(1) DEFAULT 1,
  `daily_rate` decimal(10,2) DEFAULT 0.00,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `official_receipt` text DEFAULT NULL,
  `certificate_of_registration` text DEFAULT NULL,
  `extra_images` text DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `status` enum('pending','approved','rejected','disabled') DEFAULT 'pending',
  `rating` float DEFAULT 5,
  `transmission_type` enum('Manual','Automatic','Semi-Automatic') DEFAULT 'Manual',
  `report_count` int(11) DEFAULT 0,
  `daily_mileage_limit` int(11) DEFAULT NULL COMMENT 'Daily mileage limit in KM (NULL if unlimited)',
  `excess_mileage_rate` decimal(10,2) DEFAULT 10.00 COMMENT 'Cost per excess KM in PHP'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `motorcycles`
--

INSERT INTO `motorcycles` (`id`, `owner_id`, `color`, `description`, `motorcycle_year`, `body_style`, `brand`, `model`, `engine_displacement`, `plate_number`, `price_per_day`, `image`, `location`, `created_at`, `advance_notice`, `min_trip_duration`, `max_trip_duration`, `delivery_types`, `features`, `rules`, `has_unlimited_mileage`, `daily_rate`, `latitude`, `longitude`, `official_receipt`, `certificate_of_registration`, `extra_images`, `remarks`, `status`, `rating`, `transmission_type`, `report_count`, `daily_mileage_limit`, `excess_mileage_rate`) VALUES
(1, 1, 'red', 'wow', '2025', 'Scooter', 'Honda', 'Click 125i', '100-125cc', '12345', 800.00, 'uploads/motorcycle_main_69632406d1cc8.jpg', 'CXJM+G7X Lapinigan, San Francisco, Caraga', '2026-01-11 04:16:06', '1 hour', '2 days', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"Traction Control\"]', '[\"No vaping/smoking\"]', 1, 0.00, 8.4312419, 125.9831042, 'uploads/or_69632406d1f57.jpg', 'uploads/cr_69632406d200f.jpg', '[]', '', 'approved', 5, 'Manual', 0, NULL, 10.00),
(2, 1, 'black', 'wow', '2025', 'Standard/Naked', 'Honda', 'Wave 110', '100-125cc', '12345', 500.00, 'uploads/motorcycle_main_6963250d10290.jpg', 'p2 lapinigan', '2026-01-11 04:20:29', '1 hour', '2 days', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"Traction Control\",\"Riding Modes\"]', '[\"No eating or drinking inside\"]', 1, 0.00, 8.430216699999999, 125.9751094, 'uploads/or_6963250d103bc.jpg', 'uploads/cr_6963250d10473.jpg', '[\"uploads\\/extra_6963250d10511.jpg\",\"uploads\\/extra_6963250d105f0.jpg\"]', '', 'approved', 5, 'Manual', 0, NULL, 10.00),
(3, 1, 'blue', 'wew', '2025', 'Café Racer', 'CFMoto', '400NK', '100-125cc', '12345677', 750.00, 'uploads/motorcycle_main_696aec2843857.jpg', 'Purok 4, San Francisco, Caraga', '2026-01-17 01:55:52', '3 hours', '3 days', '2 weeks', '[\"Guest Pickup & Guest Return\"]', '[\"ABS Brakes\"]', '[\"No Littering\",\"No eating or drinking inside\"]', 1, 0.00, 8.432009, 125.9829288, 'uploads/or_696aec2843b36.jpg', 'uploads/cr_696aec2843c07.jpg', '[]', '', 'approved', 5, 'Manual', 0, NULL, 10.00),
(4, 5, 'red', 'wew', '2025', 'Touring', 'Kymco', 'Xciting 400i', '100-125cc', '987268191', 850.00, 'uploads/motorcycle_main_696aed424d965.jpg', 'P-2, San Francisco, Caraga', '2026-01-17 02:00:34', '1 hour', '2 days', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"Traction Control\",\"Riding Modes\"]', '[\"No Littering\",\"No eating or drinking inside\"]', 1, 0.00, 8.4317083, 125.9814032, 'uploads/or_696aed424dc70.jpg', 'uploads/cr_696aed424dd2e.jpg', '[]', '', 'approved', 5, 'Manual', 0, NULL, 10.00),
(5, 1, 'red', 'wt', '2025', 'Scooter', 'Honda', 'Click 125i', '100-125cc', 'rars', 50.00, NULL, 'Isetann Cinerama Complex, Manila, Metro Manila', '2026-02-02 12:10:23', '30 minutes', '1 day', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"ABS Brakes\"]', '[\"No Littering\"]', 1, 0.00, 14.60133824658561, 120.98485355139668, 'uploads/or_6980942f601e1.jpg', 'uploads/cr_6980942f604cc.jpg', '[\"uploads\\/extra_6980942f6080b.jpg\"]', NULL, 'pending', 5, 'Manual', 0, NULL, 10.00),
(6, 16, 'gtee', 'jayd', '2025', 'Scooter', 'Honda', 'Click 125i', '100-125cc', 're', 500.00, 'uploads/motorcycle_main_69854c0c24472.jpg', '904, Philippines', '2026-02-06 02:03:56', 'Others', '3 days', '1 week', '[\"Guest Pickup & Guest Return\"]', '[\"Cruise Control\",\"Quick Shifter\",\"ABS Brakes\",\"Traction Control\"]', '[\"No eating or drinking inside\",\"No inter-island travel\"]', 0, 0.00, 8.607775074226366, 125.90965140232585, 'uploads/or_69854c0c245d7.jpg', 'uploads/cr_69854c0c247b7.jpg', '[\"uploads\\/extra_69854c0c2496d.jpg\"]', '', 'approved', 5, 'Manual', 0, NULL, 10.00);

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) DEFAULT 'info',
  `read_status` enum('read','unread') DEFAULT 'unread',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `read_status`, `created_at`) VALUES
(1, 15, 'Payment Verified ✓', 'Your payment has been verified. Booking approved!', 'payment_verified', 'unread', '2026-02-11 08:55:56'),
(2, 1, 'New Booking 🚗', 'Booking #57 has been confirmed. Payment received.', 'booking_confirmed', 'unread', '2026-02-11 08:55:56'),
(3, 15, 'Booking Approved', 'Your booking for Mercedes-Benz A-Class (Car) has been approved. Your insurance policy is now active.', 'booking_approved', 'unread', '2026-02-11 08:56:21'),
(4, 1, 'You Approved a Booking', 'You approved booking #57 for Mercedes-Benz A-Class (Car).', 'booking_update', 'unread', '2026-02-11 08:56:21'),
(5, 7, 'Payment Verified ✓', 'Your payment has been verified. Booking approved!', 'payment_verified', 'unread', '2026-02-11 08:59:28'),
(6, 1, 'New Booking 🚗', 'Booking #53 has been confirmed. Payment received.', 'booking_confirmed', 'unread', '2026-02-11 08:59:28'),
(7, 7, 'Payment Verified ✓', 'Your payment has been verified. Booking approved!', 'payment_verified', 'unread', '2026-02-11 08:59:31'),
(8, 1, 'New Booking 🚗', 'Booking #52 has been confirmed. Payment received.', 'booking_confirmed', 'unread', '2026-02-11 08:59:31'),
(9, 7, 'Booking Approved', 'Your booking for Mercedes-Benz A-Class (Car) has been approved. Your insurance policy is now active.', 'booking_approved', 'unread', '2026-02-11 08:59:49'),
(10, 1, 'You Approved a Booking', 'You approved booking #52 for Mercedes-Benz A-Class (Car).', 'booking_update', 'unread', '2026-02-11 08:59:49'),
(11, 16, 'Payout Completed 💸', 'Your payout of ₱945.00 for booking #BK-0056 has been transferred to your GCash account. Reference: 1212121212121', 'info', 'unread', '2026-02-11 09:10:49');

-- --------------------------------------------------------

--
-- Table structure for table `overdue_logs`
--

CREATE TABLE `overdue_logs` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `days_overdue` int(11) NOT NULL,
  `hours_overdue` int(11) NOT NULL,
  `late_fee_charged` decimal(10,2) NOT NULL,
  `notification_sent` tinyint(1) DEFAULT 0,
  `action_taken` enum('notification','fee_charged','escalated','resolved','extended') NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Audit trail for overdue rentals';

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `code_hash` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `used` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

--
-- Dumping data for table `password_resets`
--

INSERT INTO `password_resets` (`id`, `user_id`, `email`, `code_hash`, `expires_at`, `used`, `created_at`) VALUES
(1, 19, 'caring@gmail.com', '$2y$10$jPTv3FRu1e8Vi.1KwKp0OuWBrgGSa3SYu6W.Rne.caV9Fg0xRjV1e', '2026-02-10 20:32:20', 0, '2026-02-10 12:17:20'),
(2, 13, 'saberu1213@gmail.com', '$2y$10$No02yShnIParCRH1Heda2eI5vjZEOcqR4LoLrN0Zw2N1uAOJJxh3K', '2026-02-10 20:54:38', 1, '2026-02-10 12:39:38');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) NOT NULL,
  `payment_reference` varchar(100) DEFAULT NULL,
  `payment_status` enum('pending','verified','paid','rejected','failed','released','refunded') DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `payment_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`id`, `booking_id`, `user_id`, `amount`, `payment_method`, `payment_reference`, `payment_status`, `verification_notes`, `verified_by`, `verified_at`, `created_at`, `updated_at`, `payment_date`) VALUES
(4, 7, 7, 256.20, 'gcash', '1234567890123', 'refunded', NULL, 1, '2026-01-21 10:44:34', '2026-01-11 07:05:05', '2026-02-06 07:28:51', NULL),
(15, 15, 7, 256.20, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 10:47:34', '2026-01-12 23:15:16', '2026-01-21 02:47:34', NULL),
(17, 16, 7, 256.20, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 10:48:09', '2026-01-12 23:16:15', '2026-01-21 02:48:09', NULL),
(22, 19, 7, 1680.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 10:46:19', '2026-01-13 05:26:51', '2026-01-21 02:46:19', NULL),
(34, 25, 7, 1680.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 10:55:18', '2026-01-17 00:56:45', '2026-01-21 02:55:18', NULL),
(40, 28, 7, 3150.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-20 17:54:53', '2026-01-18 11:37:19', '2026-01-20 09:54:53', NULL),
(44, 30, 7, 2100.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 10:54:30', '2026-01-20 11:45:03', '2026-01-21 02:54:30', NULL),
(46, 31, 7, 2100.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 09:52:05', '2026-01-20 12:13:42', '2026-01-21 01:52:05', NULL),
(48, 32, 7, 2100.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 09:42:13', '2026-01-20 12:45:41', '2026-01-21 01:42:13', NULL),
(54, 36, 7, 3150.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-22 09:17:46', '2026-01-21 03:07:25', '2026-01-22 01:17:46', NULL),
(56, 37, 7, 3150.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-21 11:54:22', '2026-01-21 03:20:13', '2026-01-21 03:54:22', NULL),
(58, 38, 7, 3150.00, 'gcash', '0912345678912', 'verified', NULL, 1, '2026-01-21 11:52:48', '2026-01-21 03:26:38', '2026-01-21 03:52:48', NULL),
(59, 39, 7, 3150.00, 'paymongo', 'pi_t1ozWc5giVXfHiZVofB54MQg', 'verified', NULL, 1, '2026-01-21 11:52:31', '2026-01-21 03:32:33', '2026-01-21 03:52:31', NULL),
(60, 39, 7, 3150.00, 'gcash', '0912345678912', 'verified', NULL, 1, '2026-01-21 11:52:28', '2026-01-21 03:32:45', '2026-01-21 03:52:28', NULL),
(62, 40, 7, 2100.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-01-24 15:16:37', '2026-01-21 10:46:46', '2026-01-24 07:16:37', NULL),
(63, 41, 7, 30450.00, 'paymongo', 'pi_jgtguhJmc9WarZh27bkqVLjp', 'rejected', 'Duplicate payment - Payment #64 was verified instead', NULL, NULL, '2026-01-21 10:51:44', '2026-01-31 09:56:41', NULL),
(64, 41, 7, 30450.00, 'gcash', '0912345678912', 'verified', NULL, 1, '2026-01-22 09:17:14', '2026-01-21 10:51:55', '2026-01-22 01:17:14', NULL),
(66, 42, 7, 3150.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-01-30 18:39:56', '2026-01-29 11:53:53', '2026-01-30 10:39:56', NULL),
(67, 43, 7, 256.20, 'gcash', NULL, 'verified', NULL, 1, '2026-01-29 20:25:49', '2026-01-29 12:16:06', '2026-01-29 12:25:49', NULL),
(69, 44, 7, 256.20, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-01-29 20:25:14', '2026-01-29 12:16:57', '2026-01-29 12:25:14', NULL),
(91, 45, 7, 3150.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-07 14:09:08', '2026-02-01 04:58:13', '2026-02-07 14:09:08', NULL),
(93, 46, 7, 3150.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-07 14:09:05', '2026-02-01 13:44:05', '2026-02-07 14:09:05', NULL),
(95, 47, 15, 1443.75, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-06 03:05:05', '2026-02-06 02:11:44', '2026-02-06 03:05:05', NULL),
(97, 48, 15, 1050.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-07 02:25:39', '2026-02-07 02:25:04', '2026-02-07 02:25:39', NULL),
(99, 49, 15, 1050.00, 'gcash', '1212121212121', 'rejected', 'Payment verification failed', 1, '2026-02-07 07:38:03', '2026-02-07 07:09:17', '2026-02-07 07:38:03', NULL),
(101, 50, 15, 1050.00, 'gcash', '1212121212121', 'rejected', 'Payment verification failed', 1, '2026-02-07 07:45:49', '2026-02-07 07:40:29', '2026-02-07 07:45:49', NULL),
(103, 51, 15, 1050.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-07 07:48:48', '2026-02-07 07:48:31', '2026-02-07 07:48:48', NULL),
(104, 52, 7, 3150.00, 'gcash', NULL, 'verified', NULL, 1, '2026-02-11 08:59:31', '2026-02-09 11:29:11', '2026-02-11 08:59:31', NULL),
(106, 53, 7, 3150.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-02-11 08:59:28', '2026-02-09 11:32:25', '2026-02-11 08:59:28', NULL),
(108, 54, 7, 1050.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-02-09 12:05:12', '2026-02-09 12:04:41', '2026-02-09 12:05:12', NULL),
(110, 55, 7, 1050.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-02-09 12:10:26', '2026-02-09 12:10:00', '2026-02-09 12:10:26', NULL),
(112, 56, 7, 1050.00, 'gcash', '1234567890123', 'verified', NULL, 1, '2026-02-09 12:15:20', '2026-02-09 12:14:49', '2026-02-09 12:15:20', NULL),
(114, 57, 15, 3150.00, 'gcash', '1212121212121', 'verified', NULL, 1, '2026-02-11 08:55:56', '2026-02-10 01:48:38', '2026-02-11 08:55:56', NULL),
(115, 58, 7, 3150.00, 'gcash', NULL, 'pending', NULL, NULL, NULL, '2026-02-11 11:22:01', '2026-02-11 11:22:01', NULL);

--
-- Triggers `payments`
--
DELIMITER $$
CREATE TRIGGER `trg_payment_verified_to_booking_paid` AFTER UPDATE ON `payments` FOR EACH ROW BEGIN
    -- Only run when status changes to verified
    IF NEW.payment_status = 'verified' 
       AND OLD.payment_status <> 'verified' THEN

        UPDATE bookings
        SET 
            payment_status = 'paid',
            payment_verified_at = NOW()
        WHERE id = NEW.booking_id;

    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `payments_incomplete_backup`
--

CREATE TABLE `payments_incomplete_backup` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `payment_reference` varchar(255) DEFAULT NULL,
  `payment_status` enum('pending','verified','rejected','processing','completed','failed','refunded') DEFAULT 'pending',
  `verification_notes` text DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `payment_date` datetime DEFAULT NULL,
  `deleted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deletion_reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payment_attempts`
--

CREATE TABLE `payment_attempts` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `attempt_count` int(11) DEFAULT 1,
  `last_attempt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `blocked_until` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payment_transactions`
--

CREATE TABLE `payment_transactions` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `transaction_type` enum('payment','escrow_hold','escrow_release','payout','refund') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` text NOT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payment_transactions`
--

INSERT INTO `payment_transactions` (`id`, `booking_id`, `transaction_type`, `amount`, `description`, `reference_id`, `metadata`, `created_by`, `created_at`) VALUES
(1, 57, 'payment', 3150.00, 'Payment verified via gcash', NULL, '{\"payment_id\":114,\"escrow_id\":40,\"platform_fee\":315,\"owner_payout\":2835}', 1, '2026-02-11 08:55:56'),
(2, 53, 'payment', 3150.00, 'Payment verified via gcash', NULL, '{\"payment_id\":106,\"escrow_id\":41,\"platform_fee\":315,\"owner_payout\":2835}', 1, '2026-02-11 08:59:28'),
(3, 52, 'payment', 3150.00, 'Payment verified via gcash', NULL, '{\"payment_id\":104,\"escrow_id\":42,\"platform_fee\":315,\"owner_payout\":2835}', 1, '2026-02-11 08:59:31'),
(4, 56, 'payout', 945.00, 'Payout completed to Lex Istaint. GCash ref: 1212121212121', NULL, '{\"payout_id\":2,\"transfer_reference\":\"1212121212121\",\"gcash_number\":\"09451547348\",\"proof_path\":null}', 1, '2026-02-11 09:10:49');

-- --------------------------------------------------------

--
-- Table structure for table `payment_transactions_deleted_backup`
--

CREATE TABLE `payment_transactions_deleted_backup` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `transaction_type` enum('payment','escrow_hold','escrow_release','payout','refund') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` text NOT NULL,
  `reference_id` varchar(255) DEFAULT NULL,
  `metadata` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deletion_reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payouts`
--

CREATE TABLE `payouts` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `escrow_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `platform_fee` decimal(10,2) NOT NULL,
  `net_amount` decimal(10,2) NOT NULL,
  `payout_method` varchar(50) DEFAULT 'gcash',
  `payout_account` varchar(100) DEFAULT NULL,
  `status` enum('pending','processing','completed','failed') DEFAULT 'pending',
  `scheduled_at` datetime NOT NULL,
  `processed_at` datetime DEFAULT NULL,
  `completion_reference` varchar(100) DEFAULT NULL,
  `failure_reason` text DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payouts`
--

INSERT INTO `payouts` (`id`, `booking_id`, `owner_id`, `escrow_id`, `amount`, `platform_fee`, `net_amount`, `payout_method`, `payout_account`, `status`, `scheduled_at`, `processed_at`, `completion_reference`, `failure_reason`, `processed_by`, `created_at`, `updated_at`) VALUES
(1, 51, 16, 34, 1050.00, 105.00, 945.00, 'gcash', '09451547348', 'pending', '2026-02-11 08:46:10', NULL, NULL, NULL, NULL, '2026-02-11 08:46:10', '2026-02-11 08:46:10'),
(2, 56, 16, 39, 1050.00, 105.00, 945.00, 'gcash', '09451547348', 'completed', '2026-02-11 09:10:26', '2026-02-11 09:10:49', '1212121212121', NULL, 1, '2026-02-11 09:10:26', '2026-02-11 09:10:49');

-- --------------------------------------------------------

--
-- Table structure for table `payout_requests`
--

CREATE TABLE `payout_requests` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `gcash_number` varchar(15) NOT NULL,
  `status` enum('pending','processing','completed','failed') DEFAULT 'pending',
  `payout_reference` varchar(100) DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL,
  `processed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `platform_settings`
--

CREATE TABLE `platform_settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `setting_type` varchar(50) DEFAULT 'string',
  `description` text DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `platform_settings`
--

INSERT INTO `platform_settings` (`id`, `setting_key`, `setting_value`, `setting_type`, `description`, `updated_by`, `updated_at`, `created_at`) VALUES
(1, 'platform_commission_rate', '10', 'decimal', 'Platform commission percentage (e.g., 10 for 10%)', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(2, 'escrow_release_days', '3', 'integer', 'Days to hold payment in escrow after rental completion', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(3, 'gcash_account_number', '09123456789', 'string', 'Platform GCash account for receiving payments', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(4, 'gcash_account_name', 'CarGO Rentals', 'string', 'Platform GCash account name', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(5, 'minimum_payout_amount', '100', 'decimal', 'Minimum amount required for payout processing', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(6, 'auto_payout_enabled', 'true', 'boolean', 'Enable automatic payout processing after escrow release', NULL, '2025-12-15 02:18:11', '2025-12-15 02:18:11'),
(7, 'late_fee_enabled', '1', 'boolean', 'Enable automatic late fee charging', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(8, 'late_fee_grace_hours', '2', 'integer', 'Grace period in hours before late fees start', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(9, 'late_fee_tier1_rate', '300', 'decimal', 'Hourly rate for 2-6 hours late (PHP)', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(10, 'late_fee_tier2_rate', '500', 'decimal', 'Hourly rate for 6-24 hours late (PHP)', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(11, 'late_fee_tier3_rate', '2000', 'decimal', 'Daily rate for 1+ days late (PHP)', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(12, 'overdue_notification_enabled', '1', 'boolean', 'Send automated overdue notifications', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(13, 'extension_enabled', '1', 'boolean', 'Allow renters to request extensions', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(14, 'extension_max_days', '7', 'integer', 'Maximum days per extension request', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(15, 'extension_rush_fee_percent', '20', 'integer', 'Additional % for last-minute extensions', NULL, '2026-01-30 13:02:18', '2026-01-30 12:59:31'),
(17, 'mileage_tracking_enabled', '1', 'boolean', 'Enable mileage tracking system', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(18, 'default_daily_mileage_limit', '200', 'integer', 'Default daily mileage limit in KM', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(19, 'default_excess_rate', '10.00', 'decimal', 'Default excess mileage rate per KM', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(20, 'gps_distance_tracking_enabled', '1', 'boolean', 'Enable GPS-based distance calculation', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(21, 'odometer_photo_required', '1', 'boolean', 'Require photos of odometer readings', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(22, 'mileage_discrepancy_threshold', '20', 'integer', 'Max % difference between GPS and odometer before flagging', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01'),
(23, 'auto_verify_mileage', '0', 'boolean', 'Auto-verify if GPS and odometer match within threshold', NULL, '2026-02-01 07:33:01', '2026-02-01 07:33:01');

-- --------------------------------------------------------

--
-- Table structure for table `receipts`
--

CREATE TABLE `receipts` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `receipt_no` varchar(50) NOT NULL,
  `receipt_path` varchar(255) DEFAULT NULL,
  `receipt_url` varchar(500) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'generated',
  `generated_at` datetime DEFAULT current_timestamp(),
  `emailed_at` datetime DEFAULT NULL,
  `email_count` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `refunds`
--

CREATE TABLE `refunds` (
  `id` int(11) NOT NULL,
  `refund_id` varchar(50) DEFAULT NULL,
  `booking_id` int(11) NOT NULL,
  `payment_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `refund_amount` decimal(10,2) NOT NULL,
  `original_amount` decimal(10,2) DEFAULT NULL,
  `refund_method` varchar(50) NOT NULL,
  `account_number` varchar(255) NOT NULL,
  `account_name` varchar(255) NOT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `refund_reason` varchar(100) NOT NULL,
  `reason_details` text DEFAULT NULL,
  `original_payment_method` varchar(50) DEFAULT NULL,
  `original_payment_reference` varchar(255) DEFAULT NULL,
  `status` varchar(50) DEFAULT 'pending',
  `processed_by` int(11) DEFAULT NULL,
  `processed_at` datetime DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `completion_reference` varchar(255) DEFAULT NULL,
  `refund_reference` varchar(100) DEFAULT NULL,
  `transfer_proof` varchar(255) DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `deduction_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `deduction_reason` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rental_extensions`
--

CREATE TABLE `rental_extensions` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `requested_by` int(11) NOT NULL COMMENT 'User ID who requested',
  `original_return_date` date NOT NULL,
  `requested_return_date` date NOT NULL,
  `extension_days` int(11) NOT NULL,
  `extension_fee` decimal(10,2) NOT NULL,
  `reason` text DEFAULT NULL COMMENT 'Reason for extension request',
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `approved_by` int(11) DEFAULT NULL COMMENT 'Owner/admin who approved',
  `approval_reason` text DEFAULT NULL COMMENT 'Reason for approval/rejection',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Rental extension requests';

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `id` int(11) NOT NULL,
  `reporter_id` int(11) NOT NULL,
  `report_type` enum('car','motorcycle','user','booking','chat') NOT NULL,
  `reported_id` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `details` text DEFAULT NULL,
  `status` enum('pending','under_review','resolved','dismissed') DEFAULT 'pending',
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `reviewed_by` int(11) DEFAULT NULL,
  `admin_notes` text DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `image_path` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reports`
--

INSERT INTO `reports` (`id`, `reporter_id`, `report_type`, `reported_id`, `reason`, `details`, `status`, `priority`, `reviewed_by`, `admin_notes`, `review_notes`, `reviewed_at`, `created_at`, `updated_at`, `image_path`) VALUES
(1, 7, 'car', 34, 'Fake photos', 'pangit ka bonding', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-17 11:07:30', '2026-01-20 18:36:26', NULL),
(2, 7, 'car', 33, 'Vehicle not as described', 'not as described', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-17 11:15:17', '2026-01-20 18:36:26', NULL),
(5, 7, 'motorcycle', 2, 'Suspicious pricing', 'overpriced', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-17 11:36:10', '2026-01-20 18:36:26', NULL),
(6, 7, 'user', 1, 'Fake profile', 'fake', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-17 17:45:35', '2026-01-20 18:36:26', NULL),
(7, 7, 'user', 1, 'Suspicious activity', 'suspended', 'pending', 'high', NULL, NULL, NULL, NULL, '2026-01-20 15:00:12', '2026-01-20 20:07:29', NULL),
(8, 7, 'car', 35, 'Suspicious pricing', 'suspek okahshakakajhahahq', 'under_review', 'medium', 1, '', NULL, '2026-01-20 20:05:56', '2026-01-20 19:27:34', '2026-01-20 20:05:56', NULL),
(9, 7, 'car', 37, 'Fake photos', 'fake srthuuhhhhhhhggh', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-20 20:25:17', '2026-01-20 20:25:17', NULL),
(10, 7, 'car', 17, 'Fake photos', 'gggggggggggggggggggg', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-20 20:34:00', '2026-01-20 20:34:00', NULL),
(11, 7, 'car', 3, 'Misleading information', 'gghjkkjhffhjkkkkjjhhjj', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-01-21 17:55:00', '2026-01-21 17:55:00', 'uploads/reports/report_6970a27414316.jpg'),
(12, 7, 'car', 37, 'Vehicle not as described', 'blaaballaahajajakajajaj', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-02-09 12:24:09', '2026-02-09 12:24:09', 'uploads/reports/report_6989d1e900aa8.jpg'),
(14, 1, 'car', 3, 'Misleading information', 'This is a test report submission to verify that the reporting system is working correctly. The details must be at least 20 characters long.', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-02-09 14:52:02', '2026-02-09 14:52:02', NULL),
(15, 15, 'car', 37, 'Misleading information', 'hshshahahahahahhahahaha', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-02-10 01:53:12', '2026-02-10 01:53:12', 'uploads/reports/report_698a8f8872870.jpg'),
(16, 7, 'car', 35, 'Misleading information', 'asdadasdasdsadasdasdasd', 'resolved', 'medium', 1, 'alright', NULL, '2026-02-10 05:53:40', '2026-02-10 03:08:49', '2026-02-10 05:53:40', NULL),
(17, 19, 'car', 37, 'Misleading information', 'etjegjegksgkegkegkegjsg', 'pending', 'medium', NULL, NULL, NULL, NULL, '2026-02-10 05:50:06', '2026-02-10 05:50:06', 'uploads/reports/report_698ac70e328bc.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `report_logs`
--

CREATE TABLE `report_logs` (
  `id` int(11) NOT NULL,
  `report_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `performed_by` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `report_logs`
--

INSERT INTO `report_logs` (`id`, `report_id`, `action`, `performed_by`, `notes`, `created_at`) VALUES
(1, 8, 'created', 7, 'Report submitted by user', '2026-01-20 19:27:34'),
(2, 8, 'status_changed_to_under_review', 1, '', '2026-01-20 20:05:56'),
(3, 7, 'priority_changed', 1, 'Priority changed to high', '2026-01-20 20:07:29'),
(4, 9, 'created', 7, 'Report submitted by user', '2026-01-20 20:25:17'),
(5, 10, 'created', 7, 'Report submitted by user', '2026-01-20 20:34:00'),
(6, 11, 'created', 7, 'Report submitted by user', '2026-01-21 17:55:00'),
(7, 12, 'created', 7, 'Report submitted by user', '2026-02-09 12:24:09'),
(9, 14, 'created', 1, 'Report submitted by user', '2026-02-09 14:52:02'),
(10, 15, 'created', 15, 'Report submitted by user', '2026-02-10 01:53:12'),
(11, 16, 'created', 7, 'Report submitted by user', '2026-02-10 03:08:49'),
(12, 16, 'status_changed_to_under_review', 1, '', '2026-02-10 03:50:27'),
(13, 17, 'created', 19, 'Report submitted by user', '2026-02-10 05:50:06'),
(14, 16, 'status_changed_to_resolved', 1, 'alright', '2026-02-10 05:53:40');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `car_id` int(11) NOT NULL,
  `renter_id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `rating` decimal(3,1) NOT NULL,
  `review` text NOT NULL,
  `categories` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`categories`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `booking_id`, `car_id`, `renter_id`, `owner_id`, `rating`, `review`, `categories`, `created_at`) VALUES
(1, 10, 31, 7, 1, 4.4, 'CAR REVIEW:\nExactly as described\n\nOWNER REVIEW:\nGreat communication', '{\"car_rating\":4.8,\"owner_rating\":4,\"car\":{\"Cleanliness\":4,\"Condition\":5,\"Accuracy\":5,\"Value\":5},\"owner\":{\"Communication\":4,\"Responsiveness\":4,\"Friendliness\":4}}', '2026-01-13 02:28:06'),
(2, 10, 31, 7, 1, 4.9, 'CAR REVIEW:\nVery clean and well-maintained\n\nOWNER REVIEW:\nGreat communication', '{\"car_rating\":5,\"owner_rating\":4.7,\"car\":{\"Cleanliness\":5,\"Condition\":5,\"Accuracy\":5,\"Value\":5},\"owner\":{\"Communication\":4,\"Responsiveness\":5,\"Friendliness\":5}}', '2026-01-13 02:37:51'),
(3, 11, 33, 7, 1, 4.4, 'CAR REVIEW:\nExactly as described\n\nOWNER REVIEW:\nGreat communication', '{\"car_rating\":4.5,\"owner_rating\":4.3,\"car\":{\"Cleanliness\":4,\"Condition\":4,\"Accuracy\":5,\"Value\":5},\"owner\":{\"Communication\":5,\"Responsiveness\":4,\"Friendliness\":4}}', '2026-01-17 03:59:28'),
(4, 41, 17, 7, 5, 3.6, 'CAR REVIEW:\nGreat car and excellent condition!\n\nOWNER REVIEW:\nGreat communication', '{\"car_rating\":3.5,\"owner_rating\":3.7,\"car\":{\"Cleanliness\":4,\"Condition\":3,\"Accuracy\":4,\"Value\":3},\"owner\":{\"Communication\":3,\"Responsiveness\":4,\"Friendliness\":4}}', '2026-02-08 02:22:12'),
(5, 56, 6, 7, 16, 4.0, 'CAR REVIEW:\nGreat car and excellent condition!\n\nOWNER REVIEW:\nGreat communication', '{\"car_rating\":4,\"owner_rating\":4,\"car\":{\"Cleanliness\":4,\"Condition\":4,\"Accuracy\":4,\"Value\":4},\"owner\":{\"Communication\":4,\"Responsiveness\":4,\"Friendliness\":4}}', '2026-02-09 12:22:48'),
(6, 51, 6, 15, 16, 3.3, 'CAR REVIEW:\nGreat car and excellent condition!\n\nOWNER REVIEW:\naccff', '{\"car_rating\":4.5,\"owner_rating\":2,\"car\":{\"Cleanliness\":5,\"Condition\":5,\"Accuracy\":5,\"Value\":3},\"owner\":{\"Communication\":2,\"Responsiveness\":2,\"Friendliness\":2}}', '2026-02-10 01:32:19');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `fullname` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `facebook_id` varchar(100) DEFAULT NULL,
  `google_uid` varchar(255) DEFAULT NULL,
  `auth_provider` enum('email','google','facebook') DEFAULT 'email',
  `password` varchar(255) NOT NULL,
  `role` enum('Owner','Renter') DEFAULT NULL,
  `municipality` varchar(200) NOT NULL,
  `address` varchar(50) NOT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `profile_image` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  `fcm_token` text DEFAULT NULL,
  `gcash_number` varchar(15) DEFAULT NULL,
  `gcash_name` varchar(100) DEFAULT NULL,
  `report_count` int(11) DEFAULT 0,
  `api_token` varchar(255) DEFAULT NULL,
  `is_online` tinyint(1) DEFAULT 0 COMMENT 'Current online status',
  `last_seen` timestamp NULL DEFAULT NULL COMMENT 'Last time user was seen online'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `fullname`, `email`, `facebook_id`, `google_uid`, `auth_provider`, `password`, `role`, `municipality`, `address`, `phone`, `profile_image`, `created_at`, `last_login`, `fcm_token`, `gcash_number`, `gcash_name`, `report_count`, `api_token`, `is_online`, `last_seen`) VALUES
(1, 'Cartney Dejolde jr', 'cart@gmail.com', NULL, NULL, 'email', '12345', 'Owner', '', 'Lapinigan SFADS', '09770433849', 'user_1_1768732059.jpg', '2025-11-12 11:38:49', '2026-02-11 08:51:05', NULL, '09770433849', 'Cartney Dejolde', 0, 'MXwxNzcwNzk5ODY1', 0, NULL),
(3, 'cartney dejolde', 'cartskie@gmail.com', NULL, NULL, 'email', '12345', 'Owner', '', 'lapinigan', '097712345', 'profile_3_1763342696.jpg', '2025-11-12 12:03:33', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(4, 'kristian', 'kristian@gmail.com', NULL, NULL, 'email', '12345', 'Renter', '', 'Pasta SFADS', '09770433849', 'user_4_1765375801.jpg', '2025-11-13 06:58:26', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(5, 'ethan', 'ethan@gmail.com', NULL, NULL, 'email', '12345', 'Owner', '', 'san Francisco ADS', '0123456789', 'user_5_1769045131.jpg', '2025-11-13 23:47:33', '2026-02-11 08:50:29', NULL, NULL, NULL, 0, 'NXwxNzcwNzk5ODI5', 0, NULL),
(6, 'Johan Malanog', 'johan@gmail.com', NULL, NULL, 'email', '12345', 'Owner', '', '', NULL, NULL, '2025-11-16 03:29:43', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(7, 'ethan jr', 'renter@gmail.com', NULL, NULL, 'email', '12345', 'Renter', '', 'Lapinigan SFADS', '09123456789', 'user_7_1765092355.jpg', '2025-11-18 09:27:46', '2026-02-11 12:01:40', 'f54NoWISIXBGVLK0JFg6cW:APA91bEIqYYMXuKiGQYSlGFjw-wfrGkM2p5qwdHOLwlLjinewKjF0JetFUG9_gDcJ206j7T7U4mC_8sR4mI8uZVznMcOu3Q5Vv56BGcRL0wqb7wQanERhKA', NULL, NULL, 0, 'N3wxNzcwODExMzAw', 0, NULL),
(8, 'migs', 'migs@gmail.com', NULL, NULL, 'email', '12345', 'Owner', '', '', NULL, NULL, '2025-11-19 06:09:08', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(9, 'mikko johan', 'johanmalanog@gmail.com', NULL, NULL, 'email', '12345', 'Renter', 'San Francisco', '', NULL, NULL, '2025-11-25 08:49:12', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(10, 'cart ney', 'owner@gmail.com', NULL, NULL, 'email', '12345', 'Owner', 'San Francisco', '', NULL, NULL, '2025-11-29 11:49:29', NULL, NULL, NULL, NULL, 0, NULL, 0, NULL),
(12, 'itanjimss', 'itan@gmail.com', NULL, NULL, 'email', '123456', 'Renter', 'San Luis', '', NULL, NULL, '2026-02-03 14:20:55', '2026-02-03 14:21:14', NULL, NULL, NULL, 0, 'MTJ8MTc3MDEyODQ3NA==', 0, NULL),
(13, 'Ethan James Estino', 'saberu1213@gmail.com', NULL, 'bXHVrLwdsrgg2ttjs8tz3622YOJ2', 'google', '$2y$10$CnUzQrte6fIGGGcW1vQZe.W9JVX6KbNpdtiApOdyZF0WIEFBEAI1m', 'Renter', 'San Francisco', '', '', 'https://lh3.googleusercontent.com/a/ACg8ocIwTNMSY5xrLV8w1nekg42FN98V28h3KSefSWr5MynFKPreEKIr=s96-c', '2026-02-03 14:23:44', '2026-02-10 02:29:06', 'dswk_--CTnKnJZ4raC0DGK:APA91bHp96nBiaQVfxUsjClCBD1afpNTV0gVTUgFyUrm0ZZyHDOq_o-vy-_hCEMdFs-H_qqLQF50S98FbEeKFlQwuR3Q4MTc-tmztV-UQQcALnHyyLdC4Hw', NULL, NULL, 0, NULL, 0, NULL),
(14, 'Cartney Dejolde', 'malanogmelchie@gmail.com', NULL, '2d1x4iVWLJPtqb29XrXKYlXUxWd2', 'google', '$2y$10$lXb9os7H0FKDn8OoLVGA2ev1uc5qsw7QVtaYKK1ceO23aF/Z7XZCW', 'Renter', 'San Francisco', '', '', 'https://lh3.googleusercontent.com/a/ACg8ocI4JoHeIlLjAnXQJKqMGY_u1il6g8yPY8TzBfibbS-aWoi5dXQu=s96-c', '2026-02-03 15:07:22', '2026-02-03 22:54:38', NULL, NULL, NULL, 0, NULL, 0, NULL),
(15, 'Ethan james Estino', 'ethanjamesestino@gmail.com', NULL, 'o0jZ9sVm7RduVnlUTpYOyqT7iBb2', 'google', '$2y$10$XqFj.LpnUumNPkZ8SFDRNenJ103kIBlPROE.QZ6bd9MXjJSv3k.nW', 'Renter', 'San Francisco', '', '', 'https://lh3.googleusercontent.com/a/ACg8ocJGkqZQBE_xRfqA2BSHR9X1L5UjsbZivxFDRllD5YQXHeCBcQI=s96-c', '2026-02-06 01:11:23', '2026-02-11 08:46:45', 'c0CgIUs6QQ-54dAR-e-zR-:APA91bFBZWtvrQC6ZSUSf5xaZKCvm2kWc9gcioKn5XUsdfySoZGfr8PF9HHCIbh6BlAStd2t7LMl8hPegJWBHMrDtesvswG6uZcDM2xMDSEosRWjc02tlxk', NULL, NULL, 0, NULL, 0, NULL),
(16, 'Lex Istaint', 'lexistaint@gmail.com', NULL, 'u9qE7PvwZXNUzTXdbD5xpSLSJiE3', 'google', '$2y$10$SFzM00Qq4U95SKVTAFLkQOtx.2YYF8WgZ7Fq4iV6IKf.Jm5IF8Jqy', 'Owner', 'San Francisco', '', '09451547348', 'https://lh3.googleusercontent.com/a/ACg8ocJdI-XfoLuAI3vg9HUZ6pq1YuG-1922m1kny8JNZHkZtaZ59Q=s96-c', '2026-02-06 01:37:53', '2026-02-09 12:03:51', NULL, '09451547348', 'Ethan James', 0, NULL, 0, NULL),
(17, 'Boss Billy Herman', 'eljanjosol@gmail.com', NULL, 'TbTkblJUe9VtMViJQxpKpnGvSnu1', 'google', '$2y$10$PzpG2g4TlZy.osllJEppauYCMNuHXB8g94OR5YPS7Wh8PUlUok.oi', 'Owner', 'Bayugan', 'Purok 2 Cagbas, Bayugan City, Agusan del Sur', '09123456789', 'user_17_1770699709228.jpg', '2026-02-10 04:57:15', '2026-02-10 04:57:15', NULL, '09123456789', 'Royeth Dorias', 0, NULL, 0, NULL),
(18, 'Janloyd Andig', 'janloydandig20@gmail.com', NULL, 'uPr2Heb67ZfN3iiU0lFNMSiEuvi1', 'google', '$2y$10$hnlouuWa5HUcDAPI2K1KNuWqiD8MVYmF6Eihmcf3yzl.VSvkzd952', 'Renter', 'La Paz', '', '', 'https://lh3.googleusercontent.com/a/ACg8ocLbZfOowgex4aauSTqWY75MnjuvTZz17Fb0capQWQB1Udq_LsE=s96-c', '2026-02-10 04:58:25', '2026-02-10 04:58:25', 'faHFMv4CTS2w9lygolEMDU:APA91bEzRV6e2VMc5dLIpj_H7YUyKmN1U0a8ibia6FgbJvEc2UIgOraAAU6wWxfNSkS3GkrBu4ec6FGqzmy_KkOQzb6ZW6wSZ6vE8baJBtPWKzAFb-tGMPs', NULL, NULL, 0, NULL, 0, NULL),
(19, 'caring', 'caring@gmail.com', NULL, NULL, 'email', '123456', 'Renter', 'Rosario', '', '09128515463', NULL, '2026-02-10 05:11:58', '2026-02-10 05:21:20', 'erxh8-qBQ5q63sn-dXj2pB:APA91bGFZdtV65bgYiPDUzErp-LzoivBbgv79xWCxIONG8X8y1KUi1x7JZaF0kNqmWjby4RqCjzno1tU02JrVaK9nYC2nBG-3l-dw4j1176dniTbxVDZIcg', NULL, NULL, 0, 'MTl8MTc3MDcwMDg4MA==', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_verifications`
--

CREATE TABLE `user_verifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `mobile_number` varchar(50) NOT NULL,
  `gender` varchar(50) DEFAULT NULL,
  `region` varchar(200) NOT NULL,
  `province` varchar(200) NOT NULL,
  `municipality` varchar(100) DEFAULT NULL,
  `barangay` varchar(200) NOT NULL,
  `date_of_birth` date DEFAULT NULL,
  `id_type` varchar(100) NOT NULL,
  `id_front_photo` varchar(255) NOT NULL,
  `id_back_photo` varchar(255) NOT NULL,
  `selfie_photo` varchar(255) NOT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `review_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `verified_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_verifications`
--

INSERT INTO `user_verifications` (`id`, `user_id`, `first_name`, `last_name`, `email`, `mobile_number`, `gender`, `region`, `province`, `municipality`, `barangay`, `date_of_birth`, `id_type`, `id_front_photo`, `id_back_photo`, `selfie_photo`, `status`, `review_notes`, `created_at`, `updated_at`, `verified_at`) VALUES
(1, 7, 'cartney', 'dejolde', 'cart@gmail.com', '09770433849', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'Prosperidad', 'Libertad', '2000-01-01', 'drivers_license', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_front_u7_1765373369_76d78803.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_back_u7_1765373369_8e161a5a.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/selfie_u7_1765373369_28c69452.jpg', 'approved', NULL, '2025-12-10 06:29:29', '2025-12-10 14:31:38', '2025-12-10 14:31:38'),
(2, 1, 'Cartney', 'Dejolde', 'cart@gmail.com', '09770433849', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'San Francisco', 'Lapinigan', '2000-01-01', 'drivers_license', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_front_u1_1765612212_5a86c434.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_back_u1_1765612212_786f7078.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/selfie_u1_1765612212_41279515.jpg', 'approved', NULL, '2025-12-13 00:50:12', '2025-12-13 07:51:07', '2025-12-13 07:51:07'),
(3, 4, 'Kristian', 'Marty', 'kristian@gmail.com', '09123456789', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'Talacogon', 'San Agustin', '2000-01-01', 'drivers_license', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_front_u4_1765612426_691871e5.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_back_u4_1765612426_20ebb0bb.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/selfie_u4_1765612426_caddbf7b.jpg', 'approved', NULL, '2025-12-13 00:53:46', '2025-12-13 07:54:13', '2025-12-13 07:54:13'),
(4, 5, 'Ethan', 'Owner', 'ethan@gmail.com', '0123456789', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'San Francisco', 'San Francisco ADS', '2000-01-01', 'drivers_license', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_front_u5_verified.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/id_back_u5_verified.jpg', 'C:\\xampp\\htdocs\\carGOAdmin\\api/../uploads/verifications/2025/12/selfie_u5_verified.jpg', 'approved', 'Manually verified via SQL', '2025-12-22 05:29:53', NULL, '2025-12-22 05:29:53'),
(6, 13, 'ethan', 'estino', 'taning@gmail.com', '09451547348', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'Rosario', 'Bayugan 3', '2000-01-28', 'national_id', 'api/../uploads/verifications/2026/02/id_front_u13_1770196029_2c9ee6cd.jpg', 'api/../uploads/verifications/2026/02/id_back_u13_1770196029_5ede9da5.jpg', 'api/../uploads/verifications/2026/02/selfie_u13_1770196029_e6232073.jpg', 'approved', NULL, '2026-02-04 17:07:09', '2026-02-04 09:14:51', '2026-02-04 09:14:51'),
(7, 15, 'Ethan', 'Estino', 'ethan@gmail.com', '09451547348', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'San Francisco', 'Lapinigan', '2000-01-28', 'drivers_license', 'api/../uploads/verifications/2026/02/id_front_u15_1770341374_18692cbe.jpg', 'api/../uploads/verifications/2026/02/id_back_u15_1770341374_a0bbf84c.jpg', 'api/../uploads/verifications/2026/02/selfie_u15_1770341374_25e011b5.jpg', 'approved', NULL, '2026-02-06 09:29:34', '2026-02-06 01:36:45', '2026-02-06 01:36:45'),
(8, 16, 'ethan', 'isko', 'itajims@gmail.com', '09451547348', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'San Francisco', 'Oriente', '2000-01-08', 'passport', 'api/../uploads/verifications/2026/02/id_front_u16_1770343005_42c74088.jpg', 'api/../uploads/verifications/2026/02/id_back_u16_1770343005_8eb51cbf.jpg', 'api/../uploads/verifications/2026/02/selfie_u16_1770343005_b45a5e06.jpg', 'approved', NULL, '2026-02-06 09:56:45', '2026-02-06 01:58:01', '2026-02-06 01:58:01'),
(9, 19, 'cwring', 'cating', 'caring@gmail.com', '09451547348', 'Male', 'Region XIII (Caraga)', 'Agusan del Sur', 'Bunawan', 'Poblacion', '2000-01-21', 'national_id', 'api/../uploads/verifications/2026/02/id_front_u19_1770702531_86664268.jpg', 'api/../uploads/verifications/2026/02/id_back_u19_1770702531_d3b24767.jpg', 'api/../uploads/verifications/2026/02/selfie_u19_1770702531_2f0e9dff.jpg', 'approved', NULL, '2026-02-10 13:48:51', '2026-02-10 05:49:17', '2026-02-10 05:49:17');

--
-- Triggers `user_verifications`
--
DELIMITER $$
CREATE TRIGGER `prevent_duplicate_verification` BEFORE INSERT ON `user_verifications` FOR EACH ROW BEGIN
  DECLARE existing_count INT;
  
  SELECT COUNT(*) INTO existing_count
  FROM user_verifications
  WHERE user_id = NEW.user_id 
    AND status IN ('pending', 'approved');
  
  IF existing_count > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'User already has a pending or approved verification';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_availability`
--

CREATE TABLE `vehicle_availability` (
  `id` int(11) NOT NULL,
  `owner_id` int(11) NOT NULL,
  `vehicle_id` int(11) NOT NULL,
  `vehicle_type` varchar(20) NOT NULL DEFAULT 'car',
  `blocked_date` date NOT NULL,
  `reason` varchar(255) DEFAULT 'Blocked by owner',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `vehicle_availability`
--

INSERT INTO `vehicle_availability` (`id`, `owner_id`, `vehicle_id`, `vehicle_type`, `blocked_date`, `reason`, `created_at`, `updated_at`) VALUES
(1, 1, 3, 'car', '2026-02-02', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(2, 1, 3, 'car', '2026-02-07', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(3, 1, 3, 'car', '2026-02-06', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(4, 1, 3, 'car', '2026-02-05', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(5, 1, 3, 'car', '2026-02-04', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(6, 1, 3, 'car', '2026-02-03', 'blocked', '2026-02-01 02:31:31', '2026-02-01 02:31:31'),
(7, 1, 37, 'car', '2026-02-08', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(8, 1, 37, 'car', '2026-02-09', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(9, 1, 37, 'car', '2026-02-10', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(10, 1, 37, 'car', '2026-02-11', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(11, 1, 37, 'car', '2026-02-12', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(12, 1, 37, 'car', '2026-02-13', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(13, 1, 37, 'car', '2026-02-14', 'Blocked by owner', '2026-02-01 02:50:36', '2026-02-01 02:50:36'),
(14, 1, 37, 'car', '2026-02-18', 'Blocked by owner', '2026-02-01 03:23:17', '2026-02-01 03:23:17'),
(15, 1, 37, 'car', '2026-02-19', 'Blocked by owner', '2026-02-01 03:23:17', '2026-02-01 03:23:17');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_active_insurance_policies`
-- (See below for the actual view)
--
CREATE TABLE `v_active_insurance_policies` (
`id` int(11)
,`policy_number` varchar(100)
,`booking_id` int(11)
,`user_id` int(11)
,`owner_id` int(11)
,`renter_name` varchar(100)
,`coverage_type` enum('basic','standard','premium','comprehensive')
,`premium_amount` decimal(10,2)
,`coverage_limit` decimal(12,2)
,`policy_start` datetime
,`policy_end` datetime
,`status` enum('active','expired','cancelled','claimed')
,`provider_name` varchar(255)
,`days_remaining` int(8)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_escrows_ready_for_release`
-- (See below for the actual view)
--
CREATE TABLE `v_escrows_ready_for_release` (
`booking_id` int(11)
,`owner_id` int(11)
,`renter_id` int(11)
,`owner_payout` decimal(10,2)
,`platform_fee` decimal(10,2)
,`total_amount` decimal(10,2)
,`escrow_status` enum('pending','held','released_to_owner','refunded','released')
,`payout_status` enum('pending','processing','completed','failed')
,`return_date` date
,`completed_at` datetime
,`escrow_held_at` datetime
,`days_since_return` int(8)
,`days_since_completion` int(8)
,`owner_name` varchar(100)
,`owner_email` varchar(100)
,`owner_gcash` varchar(15)
,`owner_gcash_name` varchar(100)
,`renter_name` varchar(100)
,`req_booking_completed` int(1)
,`req_escrow_held` int(1)
,`req_no_hold` int(1)
,`req_gcash_configured` int(1)
,`req_payment_verified` int(1)
,`req_holding_period` int(1)
,`all_requirements_met` int(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_escrow_statistics`
-- (See below for the actual view)
--
CREATE TABLE `v_escrow_statistics` (
`funds_in_escrow` decimal(32,2)
,`pending_releases` bigint(21)
,`released_this_month` decimal(32,2)
,`on_hold_count` bigint(21)
,`avg_escrow_duration_days` decimal(11,4)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_insurance_claims_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_insurance_claims_summary` (
`id` int(11)
,`claim_number` varchar(100)
,`claim_type` enum('collision','theft','liability','personal_injury','property_damage','other')
,`status` enum('submitted','under_review','approved','rejected','paid','closed')
,`claimed_amount` decimal(10,2)
,`approved_amount` decimal(10,2)
,`booking_id` int(11)
,`claimant_name` varchar(100)
,`policy_number` varchar(100)
,`incident_date` datetime
,`claim_date` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_mileage_statistics`
-- (See below for the actual view)
--
CREATE TABLE `v_mileage_statistics` (
`booking_id` int(11)
,`car_id` int(11)
,`vehicle_type` enum('car','motorcycle')
,`user_id` int(11)
,`owner_id` int(11)
,`pickup_date` date
,`return_date` date
,`rental_days` int(9)
,`odometer_start` int(11)
,`odometer_end` int(11)
,`actual_mileage` int(11)
,`allowed_mileage` int(11)
,`excess_mileage` int(11)
,`excess_mileage_fee` decimal(10,2)
,`gps_distance` decimal(10,2)
,`odometer_gps_discrepancy` decimal(13,2)
,`discrepancy_percentage` decimal(17,2)
,`mileage_verified_by` int(11)
,`mileage_verified_at` datetime
,`excess_status` varchar(9)
,`renter_name` varchar(100)
,`owner_name` varchar(100)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_overdue_bookings`
-- (See below for the actual view)
--
CREATE TABLE `v_overdue_bookings` (
`id` int(11)
,`user_id` int(11)
,`owner_id` int(11)
,`car_id` int(11)
,`vehicle_type` enum('car','motorcycle')
,`pickup_date` date
,`return_date` date
,`return_time` time
,`status` enum('pending','approved','ongoing','rejected','completed','cancelled')
,`overdue_status` enum('on_time','overdue','severely_overdue')
,`overdue_days` int(11)
,`late_fee_amount` decimal(10,2)
,`late_fee_charged` tinyint(1)
,`total_amount` decimal(10,2)
,`renter_name` varchar(100)
,`renter_email` varchar(100)
,`renter_contact` varchar(50)
,`owner_name` varchar(100)
,`owner_email` varchar(100)
,`owner_contact` varchar(50)
,`vehicle_name` varchar(101)
,`hours_overdue_now` bigint(21)
,`days_overdue_now` int(8)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `admin_action_logs`
--
ALTER TABLE `admin_action_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_admin_id` (`admin_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_action_type` (`action_type`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `admin_notifications`
--
ALTER TABLE `admin_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_admin_read` (`admin_id`,`read_status`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `archived_notifications`
--
ALTER TABLE `archived_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_original_id` (`original_id`),
  ADD KEY `idx_archived_at` (`archived_at`),
  ADD KEY `idx_type` (`type`);

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `idx_escrow_status` (`escrow_status`),
  ADD KEY `idx_payout_status` (`payout_status`),
  ADD KEY `idx_booking_escrow_payout` (`escrow_status`,`payout_status`,`owner_id`),
  ADD KEY `idx_booking_payment_status` (`payment_status`,`status`),
  ADD KEY `idx_overdue_status` (`overdue_status`,`status`,`return_date`),
  ADD KEY `idx_late_fee_payment_status` (`late_fee_payment_status`),
  ADD KEY `idx_bookings_late_fee_confirmed` (`late_fee_confirmed`),
  ADD KEY `idx_bookings_late_fee_waived` (`late_fee_waived`),
  ADD KEY `idx_bookings_reminder_count` (`reminder_count`),
  ADD KEY `idx_bookings_last_reminder_sent` (`last_reminder_sent`),
  ADD KEY `idx_vehicle_dates` (`car_id`,`vehicle_type`,`pickup_date`,`return_date`),
  ADD KEY `idx_status_dates` (`status`,`pickup_date`,`return_date`),
  ADD KEY `idx_owner_status` (`owner_id`,`status`),
  ADD KEY `fk_mileage_verifier` (`mileage_verified_by`),
  ADD KEY `idx_odometer_tracking` (`odometer_start`,`odometer_end`,`actual_mileage`),
  ADD KEY `idx_excess_mileage` (`excess_mileage`,`excess_mileage_paid`),
  ADD KEY `idx_insurance_policy` (`insurance_policy_id`),
  ADD KEY `idx_trip_started` (`trip_started_at`),
  ADD KEY `idx_escrow_release` (`escrow_status`,`status`,`escrow_released_at`),
  ADD KEY `idx_owner_payout` (`owner_id`,`escrow_status`,`payout_status`),
  ADD KEY `idx_auto_release` (`status`,`escrow_status`,`return_date`),
  ADD KEY `idx_payment_verified` (`payment_verified_at`,`escrow_status`),
  ADD KEY `idx_escrow_hold` (`escrow_hold_reason`),
  ADD KEY `fk_payment_verified_by` (`payment_verified_by`);

--
-- Indexes for table `cars`
--
ALTER TABLE `cars`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner_id` (`owner_id`),
  ADD KEY `idx_owner_status` (`owner_id`,`status`);

--
-- Indexes for table `car_photos`
--
ALTER TABLE `car_photos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `car_id` (`car_id`);

--
-- Indexes for table `car_ratings`
--
ALTER TABLE `car_ratings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `car_id` (`car_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `car_rules`
--
ALTER TABLE `car_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `car_id` (`car_id`);

--
-- Indexes for table `escrow`
--
ALTER TABLE `escrow`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_booking_escrow` (`booking_id`),
  ADD KEY `payment_id` (`payment_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `fk_escrow_processed_by` (`processed_by`),
  ADD KEY `idx_escrow_status` (`status`,`booking_id`);

--
-- Indexes for table `escrow_logs`
--
ALTER TABLE `escrow_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking` (`booking_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_created` (`created_at`),
  ADD KEY `fk_escrow_log_admin` (`admin_id`);

--
-- Indexes for table `escrow_transactions`
--
ALTER TABLE `escrow_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `transaction_type` (`transaction_type`);

--
-- Indexes for table `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_favorite` (`user_id`,`vehicle_type`,`vehicle_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_vehicle_type` (`vehicle_type`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `gps_distance_tracking`
--
ALTER TABLE `gps_distance_tracking`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_booking` (`booking_id`);

--
-- Indexes for table `gps_locations`
--
ALTER TABLE `gps_locations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `insurance_audit_log`
--
ALTER TABLE `insurance_audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_policy_id` (`policy_id`),
  ADD KEY `idx_claim_id` (`claim_id`);

--
-- Indexes for table `insurance_claims`
--
ALTER TABLE `insurance_claims`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `claim_number` (`claim_number`),
  ADD KEY `idx_policy_id` (`policy_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_claim_number` (`claim_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_claim_status` (`status`,`priority`);

--
-- Indexes for table `insurance_coverage_types`
--
ALTER TABLE `insurance_coverage_types`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `coverage_code` (`coverage_code`);

--
-- Indexes for table `insurance_policies`
--
ALTER TABLE `insurance_policies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `policy_number` (`policy_number`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_policy_number` (`policy_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `fk_insurance_policy_provider` (`provider_id`),
  ADD KEY `idx_policy_dates` (`policy_start`,`policy_end`),
  ADD KEY `idx_policy_status` (`status`);

--
-- Indexes for table `insurance_providers`
--
ALTER TABLE `insurance_providers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `provider_code` (`provider_code`);

--
-- Indexes for table `late_fee_payments`
--
ALTER TABLE `late_fee_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `payment_status` (`payment_status`);

--
-- Indexes for table `mileage_disputes`
--
ALTER TABLE `mileage_disputes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `resolved_by` (`resolved_by`),
  ADD KEY `idx_booking` (`booking_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_owner` (`owner_id`);

--
-- Indexes for table `mileage_logs`
--
ALTER TABLE `mileage_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking` (`booking_id`),
  ADD KEY `idx_log_type` (`log_type`);

--
-- Indexes for table `motorcycles`
--
ALTER TABLE `motorcycles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `owner_id` (`owner_id`),
  ADD KEY `idx_owner_status` (`owner_id`,`status`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_notification_user_status` (`user_id`,`read_status`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_read_status` (`read_status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `overdue_logs`
--
ALTER TABLE `overdue_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking` (`booking_id`),
  ADD KEY `idx_action` (`action_taken`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `email` (`email`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `expires_at` (`expires_at`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `idx_payment_status_booking` (`payment_status`,`booking_id`),
  ADD KEY `idx_payment_user_status` (`user_id`,`payment_status`,`created_at`);

--
-- Indexes for table `payments_incomplete_backup`
--
ALTER TABLE `payments_incomplete_backup`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payment_attempts`
--
ALTER TABLE `payment_attempts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_transaction_type` (`transaction_type`);

--
-- Indexes for table `payment_transactions_deleted_backup`
--
ALTER TABLE `payment_transactions_deleted_backup`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payouts`
--
ALTER TABLE `payouts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `escrow_id` (`escrow_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_owner_id` (`owner_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `fk_payouts_processed_by` (`processed_by`),
  ADD KEY `idx_payout_owner_status` (`owner_id`,`status`,`created_at`),
  ADD KEY `idx_payout_booking_status` (`booking_id`,`status`);

--
-- Indexes for table `payout_requests`
--
ALTER TABLE `payout_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `owner_id` (`owner_id`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `platform_settings`
--
ALTER TABLE `platform_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `refunds`
--
ALTER TABLE `refunds`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `booking_id` (`booking_id`),
  ADD UNIQUE KEY `refund_id` (`refund_id`),
  ADD KEY `idx_refund_status` (`status`),
  ADD KEY `idx_user_refunds` (`user_id`,`status`),
  ADD KEY `idx_booking_refunds` (`booking_id`),
  ADD KEY `idx_refund_booking` (`booking_id`,`status`),
  ADD KEY `fk_refund_payment` (`payment_id`);

--
-- Indexes for table `rental_extensions`
--
ALTER TABLE `rental_extensions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `requested_by` (`requested_by`),
  ADD KEY `approved_by` (`approved_by`),
  ADD KEY `idx_booking` (`booking_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reporter_id` (`reporter_id`),
  ADD KEY `reported_id` (`reported_id`),
  ADD KEY `status` (`status`),
  ADD KEY `report_type` (`report_type`),
  ADD KEY `idx_reports_status` (`status`),
  ADD KEY `idx_reports_priority` (`priority`),
  ADD KEY `idx_reports_created` (`created_at`);

--
-- Indexes for table `report_logs`
--
ALTER TABLE `report_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `report_id` (`report_id`),
  ADD KEY `performed_by` (`performed_by`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_owner_rating` (`owner_id`,`rating`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `facebook_id` (`facebook_id`),
  ADD UNIQUE KEY `idx_google_uid` (`google_uid`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_auth_provider` (`auth_provider`),
  ADD KEY `idx_online_status` (`is_online`,`last_seen`);

--
-- Indexes for table `user_verifications`
--
ALTER TABLE `user_verifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_verification_status` (`status`),
  ADD KEY `idx_verification_user` (`user_id`,`status`);

--
-- Indexes for table `vehicle_availability`
--
ALTER TABLE `vehicle_availability`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_block` (`vehicle_id`,`vehicle_type`,`blocked_date`),
  ADD KEY `idx_owner_id` (`owner_id`),
  ADD KEY `idx_vehicle` (`vehicle_id`,`vehicle_type`),
  ADD KEY `idx_blocked_date` (`blocked_date`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `admin_action_logs`
--
ALTER TABLE `admin_action_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admin_notifications`
--
ALTER TABLE `admin_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `archived_notifications`
--
ALTER TABLE `archived_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `cars`
--
ALTER TABLE `cars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `car_photos`
--
ALTER TABLE `car_photos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `car_ratings`
--
ALTER TABLE `car_ratings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `car_rules`
--
ALTER TABLE `car_rules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `escrow`
--
ALTER TABLE `escrow`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `escrow_logs`
--
ALTER TABLE `escrow_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `escrow_transactions`
--
ALTER TABLE `escrow_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gps_distance_tracking`
--
ALTER TABLE `gps_distance_tracking`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `gps_locations`
--
ALTER TABLE `gps_locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `insurance_audit_log`
--
ALTER TABLE `insurance_audit_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `insurance_claims`
--
ALTER TABLE `insurance_claims`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `insurance_coverage_types`
--
ALTER TABLE `insurance_coverage_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `insurance_policies`
--
ALTER TABLE `insurance_policies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `insurance_providers`
--
ALTER TABLE `insurance_providers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `late_fee_payments`
--
ALTER TABLE `late_fee_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mileage_disputes`
--
ALTER TABLE `mileage_disputes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mileage_logs`
--
ALTER TABLE `mileage_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `motorcycles`
--
ALTER TABLE `motorcycles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `overdue_logs`
--
ALTER TABLE `overdue_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=116;

--
-- AUTO_INCREMENT for table `payment_attempts`
--
ALTER TABLE `payment_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `payouts`
--
ALTER TABLE `payouts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payout_requests`
--
ALTER TABLE `payout_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `platform_settings`
--
ALTER TABLE `platform_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `refunds`
--
ALTER TABLE `refunds`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rental_extensions`
--
ALTER TABLE `rental_extensions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `report_logs`
--
ALTER TABLE `report_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT for table `user_verifications`
--
ALTER TABLE `user_verifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `vehicle_availability`
--
ALTER TABLE `vehicle_availability`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

-- --------------------------------------------------------

--
-- Structure for view `v_active_insurance_policies`
--
DROP TABLE IF EXISTS `v_active_insurance_policies`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_active_insurance_policies`  AS SELECT `ip`.`id` AS `id`, `ip`.`policy_number` AS `policy_number`, `ip`.`booking_id` AS `booking_id`, `b`.`user_id` AS `user_id`, `b`.`owner_id` AS `owner_id`, `u`.`fullname` AS `renter_name`, `ip`.`coverage_type` AS `coverage_type`, `ip`.`premium_amount` AS `premium_amount`, `ip`.`coverage_limit` AS `coverage_limit`, `ip`.`policy_start` AS `policy_start`, `ip`.`policy_end` AS `policy_end`, `ip`.`status` AS `status`, `prov`.`provider_name` AS `provider_name`, to_days(`ip`.`policy_end`) - to_days(current_timestamp()) AS `days_remaining` FROM (((`insurance_policies` `ip` join `bookings` `b` on(`ip`.`booking_id` = `b`.`id`)) join `users` `u` on(`b`.`user_id` = `u`.`id`)) join `insurance_providers` `prov` on(`ip`.`provider_id` = `prov`.`id`)) WHERE `ip`.`status` = 'active' AND `ip`.`policy_end` > current_timestamp() ;

-- --------------------------------------------------------

--
-- Structure for view `v_escrows_ready_for_release`
--
DROP TABLE IF EXISTS `v_escrows_ready_for_release`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_escrows_ready_for_release`  AS SELECT `b`.`id` AS `booking_id`, `b`.`owner_id` AS `owner_id`, `b`.`user_id` AS `renter_id`, `b`.`owner_payout` AS `owner_payout`, `b`.`platform_fee` AS `platform_fee`, `b`.`total_amount` AS `total_amount`, `b`.`escrow_status` AS `escrow_status`, `b`.`payout_status` AS `payout_status`, `b`.`return_date` AS `return_date`, `b`.`completed_at` AS `completed_at`, `b`.`escrow_held_at` AS `escrow_held_at`, to_days(current_timestamp()) - to_days(`b`.`return_date`) AS `days_since_return`, to_days(current_timestamp()) - to_days(`b`.`completed_at`) AS `days_since_completion`, `u`.`fullname` AS `owner_name`, `u`.`email` AS `owner_email`, `u`.`gcash_number` AS `owner_gcash`, `u`.`gcash_name` AS `owner_gcash_name`, `r`.`fullname` AS `renter_name`, `b`.`status`= 'completed' AS `req_booking_completed`, `b`.`escrow_status`= 'held' AS `req_escrow_held`, `b`.`escrow_hold_reason` is null or `b`.`escrow_hold_reason` = '' AS `req_no_hold`, `u`.`gcash_number` is not null and `u`.`gcash_number` <> '' AS `req_gcash_configured`, `b`.`payment_verified_at` is not null AS `req_payment_verified`, to_days(current_timestamp()) - to_days(`b`.`return_date`) >= 3 AS `req_holding_period`, `b`.`status`= 'completed' and `b`.`escrow_status` = 'held' and (`b`.`escrow_hold_reason` is null or `b`.`escrow_hold_reason` = '') and `u`.`gcash_number` is not null and `u`.`gcash_number` <> '' and `b`.`payment_verified_at` is not null AS `all_requirements_met` FROM ((`bookings` `b` left join `users` `u` on(`b`.`owner_id` = `u`.`id`)) left join `users` `r` on(`b`.`user_id` = `r`.`id`)) WHERE `b`.`escrow_status` = 'held' AND `b`.`status` = 'completed' ORDER BY to_days(current_timestamp()) - to_days(`b`.`completed_at`) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_escrow_statistics`
--
DROP TABLE IF EXISTS `v_escrow_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_escrow_statistics`  AS SELECT coalesce(sum(case when `bookings`.`escrow_status` = 'held' then `bookings`.`owner_payout` else 0 end),0) AS `funds_in_escrow`, count(case when `bookings`.`status` = 'completed' and `bookings`.`escrow_status` = 'held' then 1 end) AS `pending_releases`, coalesce(sum(case when `bookings`.`escrow_status` in ('released_to_owner','released') and month(`bookings`.`escrow_released_at`) = month(current_timestamp()) and year(`bookings`.`escrow_released_at`) = year(current_timestamp()) then `bookings`.`owner_payout` else 0 end),0) AS `released_this_month`, count(case when `bookings`.`escrow_status` = 'held' and `bookings`.`escrow_hold_reason` is not null and `bookings`.`escrow_hold_reason` <> '' then 1 end) AS `on_hold_count`, avg(case when `bookings`.`escrow_status` in ('released_to_owner','released') and `bookings`.`escrow_released_at` is not null then to_days(`bookings`.`escrow_released_at`) - to_days(coalesce(`bookings`.`escrow_held_at`,`bookings`.`payment_verified_at`,`bookings`.`created_at`)) else NULL end) AS `avg_escrow_duration_days` FROM `bookings` ;

-- --------------------------------------------------------

--
-- Structure for view `v_insurance_claims_summary`
--
DROP TABLE IF EXISTS `v_insurance_claims_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_insurance_claims_summary`  AS SELECT `ic`.`id` AS `id`, `ic`.`claim_number` AS `claim_number`, `ic`.`claim_type` AS `claim_type`, `ic`.`status` AS `status`, `ic`.`claimed_amount` AS `claimed_amount`, `ic`.`approved_amount` AS `approved_amount`, `b`.`id` AS `booking_id`, `u`.`fullname` AS `claimant_name`, `ip`.`policy_number` AS `policy_number`, `ic`.`incident_date` AS `incident_date`, `ic`.`created_at` AS `claim_date` FROM (((`insurance_claims` `ic` join `insurance_policies` `ip` on(`ic`.`policy_id` = `ip`.`id`)) join `bookings` `b` on(`ic`.`booking_id` = `b`.`id`)) join `users` `u` on(`ic`.`user_id` = `u`.`id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_mileage_statistics`
--
DROP TABLE IF EXISTS `v_mileage_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_mileage_statistics`  AS SELECT `b`.`id` AS `booking_id`, `b`.`car_id` AS `car_id`, `b`.`vehicle_type` AS `vehicle_type`, `b`.`user_id` AS `user_id`, `b`.`owner_id` AS `owner_id`, `b`.`pickup_date` AS `pickup_date`, `b`.`return_date` AS `return_date`, to_days(`b`.`return_date`) - to_days(`b`.`pickup_date`) + 1 AS `rental_days`, `b`.`odometer_start` AS `odometer_start`, `b`.`odometer_end` AS `odometer_end`, `b`.`actual_mileage` AS `actual_mileage`, `b`.`allowed_mileage` AS `allowed_mileage`, `b`.`excess_mileage` AS `excess_mileage`, `b`.`excess_mileage_fee` AS `excess_mileage_fee`, `b`.`gps_distance` AS `gps_distance`, CASE WHEN `b`.`actual_mileage` is not null AND `b`.`gps_distance` is not null THEN abs(`b`.`actual_mileage` - `b`.`gps_distance`) ELSE NULL END AS `odometer_gps_discrepancy`, CASE WHEN `b`.`actual_mileage` is not null AND `b`.`gps_distance` is not null THEN round(abs(`b`.`actual_mileage` - `b`.`gps_distance`) / `b`.`actual_mileage` * 100,2) ELSE NULL END AS `discrepancy_percentage`, `b`.`mileage_verified_by` AS `mileage_verified_by`, `b`.`mileage_verified_at` AS `mileage_verified_at`, CASE WHEN `b`.`excess_mileage` > 0 AND `b`.`excess_mileage_paid` = 1 THEN 'paid' WHEN `b`.`excess_mileage` > 0 AND `b`.`excess_mileage_paid` = 0 THEN 'unpaid' ELSE 'no_excess' END AS `excess_status`, `u`.`fullname` AS `renter_name`, `o`.`fullname` AS `owner_name` FROM ((`bookings` `b` left join `users` `u` on(`b`.`user_id` = `u`.`id`)) left join `users` `o` on(`b`.`owner_id` = `o`.`id`)) WHERE `b`.`status` in ('completed','active') ;

-- --------------------------------------------------------

--
-- Structure for view `v_overdue_bookings`
--
DROP TABLE IF EXISTS `v_overdue_bookings`;

CREATE ALGORITHM=UNDEFINED DEFINER=`u672913452_ethan`@`127.0.0.1` SQL SECURITY DEFINER VIEW `v_overdue_bookings`  AS SELECT `b`.`id` AS `id`, `b`.`user_id` AS `user_id`, `b`.`owner_id` AS `owner_id`, `b`.`car_id` AS `car_id`, `b`.`vehicle_type` AS `vehicle_type`, `b`.`pickup_date` AS `pickup_date`, `b`.`return_date` AS `return_date`, `b`.`return_time` AS `return_time`, `b`.`status` AS `status`, `b`.`overdue_status` AS `overdue_status`, `b`.`overdue_days` AS `overdue_days`, `b`.`late_fee_amount` AS `late_fee_amount`, `b`.`late_fee_charged` AS `late_fee_charged`, `b`.`total_amount` AS `total_amount`, concat(`u`.`fullname`) AS `renter_name`, `u`.`email` AS `renter_email`, `u`.`phone` AS `renter_contact`, concat(`o`.`fullname`) AS `owner_name`, `o`.`email` AS `owner_email`, `o`.`phone` AS `owner_contact`, concat(coalesce(`c`.`brand`,`m`.`brand`),' ',coalesce(`c`.`model`,`m`.`model`)) AS `vehicle_name`, timestampdiff(HOUR,concat(`b`.`return_date`,' ',`b`.`return_time`),current_timestamp()) AS `hours_overdue_now`, to_days(current_timestamp()) - to_days(`b`.`return_date`) AS `days_overdue_now` FROM ((((`bookings` `b` left join `users` `u` on(`b`.`user_id` = `u`.`id`)) left join `users` `o` on(`b`.`owner_id` = `o`.`id`)) left join `cars` `c` on(`b`.`car_id` = `c`.`id` and `b`.`vehicle_type` = 'car')) left join `motorcycles` `m` on(`b`.`car_id` = `m`.`id` and `b`.`vehicle_type` = 'motorcycle')) WHERE `b`.`status` = 'approved' AND concat(`b`.`return_date`,' ',`b`.`return_time`) < current_timestamp() ORDER BY timestampdiff(HOUR,concat(`b`.`return_date`,' ',`b`.`return_time`),current_timestamp()) DESC ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `fk_mileage_verifier` FOREIGN KEY (`mileage_verified_by`) REFERENCES `admin` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_payment_verified_by` FOREIGN KEY (`payment_verified_by`) REFERENCES `admin` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `cars`
--
ALTER TABLE `cars`
  ADD CONSTRAINT `cars_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `car_photos`
--
ALTER TABLE `car_photos`
  ADD CONSTRAINT `car_photos_ibfk_1` FOREIGN KEY (`car_id`) REFERENCES `cars` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `car_ratings`
--
ALTER TABLE `car_ratings`
  ADD CONSTRAINT `car_ratings_ibfk_1` FOREIGN KEY (`car_id`) REFERENCES `cars` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `car_ratings_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `car_rules`
--
ALTER TABLE `car_rules`
  ADD CONSTRAINT `car_rules_ibfk_1` FOREIGN KEY (`car_id`) REFERENCES `cars` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `escrow`
--
ALTER TABLE `escrow`
  ADD CONSTRAINT `escrow_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `escrow_ibfk_2` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_escrow_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `admin` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `escrow_logs`
--
ALTER TABLE `escrow_logs`
  ADD CONSTRAINT `fk_escrow_log_admin` FOREIGN KEY (`admin_id`) REFERENCES `admin` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `gps_distance_tracking`
--
ALTER TABLE `gps_distance_tracking`
  ADD CONSTRAINT `gps_distance_tracking_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `insurance_claims`
--
ALTER TABLE `insurance_claims`
  ADD CONSTRAINT `fk_insurance_claim_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_insurance_claim_policy` FOREIGN KEY (`policy_id`) REFERENCES `insurance_policies` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `insurance_policies`
--
ALTER TABLE `insurance_policies`
  ADD CONSTRAINT `fk_insurance_policy_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_insurance_policy_provider` FOREIGN KEY (`provider_id`) REFERENCES `insurance_providers` (`id`);

--
-- Constraints for table `mileage_disputes`
--
ALTER TABLE `mileage_disputes`
  ADD CONSTRAINT `mileage_disputes_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `mileage_disputes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `mileage_disputes_ibfk_3` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `mileage_disputes_ibfk_4` FOREIGN KEY (`resolved_by`) REFERENCES `admin` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `mileage_logs`
--
ALTER TABLE `mileage_logs`
  ADD CONSTRAINT `mileage_logs_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `motorcycles`
--
ALTER TABLE `motorcycles`
  ADD CONSTRAINT `motorcycles_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `overdue_logs`
--
ALTER TABLE `overdue_logs`
  ADD CONSTRAINT `overdue_logs_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  ADD CONSTRAINT `payment_transactions_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payouts`
--
ALTER TABLE `payouts`
  ADD CONSTRAINT `fk_payouts_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `admin` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `payouts_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payouts_ibfk_2` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payouts_ibfk_3` FOREIGN KEY (`escrow_id`) REFERENCES `escrow` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `refunds`
--
ALTER TABLE `refunds`
  ADD CONSTRAINT `fk_refund_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_refund_payment` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rental_extensions`
--
ALTER TABLE `rental_extensions`
  ADD CONSTRAINT `rental_extensions_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rental_extensions_ibfk_2` FOREIGN KEY (`requested_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `rental_extensions_ibfk_3` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `report_logs`
--
ALTER TABLE `report_logs`
  ADD CONSTRAINT `report_logs_ibfk_1` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `report_logs_ibfk_2` FOREIGN KEY (`performed_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `user_verifications`
--
ALTER TABLE `user_verifications`
  ADD CONSTRAINT `user_verifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
