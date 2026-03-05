# 🚀 CarGO Deployment Guide

## Production Deployment Checklist

### Prerequisites
- ✅ Domain name registered
- ✅ SSL certificate (Let's Encrypt recommended)
- ✅ Hosting server (cPanel/VPS with PHP 8.0+)
- ✅ MySQL database (5.7+ or MariaDB 10.2+)
- ✅ Firebase project (production)
- ✅ GCash merchant account (for payments)
- ✅ Google Maps API key (production)
- ✅ MapTiler API key

---

## Backend Deployment (PHP/MySQL)

### Step 1: Server Setup

#### 1.1 Configure PHP Settings
```ini
# php.ini or .htaccess
upload_max_filesize = 20M
post_max_size = 25M
max_execution_time = 300
memory_limit = 256M
```

#### 1.2 Enable Required Extensions
```bash
# Ensure these are enabled
extension=mysqli
extension=pdo_mysql
extension=gd
extension=curl
extension=mbstring
extension=json
```

### Step 2: Database Setup

#### 2.1 Create Production Database
```sql
CREATE DATABASE cargo_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### 2.2 Import Schema
```bash
# SSH into server
mysql -u username -p cargo_production < u672913452_dbcargo_schema_only.sql

# Or use phpMyAdmin to import
```

#### 2.3 Create Database User
```sql
CREATE USER 'cargo_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON cargo_production.* TO 'cargo_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 3: Upload Backend Files

#### 3.1 File Structure on Server
```
public_html/
├── .htaccess                    # Root htaccess
├── index.php                    # Landing page
└── cargoAdmin/
    ├── api/                     # All API endpoints
    ├── include/
    │   ├── config.php          # ⚠️ CONFIGURE THIS
    │   └── db.php              # ⚠️ CONFIGURE THIS
    ├── uploads/                 # Ensure writable (755)
    └── vendor/                  # TCPDF library
```

#### 3.2 Set File Permissions
```bash
# Set correct permissions
chmod 755 public_html/cargoAdmin
chmod 755 public_html/cargoAdmin/api
chmod 755 public_html/cargoAdmin/uploads
chmod 755 public_html/cargoAdmin/uploads/profile_images
chmod 755 public_html/cargoAdmin/uploads/verification
chmod 755 public_html/cargoAdmin/uploads/reports
chmod 755 public_html/cargoAdmin/uploads/odometer
chmod 755 public_html/cargoAdmin/uploads/payout_proofs

# Protect config files
chmod 644 public_html/cargoAdmin/include/config.php
chmod 644 public_html/cargoAdmin/include/db.php
```

### Step 4: Configure Backend

#### 4.1 Database Configuration (`include/db.php`)
```php
<?php
// Production Database Configuration
define('DB_SERVER', 'localhost');
define('DB_USERNAME', 'cargo_user');
define('DB_PASSWORD', 'YOUR_STRONG_PASSWORD');
define('DB_NAME', 'cargo_production');

$conn = mysqli_connect(DB_SERVER, DB_USERNAME, DB_PASSWORD, DB_NAME);

if (!$conn) {
    error_log("Database connection failed: " . mysqli_connect_error());
    die(json_encode(['success' => false, 'message' => 'Service unavailable']));
}

mysqli_set_charset($conn, 'utf8mb4');
?>
```

#### 4.2 API Configuration (`include/config.php`)
```php
<?php
// Production Configuration
define('BASE_URL', 'https://yourdomain.com/cargoAdmin/');
define('UPLOAD_PATH', __DIR__ . '/../uploads/');
define('UPLOAD_URL', BASE_URL . 'uploads/');

// Security
define('API_SECRET_KEY', 'GENERATE_RANDOM_64_CHAR_STRING');
define('JWT_SECRET', 'GENERATE_RANDOM_64_CHAR_STRING');

// Email Configuration (SMTP)
define('SMTP_HOST', 'smtp.gmail.com');
define('SMTP_PORT', 587);
define('SMTP_USERNAME', 'your-email@gmail.com');
define('SMTP_PASSWORD', 'your-app-specific-password');
define('SMTP_FROM', 'noreply@yourdomain.com');
define('SMTP_FROM_NAME', 'CarGO Platform');

// GCash Configuration
define('GCASH_MERCHANT_ID', 'your_merchant_id');
define('GCASH_API_KEY', 'your_gcash_api_key');
define('GCASH_ENVIRONMENT', 'production'); // 'sandbox' or 'production'

// Google Maps API
define('GOOGLE_MAPS_API_KEY', 'your_production_api_key');

// MapTiler API
define('MAPTILER_API_KEY', 'your_maptiler_key');

// Environment
define('ENVIRONMENT', 'production'); // Set to 'production'
define('DEBUG_MODE', false); // MUST be false in production

// Error Logging
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/../logs/php_errors.log');
?>
```

### Step 5: Setup Cron Jobs

#### 5.1 Automatic Escrow Release (Every 5 minutes)
```bash
*/5 * * * * /usr/bin/php /home/username/public_html/cargoAdmin/cron/auto_release_escrow.php
```

#### 5.2 Overdue Detection (Every hour)
```bash
0 * * * * /usr/bin/php /home/username/public_html/cargoAdmin/cron/detect_overdue_rentals.php
```

#### 5.3 In cPanel
1. Go to **Cron Jobs**
2. Add new cron job
3. Set interval and command path
4. Save

### Step 6: SSL/HTTPS Setup

#### 6.1 Using cPanel/Let's Encrypt
1. Go to **SSL/TLS Status**
2. Select your domain
3. Click **Run AutoSSL**
4. Wait for certificate installation

#### 6.2 Force HTTPS (`.htaccess`)
```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Security Headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

### Step 7: Security Hardening

#### 7.1 Disable Directory Listing
```apache
# In .htaccess
Options -Indexes
```

#### 7.2 Protect Sensitive Files
```apache
# Deny access to config and backup files
<FilesMatch "\.(ini|log|conf|bak|backup|sql)$">
    Order allow,deny
    Deny from all
</FilesMatch>
```

#### 7.3 Remove Debug/Test Files
```bash
# Delete all test and debug files
rm -f public_html/cargoAdmin/test_*.php
rm -f public_html/cargoAdmin/debug_*.php
rm -f public_html/cargoAdmin/*_backup*.php
rm -f public_html/cargoAdmin/api/*/test_*.php
rm -f public_html/cargoAdmin/api/*/debug_*.php
```

---

## Flutter App Deployment

### Step 1: Update Configuration

#### 1.1 Update API Base URL (`lib/config/api_config.dart`)
```dart
class ApiConfig {
  static const String baseUrl = 'https://yourdomain.com/cargoAdmin/api';
  static const bool isDevelopment = false; // Set to false
  
  // Production URLs
  static const String vehiclesEndpoint = '$baseUrl/vechicle/get_cars.php';
  static const String bookingsEndpoint = '$baseUrl/bookings/create_booking.php';
  // ... update all endpoints
}
```

#### 1.2 Update Firebase Config
```bash
# Download production google-services.json from Firebase Console
# Replace android/app/google-services.json

# Download production GoogleService-Info.plist
# Replace ios/Runner/GoogleService-Info.plist
```

#### 1.3 Update MapTiler Key (`lib/config/maptiler_config.dart`)
```dart
class MapTilerConfig {
  static const String apiKey = 'YOUR_PRODUCTION_MAPTILER_KEY';
}
```

### Step 2: Build for Production

#### 2.1 Android Build

```bash
# Update version in pubspec.yaml
version: 1.0.0+1  # Increment for each release

# Clean and get dependencies
flutter clean
flutter pub get

# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab
# build/app/outputs/flutter-apk/app-release.apk
```

#### 2.2 iOS Build

```bash
# Open Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" target
# 2. Update version and build number
# 3. Select "Generic iOS Device"
# 4. Product > Archive
# 5. Distribute to App Store

# Or via command line:
flutter build ios --release
```

### Step 3: App Store Deployment

#### 3.1 Google Play Store

**Prerequisites:**
- Developer account ($25 one-time fee)
- App signing key
- Privacy policy URL
- App screenshots (phone + tablet)

**Steps:**
1. Create app in Play Console
2. Upload app bundle (.aab)
3. Fill app details:
   - Title: CarGO - Rent Cars & Motorcycles
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots (at least 2 per device type)
   - Feature graphic (1024x500)
   - App icon (512x512)
4. Set content rating
5. Add privacy policy
6. Submit for review

#### 3.2 Apple App Store

**Prerequisites:**
- Apple Developer account ($99/year)
- App Store Connect access
- Screenshots for all device sizes
- Privacy policy

**Steps:**
1. Create app in App Store Connect
2. Archive and upload via Xcode
3. Fill app information
4. Submit for review

---

## Post-Deployment

### Monitoring Setup

#### 1. Error Logging
```php
// Create logs directory
mkdir -p public_html/cargoAdmin/logs
chmod 755 public_html/cargoAdmin/logs

// Monitor errors
tail -f public_html/cargoAdmin/logs/php_errors.log
```

#### 2. Database Backup
```bash
# Daily backup cron
0 2 * * * mysqldump -u cargo_user -p'PASSWORD' cargo_production > /backups/cargo_$(date +\%Y\%m\%d).sql
```

#### 3. Performance Monitoring
- Enable slow query log
- Monitor API response times
- Track database query performance
- Monitor server resources (CPU, RAM, Disk)

### Testing Production

#### Checklist:
- [ ] API endpoints responding
- [ ] User registration working
- [ ] Login (Email, Google, Facebook)
- [ ] Vehicle listing creation
- [ ] Booking creation
- [ ] Payment processing
- [ ] GPS tracking
- [ ] Push notifications
- [ ] Image uploads
- [ ] PDF generation (insurance)
- [ ] Email sending (SMTP)
- [ ] Cron jobs running

---

## Rollback Plan

### If Issues Arise:

1. **Database Rollback**
```bash
mysql -u cargo_user -p cargo_production < backup_YYYYMMDD.sql
```

2. **Code Rollback**
- Keep previous version in `backup_YYYYMMDD/` folder
- Restore from backup if needed

3. **App Rollback**
- Keep previous .aab/.ipa files
- Can upload older version to stores if critical

---

## Support & Maintenance

### Regular Maintenance Tasks

**Daily:**
- Monitor error logs
- Check server uptime
- Review user reports

**Weekly:**
- Database backup verification
- Security updates check
- Performance review

**Monthly:**
- Database optimization
- Clear old logs
- Review analytics
- Update dependencies

---

## Emergency Contacts

**Hosting Provider:** [Provider Support]  
**Domain Registrar:** [Registrar Support]  
**Firebase Support:** https://firebase.google.com/support  
**GCash Merchant Support:** [Contact Info]  

---

**Deployment Date:** _____________  
**Deployed By:** _____________  
**Production URL:** https://yourdomain.com  
**Status:** ✅ Live

