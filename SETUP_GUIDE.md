# 🚀 CarGO Setup Guide

Complete setup instructions for development and production environments.

## 📋 Prerequisites

### Required Software
- **Flutter SDK**: 3.7.0 or higher
- **Dart SDK**: 3.7.0 or higher (bundled with Flutter)
- **PHP**: 8.0 or higher
- **MySQL/MariaDB**: 8.0+ / 10.6+
- **Composer**: Latest version (for PHP dependencies)
- **Apache/Nginx**: Web server
- **Git**: Version control
- **Android Studio**: For Android development
- **Xcode**: For iOS development (macOS only)

### Required Accounts
- **Firebase Account**: For authentication and push notifications
- **MapTiler Account**: For geocoding and maps API
- **Google Cloud Console**: For Google Sign-In
- **Facebook Developers**: For Facebook Login (optional)
- **GCash Business Account**: For payment processing

---

## 🔧 Part 1: Backend Setup (PHP API)

### Step 1: Database Configuration

1. **Create MySQL Database**
   ```sql
   CREATE DATABASE u672913452_dbcargo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. **Import Database Schema**
   ```bash
   mysql -u root -p u672913452_dbcargo < u672913452_dbcargo_schema_only.sql
   ```

3. **Run Migrations**
   ```bash
   cd public_html/cargoAdmin/database_migrations
   mysql -u root -p u672913452_dbcargo < insurance_system_migration.sql
   mysql -u root -p u672913452_dbcargo < escrow_system_complete_migration.sql
   mysql -u root -p u672913452_dbcargo < mileage_tracking_migration.sql
   ```

### Step 2: Configure Backend Environment

1. **Edit Database Configuration**
   
   Open `public_html/cargoAdmin/include/config.php`:
   
   ```php
   <?php
   // Database Configuration
   define('DB_HOST', 'localhost');
   define('DB_USER', 'your_db_username');
   define('DB_PASS', 'your_db_password');
   define('DB_NAME', 'u672913452_dbcargo');
   
   // Environment
   define('DEBUG_MODE', true);  // Set to false in production
   define('API_BASE_URL', 'https://yourdomain.com/cargoAdmin/api/');
   
   // Security
   define('JWT_SECRET_KEY', 'your-secret-key-here-change-this');
   define('ADMIN_EMAIL', 'admin@cargo.com');
   
   // File Upload Settings
   define('MAX_FILE_SIZE', 5242880); // 5MB in bytes
   define('UPLOAD_PATH', __DIR__ . '/../uploads/');
   
   // GCash Payment
   define('GCASH_RECEIVER_NUMBER', '09XXXXXXXXX');
   define('GCASH_RECEIVER_NAME', 'Your Name');
   
   // MapTiler API
   define('MAPTILER_API_KEY', 'your-maptiler-api-key');
   
   // Email Configuration (SMTP)
   define('SMTP_HOST', 'smtp.gmail.com');
   define('SMTP_PORT', 587);
   define('SMTP_USERNAME', 'your-email@gmail.com');
   define('SMTP_PASSWORD', 'your-app-password');
   define('SMTP_FROM_EMAIL', 'noreply@cargo.com');
   define('SMTP_FROM_NAME', 'CarGO Platform');
   ?>
   ```

2. **Set Folder Permissions**
   ```bash
   chmod -R 755 public_html/cargoAdmin/
   chmod -R 777 public_html/cargoAdmin/uploads/
   ```

3. **Configure Apache/Web Server**
   
   Create or edit `.htaccess` in `public_html/cargoAdmin/`:
   
   ```apache
   RewriteEngine On
   
   # Enable CORS for API
   Header set Access-Control-Allow-Origin "*"
   Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
   Header set Access-Control-Allow-Headers "Content-Type, Authorization"
   
   # Security Headers
   Header set X-Frame-Options "SAMEORIGIN"
   Header set X-Content-Type-Options "nosniff"
   
   # Handle preflight requests
   RewriteCond %{REQUEST_METHOD} OPTIONS
   RewriteRule ^(.*)$ $1 [R=200,L]
   
   # Block access to sensitive files
   <FilesMatch "\.(sql|env|git|log)$">
       Order allow,deny
       Deny from all
   </FilesMatch>
   ```

### Step 3: Create Admin Account

1. **Run Admin Creation Script**
   ```bash
   mysql -u root -p u672913452_dbcargo
   ```
   
   ```sql
   INSERT INTO admin (fullname, email, password, phone, profile_image)
   VALUES ('Admin User', 'admin@cargo.com', MD5('admin123'), '09123456789', '');
   ```

### Step 4: Setup Cron Jobs (Automated Tasks)

Add to crontab (`crontab -e`):

```bash
# Auto-release escrow for completed bookings (every 5 minutes)
*/5 * * * * php /path/to/public_html/cargoAdmin/cron/auto_release_escrow.php

# Detect overdue rentals (every hour)
0 * * * * php /path/to/public_html/cargoAdmin/cron/detect_overdue_rentals.php
```

---

## 📱 Part 2: Flutter App Setup

### Step 1: Install Flutter

1. **Download Flutter SDK**
   ```bash
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

### Step 2: Configure Firebase

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Create a new project: "CarGO"
   - Enable Google Analytics (optional)

2. **Add Android App**
   - Package name: `com.example.flutter_application_1`
   - Download `google-services.json`
   - Place in `android/app/`

3. **Add iOS App** (if developing for iOS)
   - Bundle ID: `com.example.flutterApplication1`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

4. **Enable Firebase Services**
   - **Authentication**: Enable Email/Password, Google, Facebook
   - **Cloud Messaging**: Enable FCM for push notifications
   - **Firestore**: Create database in production mode
   - **Realtime Database**: Enable for presence tracking

5. **Configure Firebase in Flutter**
   
   Run FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### Step 3: Configure App Settings

1. **Update API Configuration**
   
   Edit `lib/config/api_config.dart`:
   
   ```dart
   class GlobalApiConfig {
     // Backend API URL
     static const String baseUrl = 'https://yourdomain.com/cargoAdmin/api/';
     
     // API Endpoints
     static const String loginEndpoint = '${baseUrl}auth/login.php';
     static const String registerEndpoint = '${baseUrl}auth/register.php';
     static const String getCarsEndpoint = '${baseUrl}vechicle/get_cars.php';
     // ... add other endpoints
     
     // MapTiler API
     static const String mapTilerApiKey = 'your-maptiler-api-key';
     
     // GCash Payment Details
     static const String gcashNumber = '09XXXXXXXXX';
     static const String gcashName = 'Your Name';
   }
   ```

2. **Update MapTiler Configuration**
   
   Edit `lib/config/maptiler_config.dart`:
   
   ```dart
   class MapTilerConfig {
     static const String apiKey = 'your-maptiler-api-key';
     static const String geocodingUrl = 'https://api.maptiler.com/geocoding/';
     static const String tileUrl = 'https://api.maptiler.com/maps/streets-v2/';
   }
   ```

### Step 4: Install Dependencies

```bash
flutter pub get
flutter pub upgrade
```

### Step 5: Configure Google Sign-In

1. **Get OAuth Client ID**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create/Select project
   - Enable Google Sign-In API
   - Create OAuth 2.0 credentials
   
2. **Android Configuration**
   - Get SHA-1 fingerprint:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
     ```
     Password: `android`
   - Add to Firebase project

3. **iOS Configuration**
   - Add reversed client ID to `ios/Runner/Info.plist`

### Step 6: Build and Run

1. **Development Build**
   ```bash
   # Android
   flutter run

   # iOS (macOS only)
   flutter run -d ios
   ```

2. **Production Build**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle (for Play Store)
   flutter build appbundle --release
   
   # iOS (macOS only)
   flutter build ios --release
   ```

---

## 🧪 Part 3: Testing the Setup

### Test Backend API

```bash
# Test database connection
curl https://yourdomain.com/cargoAdmin/test_connection.php

# Test user registration
curl -X POST https://yourdomain.com/cargoAdmin/api/register.php \
  -d "fullname=Test User" \
  -d "email=test@example.com" \
  -d "password=password123" \
  -d "contact=09123456789"
```

### Test Flutter App

1. **Run on Emulator/Simulator**
   ```bash
   flutter emulators --launch <emulator_id>
   flutter run
   ```

2. **Test Core Features**
   - User registration/login
   - Browse vehicles
   - Create booking
   - Payment flow
   - GPS tracking

---

## 🔐 Security Checklist

- [ ] Change all default passwords
- [ ] Update JWT secret key
- [ ] Enable HTTPS/SSL certificate
- [ ] Set `DEBUG_MODE = false` in production
- [ ] Restrict database user privileges
- [ ] Configure firewall rules
- [ ] Enable Firebase security rules
- [ ] Validate all API inputs
- [ ] Implement rate limiting
- [ ] Regular security audits

---

## 📞 Troubleshooting

### Common Issues

**Issue**: Database connection failed
- Check credentials in `config.php`
- Verify MySQL service is running
- Check firewall settings

**Issue**: Firebase not working
- Verify `google-services.json` is in correct location
- Run `flutterfire configure` again
- Check Firebase console for enabled services

**Issue**: Maps not displaying
- Verify MapTiler API key
- Check internet connection
- Review browser console for errors

**Issue**: Push notifications not working
- Verify FCM token is saved to database
- Check Firebase Cloud Messaging setup
- Ensure device has internet connection

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [PHP MySQL Tutorial](https://www.php.net/manual/en/book.mysql.php)
- [MapTiler API Docs](https://docs.maptiler.com)

---

**Need Help?** Contact the development team or check the [API Documentation](API_DOCUMENTATION.md).
