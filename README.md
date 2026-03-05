# 🚗 CarGO - Peer-to-Peer Vehicle Rental Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter)](https://flutter.dev)
[![PHP](https://img.shields.io/badge/PHP-8.0+-777BB4?logo=php)](https://php.net)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

**CarGO** is a comprehensive peer-to-peer vehicle rental platform built with Flutter (mobile app) and PHP (backend API). It enables vehicle owners to rent out their cars and motorcycles while providing renters with a seamless booking experience, real-time GPS tracking, insurance coverage, and secure escrow-based payments.

## 📑 Table of Contents

- [Features](#-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Deployment](#-deployment)
- [Testing](#-testing)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features

### For Vehicle Owners
- **Vehicle Listing Management**: List cars and motorcycles with detailed information, photos, pricing, and availability
- **Booking Management**: Accept/reject rental requests, manage active bookings
- **Real-time Notifications**: Instant alerts for new bookings, payments, and rental status changes
- **Analytics Dashboard**: Revenue tracking, booking statistics, and performance metrics
- **Calendar Management**: Block dates for personal use or maintenance
- **Payout System**: Automated escrow release with GCash integration
- **Live GPS Tracking**: Monitor rented vehicles in real-time during active rentals
- **Document Management**: Upload and manage vehicle registration, insurance, and receipts
- **Verification System**: ID verification for trust and safety

### For Renters
- **Advanced Search**: Filter by location, price, vehicle type, features, and availability
- **Interactive Maps**: View vehicles on map with real-time availability
- **Booking System**: Seamless rental process with date selection and instant confirmation
- **Secure Payments**: GCash payment with escrow protection
- **GPS Navigation**: Turn-by-turn directions to pickup locations
- **Insurance Options**: Multiple coverage tiers for rental protection
- **Reviews & Ratings**: Rate vehicles and read owner reviews
- **Trip History**: Complete booking history with receipts
- **Favorites**: Save preferred vehicles for quick access
- **Live Chat**: Direct messaging with vehicle owners
- **Mileage Tracking**: Automatic odometer tracking with photo verification

### Platform Features
- **Escrow System**: Secure payment holding and automated release
- **Insurance Management**: Built-in insurance policy creation and claims processing
- **Overdue Detection**: Automatic late fee calculation and notification
- **Mileage Verification**: GPS-based distance tracking with dispute resolution
- **Multi-auth Support**: Email, Google Sign-In, and Facebook authentication
- **Push Notifications**: Firebase Cloud Messaging for real-time alerts
- **Offline Support**: Cached data for seamless offline browsing
- **Dark Mode**: Full theme support for comfortable viewing
- **Network Resilience**: Automatic retry and connection management

## 🏗️ System Architecture

<div align="center">
  <img src="assets/cargo.png" alt="CarGO Logo" width="200"/>
  
  **A comprehensive mobile application for vehicle rental management**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
  [![PHP](https://img.shields.io/badge/PHP-Backend-777BB4?logo=php)](https://php.net)
  [![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?logo=mysql)](https://mysql.com)
  [![License](https://img.shields.io/badge/License-Academic-green)](LICENSE)
</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [System Architecture](#-system-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Security](#-security)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

## 🌟 Overview

**CarGO** is a full-stack mobile application designed to streamline vehicle rental operations. The platform connects vehicle owners with renters, providing a secure, feature-rich environment for managing car and motorcycle rentals.

### Project Information
- **Type**: Capstone/Thesis Project
- **Version**: 1.0.0
- **Platform**: iOS, Android, Web
- **Status**: Production Ready

### Key Objectives
1. Simplify vehicle rental process for owners and renters
2. Provide real-time tracking and communication
3. Ensure secure payment processing with escrow protection
4. Deliver comprehensive analytics and reporting
5. Enable seamless booking management

---

## ✨ Features

### 🏠 For Vehicle Owners

#### Vehicle Management
- ✅ **Multi-vehicle support** - List unlimited cars and motorcycles
- ✅ **Rich media uploads** - Multiple photos per vehicle (main, CR, OR, extras)
- ✅ **Detailed specifications** - Year, model, transmission, fuel type, features
- ✅ **Dynamic pricing** - Daily, weekly, monthly rates
- ✅ **Availability calendar** - Block dates, manage bookings
- ✅ **Status management** - Available, rented, maintenance modes

#### Booking Management
- ✅ **Request approval system** - Review and approve/reject bookings
- ✅ **Active booking tracking** - Monitor ongoing rentals
- ✅ **Booking history** - View past rentals with filters
- ✅ **Cancellation handling** - Manage cancellations with refund processing
- ✅ **Extension requests** - Approve rental extensions

#### Financial Features
- ✅ **Escrow protection** - Payments held securely until completion
- ✅ **Auto-release system** - Automated payment release after rental
- ✅ **Payout management** - Track earnings and payment history
- ✅ **Late fee calculation** - Automatic overdue charges
- ✅ **Transaction reporting** - Detailed financial reports
- ✅ **Refund processing** - Handle cancellations professionally

#### Analytics & Insights
- ✅ **Revenue dashboard** - Track earnings over time
- ✅ **Booking statistics** - Completion rates, popular vehicles
- ✅ **Performance metrics** - Occupancy rates, revenue trends
- ✅ **Visual charts** - FL Chart integration for data visualization

#### Communication
- ✅ **Real-time chat** - Text messaging with renters
- ✅ **Voice/video calls** - WebRTC integration
- ✅ **Push notifications** - Booking alerts, payment updates
- ✅ **In-app notifications** - Activity feed

### 👤 For Renters

#### Vehicle Discovery
- ✅ **Search & filters** - By location, type, price, features
- ✅ **Map view** - Find vehicles near you with Flutter Map
- ✅ **List view** - Browse all available vehicles
- ✅ **Saved searches** - Quick access to frequent searches
- ✅ **Favorites** - Bookmark preferred vehicles

#### Booking Process
- ✅ **Easy booking flow** - Select dates, review details, confirm
- ✅ **Instant availability** - Real-time calendar integration
- ✅ **Booking modifications** - Request extensions or cancellations
- ✅ **Booking history** - Track all rentals (active, completed, cancelled)

#### Payment & Security
- ✅ **GCash integration** - Secure payment processing
- ✅ **Escrow protection** - Funds held until rental completion
- ✅ **Digital receipts** - PDF generation for all transactions
- ✅ **Refund support** - Automated refund processing

#### Tracking & Safety
- ✅ **GPS tracking** - Real-time vehicle location (if enabled)
- ✅ **Odometer verification** - Photo-based mileage tracking
- ✅ **Trip monitoring** - Start/end trip confirmation
- ✅ **Emergency contact** - Direct communication with owner

#### Insurance & Support
- ✅ **Insurance information** - View coverage details
- ✅ **Incident reporting** - Submit reports with photo evidence
- ✅ **Help & support** - FAQs, policy documents
- ✅ **Rating & reviews** - Provide feedback on rentals

### 🔧 System Features

#### Authentication & Security
- ✅ **Multi-method auth** - Email/password, Google Sign-In, Facebook
- ✅ **Password encryption** - BCrypt hashing with auto-upgrade
- ✅ **Session management** - Persistent login with secure tokens
- ✅ **User verification** - ID verification system for trust
- ✅ **Account suspension** - Admin controls for security

#### Real-time Features
- ✅ **Firebase integration** - Real-time database, cloud messaging
- ✅ **Live presence** - Online/offline status indicators
- ✅ **GPS tracking** - Geolocator with network resilience
- ✅ **WebRTC calls** - Peer-to-peer voice/video

#### Network & Performance
- ✅ **Offline detection** - Connectivity monitoring
- ✅ **Auto-retry logic** - Network resilience service
- ✅ **Image caching** - Cached Network Image
- ✅ **Lazy loading** - Shimmer placeholders
- ✅ **Performance optimization** - Efficient data loading

#### User Experience
- ✅ **Dark/light themes** - Theme provider with persistence
- ✅ **Material Design 3** - Modern UI components
- ✅ **Smooth animations** - Animate Do integration
- ✅ **Responsive layouts** - Adaptive to screen sizes
- ✅ **Intuitive navigation** - Bottom nav, drawer, tabs

---

## 🛠️ Technology Stack

### Mobile Application (Frontend)

| Technology | Purpose | Version |
|------------|---------|---------|
| **Flutter** | Cross-platform framework | 3.7+ |
| **Dart** | Programming language | SDK >=3.7.0 |
| **Provider** | State management | 6.0.5 |
| **Firebase Core** | Firebase initialization | 3.6.0 |
| **Firebase Auth** | Authentication | 5.3.3 |
| **Cloud Firestore** | NoSQL database | 5.4.4 |
| **Firebase Messaging** | Push notifications | 15.1.2 |
| **Flutter Map** | Interactive maps | 8.2.2 |
| **Geolocator** | GPS location services | 14.0.2 |
| **Flutter WebRTC** | Voice/video calls | Latest |
| **FL Chart** | Data visualization | 0.69.0 |
| **Table Calendar** | Calendar widget | 3.0.9 |
| **Image Picker** | Photo capture/upload | 1.0.7 |
| **Cached Network Image** | Image caching | 3.4.1 |
| **Shimmer** | Loading animations | 3.0.0 |
| **Connectivity Plus** | Network monitoring | 6.1.2 |

### Backend (API Server)

| Technology | Purpose |
|------------|---------|
| **PHP** | Server-side language (7.4+) |
| **MySQL** | Relational database (8.0+) |
| **PDO/MySQLi** | Database drivers |
| **REST API** | API architecture |
| **JSON** | Data interchange format |

### Infrastructure & Services

| Service | Purpose |
|---------|---------|
| **Firebase** | Real-time database, auth, messaging |
| **Hostinger** | Production hosting |
| **GCash** | Payment processing |
| **MapTiler** | Map tiles & geocoding |
| **TCPDF** | PDF generation |

### Development Tools

| Tool | Purpose |
|------|---------|
| **Git** | Version control |
| **VS Code / Android Studio** | IDEs |
| **Postman** | API testing |
| **Flutter DevTools** | Debugging & profiling |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     MOBILE APPLICATION                      │
│                      (Flutter/Dart)                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   UI Layer   │  │  Services    │  │   Models     │     │
│  │  (Screens)   │  │  (Business)  │  │   (Data)     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         │                  │                  │            │
│         └──────────────────┴──────────────────┘            │
│                         │                                  │
└─────────────────────────┼──────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Firebase   │  │  REST API    │  │   Payment    │
│   Services   │  │  (PHP/MySQL) │  │   Gateway    │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        │         ┌───────┴────────┐        │
        │         │                │        │
        ▼         ▼                ▼        ▼
┌──────────────────────────────────────────────────┐
│            DATABASE & STORAGE LAYER              │
├──────────────────────────────────────────────────┤
│  • Firebase Realtime DB (Presence, Chat)        │
│  • MySQL Database (Core Data)                   │
│  • File Storage (Images, Documents)             │
└──────────────────────────────────────────────────┘
```

### Architecture Patterns
- **MVVM-like structure** - Separation of UI, business logic, and data
- **Service layer** - Centralized business logic and API calls
- **Provider pattern** - State management across widgets
- **Repository pattern** - Data access abstraction (backend APIs)
- **Singleton services** - Auth, GPS, network resilience

---

## 📦 Prerequisites

Before installing CarGO, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.7 or higher)
   ```bash
   flutter --version
   ```
   Download from: https://flutter.dev/docs/get-started/install

2. **Dart SDK** (3.7 or higher)
   - Bundled with Flutter

3. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Required components:
     - Android SDK
     - Android SDK Platform
     - Android Virtual Device (AVD)

4. **Xcode** (for iOS development - macOS only)
   - Download from Mac App Store
   - Requires macOS 12.0 or higher

5. **Git**
   ```bash
   git --version
   ```

6. **PHP** (7.4 or higher for backend)
   ```bash
   php --version
   ```

7. **MySQL** (8.0 or higher)
   ```bash
   mysql --version
   ```

8. **Composer** (PHP dependency manager)
   ```bash
   composer --version
   ```

### Firebase Account
- Create a Firebase project at https://console.firebase.google.com
- Enable Authentication, Firestore, Realtime Database, Storage, Cloud Messaging

### API Keys & Services
- **MapTiler API key** (for maps and geocoding)
- **GCash Merchant Account** (for payments)
- **Domain & hosting** (for production deployment)

---

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/cargo-rental-app.git
cd cargo-rental-app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### a. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create a new project named "CarGO"
3. Enable the following services:
   - **Authentication** (Email/Password, Google, Facebook)
   - **Cloud Firestore**
   - **Realtime Database**
   - **Cloud Storage**
   - **Cloud Messaging**

#### b. Add Firebase to Flutter App

**For Android:**
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/`

**For iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/`

#### c. Configure Firebase Options
The `firebase_options.dart` file is already configured. Update if needed:
```bash
flutterfire configure
```

### 4. Backend Setup

#### a. Database Setup
```bash
# Navigate to backend directory
cd public_html/cargoAdmin

# Import database schema
mysql -u your_username -p your_database < database_migrations.sql

# Or import via phpMyAdmin
# Import: u672913452_dbcargo_schema_only.sql
```

#### b. Configure Database Connection
Edit `public_html/cargoAdmin/include/db.php`:
```php
<?php
$servername = "localhost";
$username = "your_db_username";
$password = "your_db_password";
$dbname = "your_db_name";

$conn = new mysqli($servername, $username, $password, $dbname);
?>
```

#### c. Update API Configuration
Edit `lib/config/api_config.dart`:
```dart
class GlobalApiConfig {
  static const bool isDevelopment = true; // Set to false for production
  
  // Development
  static const String _devBaseIP = '10.0.2.2'; // Your local IP
  static const String _devBasePath = 'cargoAdmin';
  
  // Production
  static const String _prodDomain = 'your-domain.com';
  static const String _prodBasePath = 'cargoAdmin';
  
  // ... rest of configuration
}
```

### 5. Configure Third-Party Services

#### a. MapTiler API Key
Edit `lib/config/maptiler_config.dart`:
```dart
class MapTilerConfig {
  static const String apiKey = 'YOUR_MAPTILER_API_KEY';
  // Get free key at: https://www.maptiler.com/
}
```

#### b. GCash Payment (Optional for testing)
Update payment endpoints in backend if needed.

### 6. Grant Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby vehicles</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access to upload vehicle photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select vehicle images</string>
```

---

## ⚙️ Configuration

### Environment Variables

Create `.env` file in project root (optional, for sensitive data):
```env
# API Configuration
API_BASE_URL=https://your-domain.com/cargoAdmin
API_TIMEOUT=15

# MapTiler
MAPTILER_API_KEY=your_key_here

# Firebase (if not using firebase_options.dart)
FIREBASE_API_KEY=your_key
FIREBASE_PROJECT_ID=your_project_id
```

### App Configuration

Edit `lib/config/app_info.dart` for app-wide settings:
```dart
class AppInfo {
  static const String appName = 'CarGO';
  static const String version = '1.0.0';
  static const String supportEmail = 'support@cargoph.online';
  static const String supportPhone = '+63 XXX XXX XXXX';
}
```

### Build Configuration

**For Development:**
```bash
flutter run --debug
```

**For Production:**
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

---

## 📖 Usage

### Running the Application

#### Android
```bash
# Start Android emulator or connect physical device
flutter devices

# Run the app
flutter run
```

#### iOS (macOS only)
```bash
# Start iOS simulator
open -a Simulator

# Run the app
flutter run
```

#### Web
```bash
flutter run -d chrome
```

### First-Time Setup

1. **Launch the app** - You'll see the onboarding screen
2. **Register an account**:
   - Choose "Sign Up"
   - Select role: Owner or Renter
   - Fill in details (email, password, name, etc.)
   - Verify email (if enabled)
3. **Login** with created credentials
4. **Complete profile** with additional information

### For Vehicle Owners

1. **Add a vehicle**:
   - Navigate to "My Cars"
   - Tap "+" button
   - Fill vehicle details
   - Upload photos (main, CR, OR, extras)
   - Set pricing and availability
   - Submit for listing

2. **Manage bookings**:
   - View pending requests
   - Approve/reject bookings
   - Track active rentals
   - Confirm trip start/end
   - Handle extensions

3. **Monitor earnings**:
   - Dashboard shows revenue
   - View payout history
   - Request withdrawals

### For Renters

1. **Search vehicles**:
   - Browse list or map view
   - Apply filters (price, type, location)
   - View vehicle details
   - Check owner ratings

2. **Book a vehicle**:
   - Select dates on calendar
   - Review booking details
   - Proceed to payment
   - Submit booking request

3. **During rental**:
   - Start trip (odometer photo)
   - Track location (if enabled)
   - Contact owner via chat/call
   - End trip (odometer photo)

4. **After rental**:
   - Rate and review
   - View digital receipt
   - Download invoice

---

## 📚 API Documentation

Comprehensive API documentation is available in [API_DOCUMENTATION.md](API_DOCUMENTATION.md).

### Quick Reference

#### Base URLs
- **Development**: `http://your-local-ip/cargoAdmin`
- **Production**: `https://cargoph.online/cargoAdmin`

#### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/login.php` | User login |
| POST | `/register.php` | User registration |
| POST | `/logout.php` | User logout |
| POST | `/backend_setting/update_password.php` | Change password |

#### Vehicle Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/get_cars.php` | Get all cars |
| GET | `/api/get_motorcycles_filtered.php` | Get motorcycles with filters |
| GET | `/api/get_car_details.php?car_id={id}` | Get car details |
| POST | `/api/vechicle/add_vehicle.php` | Add new vehicle |
| POST | `/update_car_status.php` | Update vehicle status |

#### Booking Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/get_my_bookings.php?user_id={id}` | Get user bookings |
| POST | `/api/create_booking.php` | Create new booking |
| POST | `/api/approve_request.php` | Approve booking |
| POST | `/api/reject_request.php` | Reject booking |
| POST | `/api/cancel_booking.php` | Cancel booking |

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete list with request/response examples.

---

## 🗄️ Database Schema

Database documentation is available in [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md).

### Core Tables

#### Users Table
```sql
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('Renter', 'Owner') NOT NULL,
  phone VARCHAR(20),
  address TEXT,
  profile_image VARCHAR(255),
  is_verified BOOLEAN DEFAULT FALSE,
  is_suspended BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  online_status ENUM('online', 'offline') DEFAULT 'offline',
  last_seen TIMESTAMP NULL
);
```

#### Cars Table
```sql
CREATE TABLE cars (
  car_id INT AUTO_INCREMENT PRIMARY KEY,
  owner_id INT NOT NULL,
  car_name VARCHAR(100) NOT NULL,
  car_year INT NOT NULL,
  transmission VARCHAR(50),
  fuel_type VARCHAR(50),
  seating_capacity INT,
  daily_rate DECIMAL(10,2) NOT NULL,
  weekly_rate DECIMAL(10,2),
  monthly_rate DECIMAL(10,2),
  location VARCHAR(255),
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),
  car_image VARCHAR(255),
  status ENUM('available', 'rented', 'maintenance') DEFAULT 'available',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(user_id) ON DELETE CASCADE
);
```

#### Bookings Table
```sql
CREATE TABLE bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  vehicle_id INT NOT NULL,
  vehicle_type ENUM('Car', 'Motorcycle') NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_price DECIMAL(10,2) NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'cancelled', 'completed') DEFAULT 'pending',
  payment_status ENUM('pending', 'paid', 'refunded', 'escrowed', 'released') DEFAULT 'pending',
  trip_started BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (vehicle_id) REFERENCES cars(car_id)
);
```

See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for complete schema with ER diagram.

---

## 🔒 Security

### Implemented Security Measures

1. **Authentication & Authorization**
   - Password hashing with `bcrypt` (PHP `password_hash()`)
   - Auto-upgrade from legacy plaintext passwords
   - Session management with secure tokens
   - Role-based access control (Owner/Renter)
   - Firebase Authentication integration

2. **Data Protection**
   - **SQL injection prevention**: Prepared statements (PDO, MySQLi)
   - **Input sanitization**: `mysqli_real_escape_string()`, `intval()`, `htmlspecialchars()`
   - **XSS protection**: Output encoding in PHP and Dart
   - **CSRF protection**: Token validation (where applicable)
   - **HTTPS enforcement**: Production uses SSL/TLS

3. **API Security**
   - CORS configuration for controlled access
   - API timeout limits (15 seconds)
   - Rate limiting (recommended for production)
   - User suspension capability
   - Token-based authentication

4. **Firebase Security**
   - Security rules for Realtime Database
   - Firestore security rules
   - Storage access controls
   - Authentication state persistence

5. **Data Privacy**
   - User data encryption in transit (HTTPS)
   - Sensitive data (passwords) never logged
   - Privacy policy implementation
   - GDPR-compliant data handling (for EU users)

### Security Best Practices

✅ **Never commit sensitive data** to version control
✅ **Use environment variables** for API keys
✅ **Regular security audits** of dependencies
✅ **Keep backend updated** (PHP, MySQL, libraries)
✅ **Monitor for suspicious activity** (failed logins, etc.)
✅ **Implement rate limiting** on authentication endpoints
✅ **Use Firebase App Check** (recommended)

### Known Limitations
- ⚠️ No rate limiting on authentication endpoints (add for production)
- ⚠️ API keys visible in client code (use backend proxy for production)
- ⚠️ No two-factor authentication (future enhancement)

---

## 🧪 Testing

### Test Coverage

Current test files:
- `test/widget_test.dart` - Basic smoke test

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Tests

See example tests in [TESTING_GUIDE.md](TESTING_GUIDE.md).

#### Unit Test Example
```dart
test('BookingService calculates total price correctly', () {
  final service = BookingService();
  final price = service.calculateTotalPrice(
    dailyRate: 1500.0,
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 2, 5),
  );
  expect(price, 6000.0); // 4 days * 1500
});
```

#### Widget Test Example
```dart
testWidgets('Login button triggers authentication', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  final emailField = find.byType(TextField).first;
  final passwordField = find.byType(TextField).last;
  final loginButton = find.text('Login');
  
  await tester.enterText(emailField, 'test@example.com');
  await tester.enterText(passwordField, 'password123');
  await tester.tap(loginButton);
  await tester.pump();
  
  // Assert navigation or loading state
});
```

### Test Checklist

- [ ] Unit tests for services (auth, booking, payment)
- [ ] Widget tests for critical screens
- [ ] Integration tests for user flows
- [ ] API endpoint tests (backend)
- [ ] Performance tests (load testing)

**Target**: Minimum 60% code coverage before production deployment.

---

## 🚀 Deployment

Complete deployment guide available in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

### Quick Deployment Steps

#### Android (Google Play)

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2  # version+build_number

# 2. Build release APK
flutter build apk --release

# 3. Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS (App Store)

```bash
# 1. Update version in pubspec.yaml
# 2. Build iOS release
flutter build ios --release

# 3. Open in Xcode
open ios/Runner.xcworkspace

# 4. Archive and upload via Xcode
```

#### Web

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting, Netlify, or Vercel
firebase deploy --only hosting
```

#### Backend (Hostinger/cPanel)

1. **Upload PHP files** via FTP/SFTP
2. **Import database** via phpMyAdmin
3. **Configure** `include/db.php` with production credentials
4. **Set permissions** on upload directories (755)
5. **Enable SSL** certificate
6. **Test** all API endpoints

---

## 👥 Contributing

This is an academic project. Contributions are welcome for educational purposes.

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** changes (`git commit -m 'Add amazing feature'`)
4. **Push** to branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before committing
- Format code with `dart format .`
- Write meaningful commit messages

---

## 📄 License

This project is developed as an **academic capstone/thesis project**.

**For Educational Use Only**

© 2026 CarGO Development Team. All rights reserved.

---

## 📞 Contact

### Project Team
- **Project Lead**: [Your Name]
- **Email**: support@cargoph.online
- **Institution**: [Your University]
- **Department**: Computer Science / Information Technology

### Support
- **Issues**: Open an issue on GitHub
- **Documentation**: See `/docs` folder
- **Email**: support@cargoph.online

### Links
- **Live Demo**: https://cargoph.online
- **API Documentation**: [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **User Manual**: [USER_MANUAL.md](USER_MANUAL.md)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- MapTiler for mapping services
- All open-source contributors whose packages made this possible

---

<div align="center">
  <p><strong>Built with ❤️ using Flutter</strong></p>
  <p>⭐ Star this repository if you find it helpful!</p>
</div>
