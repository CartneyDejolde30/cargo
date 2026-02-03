-- ================================================================
-- HOSTINGER-COMPATIBLE STORED PROCEDURE
-- CarGO Philippines - Vehicle Availability Checker
-- ================================================================
-- This version removes the DEFINER clause to work on shared hosting

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_get_vehicle_availability$$

CREATE PROCEDURE sp_get_vehicle_availability(
    IN p_vehicle_id INT,
    IN p_vehicle_type VARCHAR(20),
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
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

-- ================================================================
-- USAGE EXAMPLE:
-- ================================================================
-- CALL sp_get_vehicle_availability(1, 'car', '2026-02-01', '2026-02-28');
-- 
-- This will return all blocked and booked dates for vehicle ID 1
-- between Feb 1 and Feb 28, 2026
-- ================================================================
