# 🚀 CarGO Philippines - Hostinger Deployment Checklist

## ✅ Pre-Deployment Setup

### Step 1: Get Hostinger Credentials
- [ ] Login to Hostinger cPanel: https://hpanel.hostinger.com
- [ ] Navigate to MySQL Databases
- [ ] Note down your database credentials:
  ```
  DB Host: _____________ (usually localhost)
  DB User: _____________
  DB Pass: _____________
  DB Name: _____________
  ```

### Step 2: Update Backend Configuration
- [ ] Open `cargoAdmin/include/config.php`
- [ ] Update lines 25-29 with your actual credentials:
  ```php
  define('DB_HOST', 'localhost');
  define('DB_USER', 'your_actual_username');
  define('DB_PASS', 'your_actual_password');
  define('DB_NAME', 'your_actual_database');
  ```
- [ ] Save the file

### Step 3: Database Setup
- [ ] Open phpMyAdmin in Hostinger cPanel
- [ ] Create new database (if not exists)
- [ ] Click Import tab
- [ ] Upload `dbcargo (22).sql` from project root
- [ ] Click Go and wait for completion
- [ ] Verify tables are imported (should see 20+ tables)

---

## 📤 File Upload to Hostinger

### Method A: File Manager (Recommended)
- [ ] Open File Manager in cPanel
- [ ] Navigate to `public_html` folder
- [ ] Create new folder: `carGOAdmin`
- [ ] Upload ALL files from local `cargoAdmin/` to `public_html/carGOAdmin/`
- [ ] Verify folder structure:
  ```
  public_html/carGOAdmin/
  ├── api/
  ├── include/
  │   ├── config.php ✅
  │   └── db.php
  ├── uploads/
  ├── .htaccess ✅
  ├── login.php
  ├── register.php
  └── [all other files]
  ```

### Method B: FTP Upload (Alternative)
- [ ] Connect via FileZilla or similar
  ```
  Host: ftp.cargoph.online
  Username: [Your FTP username]
  Password: [Your FTP password]
  ```
- [ ] Upload to `/public_html/carGOAdmin/`

### Set Folder Permissions
- [ ] Right-click `uploads/` → Permissions → Set to `755`
- [ ] Right-click `uploads/odometer/` → Permissions → Set to `755`
- [ ] Right-click `uploads/verifications/` → Permissions → Set to `755`
- [ ] Right-click `uploads/reports/` → Permissions → Set to `755`
- [ ] Right-click `uploads/profile_images/` → Permissions → Set to `755`
- [ ] Right-click `uploads/payout_proofs/` → Permissions → Set to `755`

---

## 🧪 Backend Testing

### Test Database Connection
- [ ] Visit: http://cargoph.online/carGOAdmin/login.php
- [ ] Should load without errors
- [ ] Try logging in with test account

### Test API Endpoints
- [ ] Open: http://cargoph.online/carGOAdmin/api/get_cars.php
- [ ] Should return JSON with cars data
- [ ] Check response status is 200

### Test Image Access
- [ ] Upload a test image via admin panel
- [ ] Verify accessible at: http://cargoph.online/carGOAdmin/uploads/[filename]
- [ ] Image should display in browser

---

## 📱 Flutter App Configuration

### Update Configuration
- [ ] Open `lib/config/api_config.dart`
- [ ] Locate line 13: `static const bool isDevelopment = false;`
- [ ] Ensure it's set to `false` for production
- [ ] Save the file

### Verify Configuration
- [ ] Check the production URLs are set:
  ```dart
  static const String _prodDomain = 'cargoph.online';
  static const String _prodBasePath = 'carGOAdmin';
  static const String _prodBaseUrl = 'http://$_prodDomain/$_prodBasePath';
  ```

### Clean and Rebuild
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter analyze` (check for errors)
- [ ] Run: `flutter build apk --release`
- [ ] Locate APK at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 App Testing

### Installation
- [ ] Transfer APK to Android device
- [ ] Install the app
- [ ] Open the app

### Core Functionality Tests
- [ ] **Login Test**
  - [ ] Try logging in with existing account
  - [ ] Should connect to production backend
  - [ ] Verify login successful

- [ ] **Car Listings Test**
  - [ ] View car listings
  - [ ] Cars should load from Hostinger
  - [ ] Images should display correctly
  - [ ] Click on a car to view details

- [ ] **Search & Filter Test**
  - [ ] Try searching for cars
  - [ ] Apply filters
  - [ ] Results should update

- [ ] **Booking Test**
  - [ ] Select a car
  - [ ] Try creating a booking
  - [ ] Verify booking appears in database

- [ ] **Profile Test**
  - [ ] View profile
  - [ ] Try updating profile
  - [ ] Upload profile picture

- [ ] **Image Loading Test**
  - [ ] All car images load correctly
  - [ ] Profile images load
  - [ ] No broken image icons

---

## 🔒 Security Checklist

### Backend Security
- [ ] Database credentials not committed to Git
- [ ] `config.php` added to `.gitignore`
- [ ] Strong database password used
- [ ] File permissions set correctly (755/644)
- [ ] `.htaccess` file uploaded and working

### App Security
- [ ] Production mode enabled (isDevelopment = false)
- [ ] No debug logs in production
- [ ] API keys secured
- [ ] Firebase credentials properly configured

---

## 🌐 Optional: HTTPS Setup

### Enable SSL Certificate
- [ ] Go to Hostinger cPanel → SSL/TLS
- [ ] Find `cargoph.online`
- [ ] Click "Install SSL Certificate"
- [ ] Wait 10-15 minutes for activation

### Update Configuration for HTTPS
- [ ] Edit `cargoAdmin/include/config.php` line 35:
  ```php
  define('BASE_URL', 'https://cargoph.online/carGOAdmin');
  ```
- [ ] Edit `lib/config/api_config.dart` line 23:
  ```dart
  static const String _prodBaseUrl = 'https://cargoph.online/carGOAdmin';
  ```
- [ ] Rebuild app: `flutter build apk --release`

### Force HTTPS (Recommended)
- [ ] Create `public_html/.htaccess` with:
  ```apache
  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
  ```

---

## 📊 Verification Tests

### URLs to Test
- [ ] http://cargoph.online/carGOAdmin/
- [ ] http://cargoph.online/carGOAdmin/api/get_cars.php
- [ ] http://cargoph.online/carGOAdmin/login.php
- [ ] http://cargoph.online/carGOAdmin/uploads/

### Expected Results
- ✅ All URLs should load without 404 errors
- ✅ APIs return proper JSON responses
- ✅ Images display correctly
- ✅ Admin panel accessible

---

## 🐛 Troubleshooting

### If "Database connection failed"
- [ ] Check credentials in `config.php`
- [ ] Verify database exists in phpMyAdmin
- [ ] Test database connection in cPanel

### If "404 Not Found"
- [ ] Verify files uploaded to `public_html/carGOAdmin/`
- [ ] Check folder name is exactly `carGOAdmin` (case-sensitive)
- [ ] Clear browser cache

### If images not loading
- [ ] Check `uploads/` folder permissions (755)
- [ ] Verify images exist in uploads folder
- [ ] Test direct image URL in browser

### If app can't connect
- [ ] Verify `isDevelopment = false`
- [ ] Check internet connection on device
- [ ] Test API URLs in browser first
- [ ] Rebuild app after config changes

---

## ✅ Final Verification

### Backend Checklist
- [ ] ✅ Database imported successfully
- [ ] ✅ Config file updated with credentials
- [ ] ✅ All files uploaded to Hostinger
- [ ] ✅ Folder permissions set correctly
- [ ] ✅ APIs responding correctly
- [ ] ✅ Images accessible

### Frontend Checklist
- [ ] ✅ Production mode enabled
- [ ] ✅ App rebuilt for production
- [ ] ✅ Login working
- [ ] ✅ Car listings working
- [ ] ✅ Images displaying
- [ ] ✅ Bookings working
- [ ] ✅ All features tested

### Documentation
- [ ] ✅ Credentials saved securely
- [ ] ✅ Backup of database created
- [ ] ✅ Deployment guide reviewed
- [ ] ✅ Team members informed

---

## 🎉 Deployment Complete!

When all items are checked:
- ✅ Your app is live at: **http://cargoph.online**
- ✅ Users can access the application
- ✅ All features working correctly
- ✅ Ready for production use

---

## 📞 Need Help?

**Documentation:**
- 📖 Full Guide: `DEPLOYMENT_GUIDE.md`
- ⚡ Quick Setup: `HOSTINGER_SETUP_STEPS.md`
- 📋 Summary: `DOMAIN_CONNECTION_SUMMARY.md`

**Hostinger Support:**
- Live Chat: 24/7 in cPanel
- Tickets: Via hPanel
- Knowledge Base: https://support.hostinger.com

**Test URLs:**
- API: http://cargoph.online/carGOAdmin/api/get_cars.php
- Admin: http://cargoph.online/carGOAdmin/dashboard.php
- Login: http://cargoph.online/carGOAdmin/login.php

---

**Last Updated:** 2026-02-03
**Version:** 1.0.0
**Status:** Ready for Deployment ✅
