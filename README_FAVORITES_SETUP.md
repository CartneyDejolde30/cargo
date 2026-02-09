# 🔧 Favorites System - Setup & Troubleshooting Guide

## ⚠️ Issue: Favorites Not Showing

If you added a car to favorites but it's not showing, follow these steps:

## 🚀 Quick Fix - Setup Database Table

### Step 1: Create the Favorites Table

**Option A: Using phpMyAdmin or MySQL Client**

1. Open your database management tool (phpMyAdmin, MySQL Workbench, etc.)
2. Select your database (usually `u672913452_dbcargo` based on your SQL file)
3. Run this SQL command:

```sql
CREATE TABLE IF NOT EXISTS favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_type ENUM('car', 'motorcycle') NOT NULL,
    vehicle_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_favorite (user_id, vehicle_type, vehicle_id),
    INDEX idx_user_id (user_id),
    INDEX idx_vehicle_type (vehicle_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Option B: Using the Auto-Create Script**

1. Open your browser
2. Navigate to: `https://your-domain.com/cargoAdmin/api/favorites/create_table_if_not_exists.php`
3. You should see a success message:
   ```json
   {
     "status": "success",
     "message": "Favorites table created successfully",
     "total_favorites": 0
   }
   ```

### Step 2: Test the Setup

Navigate to: `https://your-domain.com/cargoAdmin/api/favorites/test_favorites_setup.php`

You should see:
```json
{
  "table_exists": true,
  "table_structure": [...],
  "total_favorites": 0,
  "api_endpoints": {
    "add_favorite.php": true,
    "remove_favorite.php": true,
    "get_favorites.php": true,
    "check_favorite.php": true
  }
}
```

### Step 3: Test Adding a Favorite

**Using the Debug Script:**

Navigate to: `https://your-domain.com/cargoAdmin/api/favorites/debug_add_favorite.php`

Add these POST parameters (you can use Postman, browser console, or curl):
```
user_id=1
vehicle_type=car
vehicle_id=1
```

Example using browser console:
```javascript
fetch('https://your-domain.com/cargoAdmin/api/favorites/debug_add_favorite.php', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: 'user_id=1&vehicle_type=car&vehicle_id=1'
})
.then(r => r.json())
.then(console.log);
```

### Step 4: Verify in the App

1. Close and restart your Flutter app
2. Navigate to a car or motorcycle
3. Tap the heart icon
4. Navigate to Favorites (heart icon in bottom navigation)
5. Your favorited items should now appear!

## 🔍 Troubleshooting

### Problem: Table doesn't exist error
**Solution:** Run the SQL creation script from Step 1

### Problem: "Already exists" but not showing in app
**Solution:** 
1. Check the Flutter app is using the correct API endpoint
2. Verify your `api_config.dart` has the correct base URL
3. Clear app cache: `flutter clean && flutter run`

### Problem: API returns "Invalid user ID"
**Solution:** 
1. Make sure you're logged in
2. Check SharedPreferences has `user_id` stored
3. In the app, go to Profile screen to verify user data

### Problem: Heart icon doesn't turn red
**Solution:**
1. Check browser/app console for API errors
2. Verify internet connection
3. Check CORS headers are allowing requests

## 🧪 Manual Database Check

Run this query to see all favorites:
```sql
SELECT * FROM favorites;
```

Run this query to see favorites for a specific user:
```sql
SELECT * FROM favorites WHERE user_id = 1;
```

Run this query to see favorites with vehicle details:
```sql
SELECT f.*, c.brand, c.model 
FROM favorites f 
LEFT JOIN cars c ON f.vehicle_id = c.id AND f.vehicle_type = 'car'
WHERE f.user_id = 1;
```

## 📁 Files Created for Testing

1. `public_html/cargoAdmin/api/favorites/create_table_if_not_exists.php` - Auto-creates table
2. `public_html/cargoAdmin/api/favorites/test_favorites_setup.php` - Tests setup
3. `public_html/cargoAdmin/api/favorites/debug_add_favorite.php` - Debug adding favorites

## ✅ Success Checklist

- [ ] Favorites table exists in database
- [ ] Table has correct structure (5 columns)
- [ ] API endpoints exist and are accessible
- [ ] Can add favorite via debug script
- [ ] Can see favorites in database
- [ ] App shows favorites in Favorites screen
- [ ] Heart icon turns red when favorited
- [ ] Can remove favorites

## 🆘 Still Not Working?

Check these common issues:

1. **Database connection**: Verify `public_html/cargoAdmin/include/db.php` has correct credentials
2. **API URL**: Check `lib/config/api_config.dart` has correct base URL
3. **User ID**: Verify user is logged in and user_id is stored
4. **CORS**: Check API allows cross-origin requests
5. **Permissions**: Ensure database user has CREATE/INSERT/SELECT permissions

---

**Need more help?** Check the console logs in your Flutter app and browser network tab for specific error messages.
