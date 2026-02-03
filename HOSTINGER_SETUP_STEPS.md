# Quick Hostinger Setup Steps

## 🎯 Step-by-Step Guide (30 Minutes)

### Step 1: Database Setup (5 min)
1. Login to Hostinger cPanel: https://hpanel.hostinger.com
2. Click **MySQL Databases**
3. Create new database:
   - Name: `u476920059_dbcargo` (or auto-generated name)
4. Create user:
   - Username: `u476920059_cargo`
   - Password: **[Create strong password]**
5. Add user to database → Select **ALL PRIVILEGES**
6. Click **phpMyAdmin** → Select your database → **Import**
7. Upload `dbcargo (22).sql` → Click **Go**

### Step 2: Update Config File (2 min)
1. Open `cargoAdmin/include/config.php`
2. Update lines 25-29 with your actual credentials:
```php
define('DB_HOST', 'localhost');
define('DB_USER', 'u476920059_cargo'); // Your username
define('DB_PASS', 'YourPassword'); // Your password
define('DB_NAME', 'u476920059_dbcargo'); // Your DB name
```

### Step 3: Upload Files (10 min)
1. In cPanel, click **File Manager**
2. Go to `public_html` folder
3. Create folder: `carGOAdmin`
4. Upload ALL files from `cargoAdmin/` to `public_html/carGOAdmin/`
5. Set permissions:
   - Right-click `uploads/` → Permissions → `755`
   - Right-click `uploads/odometer/` → Permissions → `755`
   - Right-click `uploads/verifications/` → Permissions → `755`

### Step 4: Test Backend (3 min)
Open in browser:
```
http://cargoph.online/carGOAdmin/api/get_cars.php
```
Expected: JSON response with cars data

### Step 5: Configure Flutter App (5 min)
1. Open `lib/config/api_config.dart`
2. Change line 13:
```dart
static const bool isDevelopment = false; // Production mode
```
3. Rebuild app:
```bash
flutter clean
flutter build apk --release
```

### Step 6: Test App (5 min)
1. Install built APK on phone
2. Test login
3. Test viewing cars
4. Test booking

## ✅ Done!
Your app is now connected to: **http://cargoph.online**

---

## 🔐 Important Credentials to Save

**Database:**
- Host: `localhost`
- Username: `______________`
- Password: `______________`
- Database: `______________`

**FTP:**
- Host: `ftp.cargoph.online`
- Username: `______________`
- Password: `______________`

**Domain:**
- Primary: http://cargoph.online
- WWW: http://www.cargoph.online
- IP: 145.79.25.36

---

## 🚨 Common Issues

**"Database connection failed"**
→ Check credentials in `config.php`

**"404 Not Found"**
→ Ensure files in `public_html/carGOAdmin/`

**Images not loading**
→ Set `uploads/` permissions to 755

**DNS not resolving**
→ Wait 24-48 hours for propagation

---

## 📞 Need Help?

1. Check full guide: `DEPLOYMENT_GUIDE.md`
2. Hostinger support: 24/7 live chat
3. Test URLs:
   - Config: http://cargoph.online/carGOAdmin/include/config.php?show_config
   - API: http://cargoph.online/carGOAdmin/api/get_cars.php
