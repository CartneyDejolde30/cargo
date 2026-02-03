# 📝 Stored Procedure Setup Instructions

## ⚠️ Important Note

The stored procedure you have uses `DEFINER=root@localhost` which **will not work on Hostinger** because:
- Shared hosting doesn't allow root access
- DEFINER clause requires special privileges

---

## ✅ Solution: Fixed Version Created

I've created a **Hostinger-compatible version**: `hostinger_stored_procedure.sql`

### What Changed:
- ❌ Removed: `DEFINER=root@localhost`
- ✅ Added: Proper delimiter handling
- ✅ Added: DROP IF EXISTS (safe re-import)
- ✅ Works on: Shared hosting environments

---

## 🚀 How to Install on Hostinger

### Method 1: Via phpMyAdmin (Recommended)

1. **Login to Hostinger cPanel**
   - Go to https://hpanel.hostinger.com
   - Open phpMyAdmin

2. **Select Your Database**
   - Click on: `u672913452_dbcargo`

3. **Open SQL Tab**
   - Click the **SQL** tab at the top

4. **Copy and Paste**
   - Open `hostinger_stored_procedure.sql`
   - Copy the entire content
   - Paste into the SQL query box

5. **Execute**
   - Click **Go** button
   - Should see: "Procedure created successfully"

### Method 2: Via SQL File Import

1. **In phpMyAdmin**
   - Select database: `u672913452_dbcargo`

2. **Click Import Tab**
   - Choose file: `hostinger_stored_procedure.sql`
   - Click **Go**

---

## 🧪 Testing the Procedure

After installation, test it with this query:

```sql
CALL sp_get_vehicle_availability(1, 'car', '2026-02-01', '2026-02-28');
```

**Expected Result:**
- Returns list of blocked/booked dates
- Columns: date, status, reason

---

## 📊 What This Procedure Does

### Purpose:
Checks vehicle availability by returning all blocked and booked dates for a specific vehicle.

### Parameters:
- `p_vehicle_id` - Vehicle ID to check
- `p_vehicle_type` - 'car' or 'motorcycle'
- `p_start_date` - Start date of range
- `p_end_date` - End date of range

### Returns:
| Column | Type | Description |
|--------|------|-------------|
| date | DATE | The blocked/booked date |
| status | VARCHAR | 'blocked' or 'booked' |
| reason | VARCHAR | Why it's unavailable |

---

## 🔧 Troubleshooting

### Error: "Access denied for procedure"
**Solution:** Make sure you're logged in as `u672913452_ethan` in phpMyAdmin

### Error: "PROCEDURE already exists"
**Solution:** Run this first to drop it:
```sql
DROP PROCEDURE IF EXISTS sp_get_vehicle_availability;
```

### Error: "Delimiter issue"
**Solution:** Use phpMyAdmin's SQL tab (it handles delimiters automatically)

---

## 📦 Including in Main Database Export

### Option 1: Add to dbcargo (22).sql
Add the stored procedure at the **end** of your main SQL file:

```sql
-- ... existing tables and data ...

-- Add this at the end:
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_get_vehicle_availability$$
CREATE PROCEDURE sp_get_vehicle_availability(...)
BEGIN
  ...
END$$
DELIMITER ;
```

### Option 2: Import Separately
1. Import `dbcargo (22).sql` first (tables & data)
2. Then import `hostinger_stored_procedure.sql` (procedure)

---

## ✅ Verification Checklist

After installation, verify:

- [ ] Procedure appears in phpMyAdmin under "Routines"
- [ ] Test query returns results without errors
- [ ] App calendar features work correctly
- [ ] No "procedure not found" errors in logs

---

## 🔍 Where This Procedure Is Used

Search your code for these patterns to see where it's called:

```php
// PHP usage
$stmt = $conn->prepare("CALL sp_get_vehicle_availability(?, ?, ?, ?)");
$stmt->bind_param("isss", $vehicle_id, $vehicle_type, $start_date, $end_date);
```

```dart
// Dart/Flutter usage (via API)
// Calls PHP API that uses this procedure
```

---

## 💡 Best Practices

1. **Always use prepared statements** when calling procedures
2. **Test on local first** before deploying to Hostinger
3. **Keep a backup** of your procedure code
4. **Document changes** when modifying the procedure

---

## 🎯 Quick Commands

**Drop Procedure:**
```sql
DROP PROCEDURE IF EXISTS sp_get_vehicle_availability;
```

**Check if Exists:**
```sql
SHOW PROCEDURE STATUS WHERE Name = 'sp_get_vehicle_availability';
```

**View Definition:**
```sql
SHOW CREATE PROCEDURE sp_get_vehicle_availability;
```

---

## 📞 Support

If you encounter issues:
1. Check phpMyAdmin error messages
2. Verify database user permissions
3. Contact Hostinger support if permission errors persist
4. Reference: `DEPLOYMENT_GUIDE.md`

---

**Created:** 2026-02-03  
**For:** CarGO Philippines  
**Database:** u672913452_dbcargo  
**Status:** Ready for deployment ✅
