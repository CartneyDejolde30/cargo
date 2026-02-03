# 🚀 Running CarGO Without XAMPP - Quick Setup Guide

## ✅ Current Status

Your app is **NOW CONFIGURED** to run directly with Hostinger - no XAMPP needed!

---

## 📋 What's Already Done

### 1. ✅ Flutter App Configuration
- **File:** `lib/config/api_config.dart`
- **Status:** Already set to production mode (`isDevelopment = false`)
- **Points to:** `http://cargoph.online/carGOAdmin`

### 2. ✅ PHP Backend Configuration  
- **File:** `cargoAdmin/include/config.php`
- **Status:** Auto-detects environment
- **Hostinger Database:**
  - Host: `localhost`
  - User: `u672913452_ethan`
  - Database: `u672913452_dbcargo`

### 3. ✅ Database Ready
- **File:** `dbcargo (23)_hostinger_clean.sql`
- **Status:** Ready to import (DEFINER clauses removed)

---

## 🎯 What You Need to Do

### Step 1: Import Database to Hostinger ⏳

1. **Login to Hostinger** control panel
2. **Open phpMyAdmin**
3. **Select database:** `u672913452_dbcargo`
4. **Click "Import" tab**
5. **Choose file:** `dbcargo (23)_hostinger_clean.sql`
6. **Click "Go"** and wait for completion

### Step 2: Upload PHP Files to Hostinger 📤

You need to upload your `cargoAdmin` folder to Hostinger:

**Option A: Using File Manager (Recommended)**
1. Login to Hostinger
2. Go to **File Manager**
3. Navigate to `public_html/`
4. Upload the entire `cargoAdmin` folder
5. Make sure the structure is: `public_html/carGOAdmin/`

**Option B: Using FTP**
1. Use FileZilla or any FTP client
2. Connect to your Hostinger FTP:
   - Host: Your Hostinger FTP host
   - Username: Your FTP username
   - Password: Your FTP password
3. Upload `cargoAdmin` folder to `public_html/carGOAdmin/`

### Step 3: Verify File Permissions 🔐

In Hostinger File Manager, set these permissions:
- `carGOAdmin/uploads/` → **755** (Read, Write, Execute)
- `carGOAdmin/logs/` → **755** (create this folder if it doesn't exist)

### Step 4: Test Backend Connection 🧪

Open in your browser:
```
http://cargoph.online/carGOAdmin/include/config.php?show_config
```

You should see:
- ✅ Environment: **PRODUCTION**
- ✅ DB Name: **u672913452_dbcargo**
- ✅ Base URL: **http://cargoph.online/carGOAdmin**

### Step 5: Run Flutter App 📱

```bash
flutter clean
flutter pub get
flutter run
```

Or for release mode:
```bash
flutter run --release
```

---

## 🌐 Your App URLs

### Backend URLs
- **Admin Panel:** `http://cargoph.online/carGOAdmin/`
- **API Base:** `http://cargoph.online/carGOAdmin/api/`
- **Login API:** `http://cargoph.online/carGOAdmin/login.php`

### Test Endpoints
- Config Test: `http://cargoph.online/carGOAdmin/include/config.php?show_config`
- DB Test: `http://cargoph.online/carGOAdmin/test_connection.php`

---

## 🔧 Troubleshooting

### Problem: "Connection Failed"
**Solution:** Make sure you've uploaded all PHP files to Hostinger

### Problem: "Database Error"
**Solution:** 
1. Check database is imported correctly
2. Verify credentials in `config.php`
3. Make sure database name is `u672913452_dbcargo`

### Problem: "404 Not Found"
**Solution:** 
1. Verify folder name is `carGOAdmin` (case-sensitive)
2. Check .htaccess file is uploaded
3. Ensure files are in `public_html/carGOAdmin/`

### Problem: "Images Not Loading"
**Solution:**
1. Upload `uploads` folder to Hostinger
2. Set folder permission to 755
3. Check image paths in database

### Problem: "CORS Error"
**Solution:** Already configured in `config.php` - but verify:
```php
header('Access-Control-Allow-Origin: http://cargoph.online');
```

---

## 📝 Important Notes

### ✅ You DON'T Need XAMPP Anymore!
- Your PHP files will run on Hostinger's servers
- Your MySQL database is on Hostinger
- Flutter app connects directly to Hostinger

### ⚠️ Keep XAMPP for Local Development
- If you want to test changes locally, keep XAMPP
- Switch `isDevelopment = true` in `api_config.dart`
- Switch back to `false` before building release

### 🔒 Security Checklist
- [ ] Database password is secure
- [ ] Remove `?show_config` access in production
- [ ] Set proper file permissions (755 for folders, 644 for files)
- [ ] Enable HTTPS (SSL) on Hostinger for security

---

## 🎉 Next Steps After Setup

1. **Test user registration and login**
2. **Upload some test vehicles**
3. **Create test bookings**
4. **Test GPS tracking**
5. **Verify payment flows**
6. **Test notifications**

---

## 📞 Quick Reference

### Hostinger Database Credentials
```
Host: localhost
Username: u672913452_ethan
Password: Cityhunter_23
Database: u672913452_dbcargo
```

### Flutter Configuration
```dart
// lib/config/api_config.dart
static const bool isDevelopment = false; // Production mode
static const String _prodDomain = 'cargoph.online';
```

### PHP Configuration
```php
// cargoAdmin/include/config.php
// Auto-detects production when not on localhost
define('DB_NAME', 'u672913452_dbcargo');
define('BASE_URL', 'http://cargoph.online/carGOAdmin');
```

---

## ✨ You're Ready!

Once you complete Steps 1-4 above, you can run your Flutter app and it will connect directly to Hostinger - **no XAMPP needed!**

Good luck! 🚀
