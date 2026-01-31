<?php
/**
 * Test Analytics API - Debug Script
 * Run this to test if analytics API is working
 * Access: http://10.218.197.49/carGOAdmin/tmp_rovodev_test_analytics_api.php
 */

require_once 'include/db.php';

header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html>
<html>
<head>
    <title>Analytics API Test</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #666; margin-top: 30px; }
        pre { background: #f9f9f9; padding: 15px; border-radius: 4px; overflow-x: auto; }
        .success { color: green; }
        .error { color: red; }
        .info { color: blue; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 Analytics API Test Results</h1>
        
        <?php
        // Test 1: Database Connection
        echo '<div class="test-section">';
        echo '<h2>1. Database Connection</h2>';
        if ($conn) {
            echo '<p class="success">✅ Database connected successfully</p>';
        } else {
            echo '<p class="error">❌ Database connection failed: ' . mysqli_connect_error() . '</p>';
        }
        echo '</div>';

        // Test 2: Check Tables Exist
        echo '<div class="test-section">';
        echo '<h2>2. Database Tables</h2>';
        $tables = ['bookings', 'cars', 'motorcycles', 'reviews'];
        foreach ($tables as $table) {
            $result = mysqli_query($conn, "SHOW TABLES LIKE '$table'");
            if (mysqli_num_rows($result) > 0) {
                echo "<p class='success'>✅ Table '$table' exists</p>";
            } else {
                echo "<p class='error'>❌ Table '$table' missing</p>";
            }
        }
        echo '</div>';

        // Test 3: Check for Data
        echo '<div class="test-section">';
        echo '<h2>3. Data Availability</h2>';
        
        $bookingsCount = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) as count FROM bookings"))['count'];
        $carsCount = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) as count FROM cars"))['count'];
        $motorcyclesCount = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) as count FROM motorcycles"))['count'];
        
        echo "<table>";
        echo "<tr><th>Table</th><th>Count</th><th>Status</th></tr>";
        echo "<tr><td>Bookings</td><td>$bookingsCount</td><td>" . ($bookingsCount > 0 ? '<span class="success">✅ Has data</span>' : '<span class="error">⚠️ Empty</span>') . "</td></tr>";
        echo "<tr><td>Cars</td><td>$carsCount</td><td>" . ($carsCount > 0 ? '<span class="success">✅ Has data</span>' : '<span class="error">⚠️ Empty</span>') . "</td></tr>";
        echo "<tr><td>Motorcycles</td><td>$motorcyclesCount</td><td>" . ($motorcyclesCount > 0 ? '<span class="success">✅ Has data</span>' : '<span class="error">⚠️ Empty</span>') . "</td></tr>";
        echo "</table>";
        echo '</div>';

        // Test 4: Get Owner IDs
        echo '<div class="test-section">';
        echo '<h2>4. Owner IDs in Bookings</h2>';
        $ownerResult = mysqli_query($conn, "SELECT DISTINCT owner_id, COUNT(*) as bookings FROM bookings GROUP BY owner_id LIMIT 10");
        if (mysqli_num_rows($ownerResult) > 0) {
            echo "<table>";
            echo "<tr><th>Owner ID</th><th>Bookings Count</th></tr>";
            while ($row = mysqli_fetch_assoc($ownerResult)) {
                echo "<tr><td>{$row['owner_id']}</td><td>{$row['bookings']}</td></tr>";
            }
            echo "</table>";
        } else {
            echo '<p class="error">⚠️ No owner_id found in bookings</p>';
        }
        echo '</div>';

        // Test 5: Test Overview Query
        echo '<div class="test-section">';
        echo '<h2>5. Test Overview Query (Owner ID = 1)</h2>';
        $owner_id = 1;
        $whereAnd = "WHERE owner_id = $owner_id AND";
        
        $query = "SELECT COUNT(*) as count FROM bookings WHERE owner_id = $owner_id";
        $result = mysqli_query($conn, $query);
        if ($result) {
            $data = mysqli_fetch_assoc($result);
            echo '<p class="success">✅ Query executed successfully</p>';
            echo "<p>Total bookings for owner $owner_id: <strong>{$data['count']}</strong></p>";
        } else {
            echo '<p class="error">❌ Query failed: ' . mysqli_error($conn) . '</p>';
        }
        echo '</div>';

        // Test 6: Test API Endpoint
        echo '<div class="test-section">';
        echo '<h2>6. Test API Endpoint</h2>';
        $apiUrl = 'http://10.218.197.49/carGOAdmin/api/analytics/get_analytics_data.php?type=overview&owner_id=1';
        echo '<p class="info">Testing URL: <a href="' . $apiUrl . '" target="_blank">' . $apiUrl . '</a></p>';
        
        $apiResponse = @file_get_contents($apiUrl);
        if ($apiResponse) {
            echo '<p class="success">✅ API responded</p>';
            echo '<h3>Response:</h3>';
            echo '<pre>' . htmlspecialchars($apiResponse) . '</pre>';
            
            $json = json_decode($apiResponse, true);
            if ($json) {
                echo '<h3>Parsed JSON:</h3>';
                echo '<pre>' . print_r($json, true) . '</pre>';
            } else {
                echo '<p class="error">❌ Failed to parse JSON response</p>';
            }
        } else {
            echo '<p class="error">❌ Failed to connect to API endpoint</p>';
            echo '<p>Make sure the API file exists at: cargoAdmin/api/analytics/get_analytics_data.php</p>';
        }
        echo '</div>';

        // Test 7: Sample Data Query
        echo '<div class="test-section">';
        echo '<h2>7. Sample Bookings Data</h2>';
        $sampleQuery = "SELECT id, owner_id, car_id, vehicle_type, status, total_amount, created_at 
                        FROM bookings 
                        ORDER BY created_at DESC 
                        LIMIT 5";
        $sampleResult = mysqli_query($conn, $sampleQuery);
        
        if ($sampleResult && mysqli_num_rows($sampleResult) > 0) {
            echo '<table>';
            echo '<tr><th>ID</th><th>Owner ID</th><th>Car ID</th><th>Type</th><th>Status</th><th>Amount</th><th>Date</th></tr>';
            while ($row = mysqli_fetch_assoc($sampleResult)) {
                echo '<tr>';
                echo '<td>' . $row['id'] . '</td>';
                echo '<td>' . $row['owner_id'] . '</td>';
                echo '<td>' . $row['car_id'] . '</td>';
                echo '<td>' . $row['vehicle_type'] . '</td>';
                echo '<td>' . $row['status'] . '</td>';
                echo '<td>₱' . number_format($row['total_amount'], 2) . '</td>';
                echo '<td>' . date('Y-m-d', strtotime($row['created_at'])) . '</td>';
                echo '</tr>';
            }
            echo '</table>';
        } else {
            echo '<p class="error">⚠️ No bookings found</p>';
        }
        echo '</div>';

        mysqli_close($conn);
        ?>

        <div class="test-section">
            <h2>📋 Summary</h2>
            <p>If you see ⚠️ warnings about empty tables, you need to add test data to your database.</p>
            <p>Check the API response above to see what data is being returned to the app.</p>
        </div>
    </div>
</body>
</html>
