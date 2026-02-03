# CarGO Philippines - Hostinger Deployment Guide

## 🌐 Domain Information
- **Primary Domain:** http://cargoph.online
- **WWW Domain:** http://www.cargoph.online
- **Server IP:** 145.79.25.36

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [File Upload & Configuration](#file-upload--configuration)
4. [Flutter App Configuration](#flutter-app-configuration)
5. [Testing & Verification](#testing--verification)
6. [SSL Certificate Setup (HTTPS)](#ssl-certificate-setup)
7. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

### Required Information from Hostinger:
- ✅ Domain: cargoph.online (already configured)
- ✅ Server IP: 145.79.25.36
- 🔑 **Database credentials** (Get these from Hostinger cPanel)
  - Database Host (usually `localhost`)
  - Database Name
  - Database Username
  - Database Password

### Access Requirements:
- Hostinger cPanel login
- FTP/SFTP credentials OR File Manager access
- MySQL database access via phpMyAdmin

---

## 2. Database Setup

### Step 1: Create Database on Hostinger

1. Log in to **Hostinger cPanel**
2. Go to **MySQL Databases**
3. Create a new database:
   ```
   Database Name: u476920059_dbcargo (or similar - Hostinger auto-prefixes)
   ```
4. Create a database user:
   ```
   Username: u476920059_cargo
   Password: [Create a strong password]
   ```
5. Add user to database with **ALL PRIVILEGES**

### Step 2: Import Database

1. Open **phpMyAdmin** from cPanel
2. Select your database
3. Click **Import** tab
4. Upload `dbcargo (22).sql` from your project root
5. Click **Go** to import

### Step 3: Update Configuration File

Edit `cargoAdmin/include/config.php` (lines 25-29):

```php
// PRODUCTION SETTINGS (Hostinger)
define('DB_HOST', 'localhost'); // Usually localhost on Hostinger
define('DB_USER', 'u476920059_cargo'); // Your actual DB username
define('DB_PASS', 'YourActualPassword'); // Your actual DB password
define('DB_NAME', 'u476920059_dbcargo'); // Your actual DB name
```

---

## 3. File Upload & Configuration

### Method 1: Using File Manager (Recommended for Beginners)

1. **Access File Manager**
   - Log in to Hostinger cPanel
   - Open **File Manager**
   - Navigate to `public_html` directory

2. **Upload Files**
   - Create folder: `carGOAdmin` inside `public_html`
   - Upload all files from `cargoAdmin/` folder to `public_html/carGOAdmin/`
   - **Important folders to upload:**
     - `api/` (all API endpoints)
     - `include/` (database & config files)
     - `uploads/` (with proper permissions)
     - All PHP files in root

3. **Set Folder Permissions**
   - Right-click `uploads/` folder → Permissions → Set to `755`
   - Right-click `uploads/odometer/` → Permissions → Set to `755`
   - Right-click `uploads/verifications/` → Permissions → Set to `755`
   - Right-click `uploads/reports/` → Permissions → Set to `755`
   - Right-click `uploads/profile_images/` → Permissions → Set to `755`
   - Right-click `uploads/payout_proofs/` → Permissions → Set to `755`

### Method 2: Using FTP/SFTP (For Advanced Users)

1. **Connect via FTP Client** (FileZilla recommended)
   ```
   Host: ftp.cargoph.online or 145.79.25.36
   Username: [Your FTP username]
   Password: [Your FTP password]
   Port: 21 (FTP) or 22 (SFTP)
   ```

2. **Upload Structure**
   ```
   public_html/
   └── carGOAdmin/
       ├── api/
       ├── include/
       │   ├── config.php (UPDATED)
       │   └── db.php
       ├── uploads/
       ├── login.php
       ├── register.php
       └── [all other PHP files]
   ```

### Critical Configuration Check

**File: `cargoAdmin/include/config.php`** (Already created)
- ✅ Automatically detects environment (localhost vs production)
- ✅ Uses production settings on Hostinger
- ✅ Base URL automatically set to `http://cargoph.online/carGOAdmin`

---

## 4. Flutter App Configuration

### Step 1: Update API Configuration

**File: `lib/config/api_config.dart` (Already created)**

Change line 13 from:
```dart
static const bool isDevelopment = false; // ← SET TO false FOR PRODUCTION
```

To:
```dart
static const bool isDevelopment = false; // ✅ PRODUCTION MODE
```

### Step 2: Verify Configuration

The app will automatically use:
```
Base URL: http://cargoph.online/carGOAdmin
API URL: http://cargoph.online/carGOAdmin/api
Uploads: http://cargoph.online/carGOAdmin/uploads
```

### Step 3: Test Configuration

Run this in your project:
```dart
import 'package:flutter_application_1/config/api_config.dart';

void main() {
  GlobalApiConfig.printConfig();
}
```

Expected output:
```
========================================
API CONFIGURATION
========================================
Environment: PRODUCTION
Base URL: http://cargoph.online/carGOAdmin
API URL: http://cargoph.online/carGOAdmin/api
Uploads URL: http://cargoph.online/carGOAdmin/uploads
========================================
```

### Step 4: Build Production App

```bash
# For Android
flutter build apk --release

# For iOS (requires Mac)
flutter build ios --release

# For Web
flutter build web --release
```

---

## 5. Testing & Verification

### Backend API Tests

1. **Test Database Connection**
   ```
   URL: http://cargoph.online/carGOAdmin/include/config.php?show_config
   Expected: Shows configuration (only works in development mode)
   ```

2. **Test Login API**
   ```
   URL: http://cargoph.online/carGOAdmin/login.php
   Method: POST
   Body: {"email": "test@example.com", "password": "password"}
   ```

3. **Test Get Cars API**
   ```
   URL: http://cargoph.online/carGOAdmin/api/get_cars.php
   Method: GET
   Expected: JSON response with cars data
   ```

4. **Test Image Upload**
   - Upload test via admin panel
   - Verify image appears at: `http://cargoph.online/carGOAdmin/uploads/[filename]`

### Frontend App Tests

1. **Test Login**
   - Open app → Login with test credentials
   - Should connect to production backend

2. **Test Car Listings**
   - View cars → Should load from Hostinger
   - Images should display correctly

3. **Test Booking**
   - Create a test booking
   - Verify it appears in database

---

## 6. SSL Certificate Setup (HTTPS)

### Why HTTPS is Important:
- Secure data transmission
- Required for payment APIs
- Better SEO ranking
- User trust

### Step 1: Enable SSL in Hostinger

1. Log in to **Hostinger cPanel**
2. Go to **SSL/TLS Status**
3. Find `cargoph.online` and `www.cargoph.online`
4. Click **Run AutoSSL** or **Install Certificate**
5. Wait 10-15 minutes for certificate activation

### Step 2: Force HTTPS (Create .htaccess)

Create file: `public_html/.htaccess`

```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Force WWW (optional)
RewriteCond %{HTTP_HOST} !^www\.
RewriteRule ^(.*)$ https://www.%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

### Step 3: Update Configuration for HTTPS

**File: `cargoAdmin/include/config.php`**

Change line 35 to:
```php
define('BASE_URL', 'https://cargoph.online/carGOAdmin'); // Changed to HTTPS
```

**File: `lib/config/api_config.dart`**

Change line 23 to:
```dart
static const String _prodBaseUrl = 'https://cargoph.online/carGOAdmin'; // Changed to HTTPS
```

### Step 4: Rebuild & Redeploy

```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 7. Troubleshooting

### Issue: "Database connection failed"

**Solution:**
1. Check `cargoAdmin/include/config.php` has correct credentials
2. Verify database user has ALL PRIVILEGES
3. Check if database exists in phpMyAdmin
4. Test connection via terminal:
   ```bash
   mysql -h localhost -u u476920059_cargo -p u476920059_dbcargo
   ```

### Issue: "404 Not Found" on API calls

**Solution:**
1. Verify folder structure: `public_html/carGOAdmin/api/`
2. Check file permissions (should be 644 for files, 755 for folders)
3. Clear browser cache
4. Test direct URL: `http://cargoph.online/carGOAdmin/api/get_cars.php`

### Issue: Images not loading

**Solution:**
1. Check `uploads/` folder permissions (should be 755)
2. Verify images exist: `http://cargoph.online/carGOAdmin/uploads/`
3. Check file ownership (should be your FTP user)
4. Ensure `.htaccess` allows image access:
   ```apache
   <FilesMatch "\.(jpg|jpeg|png|gif)$">
       Allow from all
   </FilesMatch>
   ```

### Issue: CORS errors in browser console

**Solution:**
The `config.php` already handles CORS. If issues persist:

1. Add to `cargoAdmin/api/.htaccess`:
   ```apache
   Header set Access-Control-Allow-Origin "*"
   Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
   Header set Access-Control-Allow-Headers "Content-Type, Authorization"
   ```

### Issue: "Unable to connect to server"

**Solution:**
1. Check domain DNS propagation: https://dnschecker.org
   - Search: cargoph.online
   - Should point to: 145.79.25.36
2. Wait 24-48 hours if recently changed
3. Clear DNS cache:
   ```bash
   # Windows
   ipconfig /flushdns
   
   # Mac/Linux
   sudo killall -HUP mDNSResponder
   ```

### Issue: App works on WiFi but not on mobile data

**Solution:**
1. Ensure firewall allows HTTP/HTTPS
2. Check if ISP blocks certain ports
3. Use HTTPS (more reliable on mobile networks)

---

## 📝 Deployment Checklist

### Pre-Deployment
- [ ] Database created on Hostinger
- [ ] Database user created with privileges
- [ ] Database imported successfully
- [ ] `config.php` updated with correct credentials
- [ ] All files uploaded to `public_html/carGOAdmin/`
- [ ] Folder permissions set correctly

### Configuration
- [ ] `lib/config/api_config.dart` set to production mode
- [ ] Flutter app rebuilt for production
- [ ] Backend tested via browser/Postman
- [ ] Frontend tested on device

### Optional but Recommended
- [ ] SSL certificate enabled
- [ ] HTTPS forced via .htaccess
- [ ] Error logging configured
- [ ] Backup system set up
- [ ] Monitoring/analytics added

---

## 🚀 Quick Start Commands

### Switch to Production Mode
```dart
// lib/config/api_config.dart
static const bool isDevelopment = false; // Set to false
```

### Rebuild App
```bash
flutter clean && flutter pub get && flutter build apk --release
```

### Test Backend
```bash
curl http://cargoph.online/carGOAdmin/api/get_cars.php
```

---

## 📞 Support & Resources

### Hostinger Support
- Knowledge Base: https://support.hostinger.com
- Live Chat: Available 24/7
- Ticket System: Via cPanel

### Development Resources
- Flutter Docs: https://flutter.dev/docs
- PHP Manual: https://www.php.net/manual/en/
- MySQL Docs: https://dev.mysql.com/doc/

### Project Files
- Database: `dbcargo (22).sql`
- Config: `cargoAdmin/include/config.php`
- API Config: `lib/config/api_config.dart`

---

## ⚠️ Important Security Notes

1. **Never commit credentials to Git**
   - `config.php` contains sensitive info
   - Add to `.gitignore`

2. **Use strong passwords**
   - Database password
   - Admin accounts
   - FTP credentials

3. **Regular backups**
   - Database (weekly)
   - Files (monthly)
   - Use Hostinger backup tools

4. **Keep software updated**
   - Flutter SDK
   - PHP version (check Hostinger)
   - Dependencies

---

## 🎉 Deployment Complete!

After following this guide:
- ✅ App connects to: http://cargoph.online
- ✅ API accessible at: http://cargoph.online/carGOAdmin/api
- ✅ Images load from: http://cargoph.online/carGOAdmin/uploads
- ✅ Database hosted on Hostinger
- ✅ Ready for production use!

---

**Last Updated:** 2026-02-03
**Version:** 1.0.0
**Author:** CarGO Philippines Development Team
