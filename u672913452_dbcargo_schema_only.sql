-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Feb 10, 2026 at 01:25 PM
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

--
-- Dumping data for table `admin_action_logs`
--


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

--
-- Dumping data for table `favorites`
--


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

--
-- Dumping data for table `late_fee_payments`
--


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

--
-- Dumping data for table `overdue_logs`
--


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

--
-- Dumping data for table `payments_incomplete_backup`
--


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

--
-- Dumping data for table `refunds`
--


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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `admin_notifications`
--
ALTER TABLE `admin_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `archived_notifications`
--
ALTER TABLE `archived_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `escrow_logs`
--
ALTER TABLE `escrow_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `escrow_transactions`
--
ALTER TABLE `escrow_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `gps_distance_tracking`
--
ALTER TABLE `gps_distance_tracking`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `gps_locations`
--
ALTER TABLE `gps_locations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=664;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `insurance_providers`
--
ALTER TABLE `insurance_providers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `late_fee_payments`
--
ALTER TABLE `late_fee_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=319;

--
-- AUTO_INCREMENT for table `overdue_logs`
--
ALTER TABLE `overdue_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=115;

--
-- AUTO_INCREMENT for table `payment_attempts`
--
ALTER TABLE `payment_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payment_transactions`
--
ALTER TABLE `payment_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT for table `payouts`
--
ALTER TABLE `payouts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

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
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

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
