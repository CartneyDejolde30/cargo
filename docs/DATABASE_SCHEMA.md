# 🗄️ CarGO Database Schema Documentation

**Database Name:** `u672913452_dbcargo`  
**Database Engine:** MySQL/MariaDB  
**Version:** 1.0.0  
**Last Updated:** February 2024

---

## 📑 Table of Contents

1. [Database Overview](#database-overview)
2. [Entity Relationship Diagram](#entity-relationship-diagram)
3. [Core Tables](#core-tables)
4. [Supporting Tables](#supporting-tables)
5. [Database Views](#database-views)
6. [Stored Procedures](#stored-procedures)
7. [Triggers](#triggers)
8. [Indexes](#indexes)

---

## 📊 Database Overview

### Database Statistics
- **Total Tables:** 45+
- **Total Views:** 7
- **Total Stored Procedures:** 2+
- **Total Triggers:** 3
- **Storage Engine:** InnoDB
- **Character Set:** utf8mb4

### Key Features
- ✅ ACID-compliant transactions
- ✅ Foreign key constraints
- ✅ Automated timestamp tracking
- ✅ Soft delete support
- ✅ Audit logging
- ✅ Data encryption for sensitive fields

---

## 🔗 Entity Relationship Diagram

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    USERS    │◄────────│   BOOKINGS  │────────►│    CARS     │
│             │ renter  │             │ vehicle │             │
│ - id (PK)   │         │ - id (PK)   │         │ - id (PK)   │
│ - fullname  │         │ - user_id   │         │ - owner_id  │
│ - email     │         │ - car_id    │         │ - brand     │
│ - contact   │         │ - status    │         │ - model     │
│ - password  │         │ - pickup_dt │         │ - price     │
└─────────────┘         │ - return_dt │         └─────────────┘
       │                └─────────────┘                │
       │ owner                  │                      │
       └────────────────────────┼──────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
              ┌─────▼─────┐         ┌──────▼──────┐
              │  PAYMENTS │         │   ESCROW    │
              │           │         │             │
              │ - id (PK) │         │ - id (PK)   │
              │ - amount  │◄────────┤ - payment_id│
              │ - status  │         │ - status    │
              └───────────┘         │ - held_amt  │
                    │               └─────────────┘
                    │
              ┌─────▼──────┐
              │ INSURANCE  │
              │ POLICIES   │
              │            │
              │ - id (PK)  │
              │ - coverage │
              │ - premium  │
              └────────────┘
```

### Complete Entity Relationships

```
USERS (1) ──── (M) BOOKINGS
  │                   │
  │                   ├─── (1) PAYMENTS (1) ──── (1) ESCROW
  │                   │
  │                   ├─── (1) INSURANCE_POLICIES
  │                   │
  │                   ├─── (M) GPS_LOCATIONS
  │                   │
  │                   └─── (1) REVIEWS
  │
  ├──── (M) CARS
  │       └─── (M) CAR_PHOTOS
  │
  ├──── (M) MOTORCYCLES
  │
  ├──── (M) NOTIFICATIONS
  │
  ├──── (M) FAVORITES
  │
  ├──── (1) USER_VERIFICATIONS
  │
  └──── (M) REPORTS
```

---

## 📋 Core Tables

### 1. `users` - User Accounts

Primary table for all user accounts (renters and owners).

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `fullname` | VARCHAR(100) | User's full name | NOT NULL |
| `email` | VARCHAR(100) | Email address | UNIQUE, NOT NULL |
| `password` | VARCHAR(255) | Hashed password | NULL for social auth |
| `contact` | VARCHAR(50) | Phone number | NOT NULL |
| `profile_image` | VARCHAR(255) | Profile photo path | NULL |
| `auth_provider` | ENUM | 'email', 'google', 'facebook' | DEFAULT 'email' |
| `google_uid` | VARCHAR(255) | Google user ID | UNIQUE, NULL |
| `facebook_id` | VARCHAR(255) | Facebook user ID | UNIQUE, NULL |
| `fcm_token` | TEXT | Push notification token | NULL |
| `is_verified` | TINYINT(1) | ID verification status | DEFAULT 0 |
| `is_online` | TINYINT(1) | Online status | DEFAULT 0 |
| `last_seen` | DATETIME | Last activity timestamp | NULL |
| `created_at` | TIMESTAMP | Account creation date | DEFAULT CURRENT_TIMESTAMP |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY (`email`)
- UNIQUE KEY (`google_uid`)
- UNIQUE KEY (`facebook_id`)
- INDEX (`is_online`, `last_seen`)

**Relationships:**
- Has many `bookings` (as renter)
- Has many `cars` (as owner)
- Has many `motorcycles` (as owner)
- Has one `user_verifications`

---

### 2. `cars` - Vehicle Listings (Cars)

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `owner_id` | INT(11) | Vehicle owner | FK → users.id |
| `brand` | VARCHAR(50) | Car brand | NOT NULL |
| `model` | VARCHAR(50) | Car model | NOT NULL |
| `car_year` | VARCHAR(50) | Year of manufacture | NOT NULL |
| `color` | VARCHAR(100) | Vehicle color | NOT NULL |
| `price_per_day` | DECIMAL(10,2) | Daily rental rate | NOT NULL |
| `description` | VARCHAR(1000) | Vehicle description | NULL |
| `plate_number` | VARCHAR(30) | License plate | NULL |
| `transmission` | VARCHAR(200) | Automatic/Manual | DEFAULT 'Automatic' |
| `fuel_type` | VARCHAR(200) | Gasoline/Diesel/Electric | DEFAULT 'Gasoline' |
| `seats` | INT(11) | Number of seats | DEFAULT 4 |
| `body_style` | VARCHAR(200) | Sedan/SUV/Van/etc | NULL |
| `latitude` | DOUBLE | GPS latitude | NULL |
| `longitude` | DOUBLE | GPS longitude | NULL |
| `location` | VARCHAR(255) | Text location | NULL |
| `address` | TEXT | Full address | NULL |
| `image` | VARCHAR(255) | Main photo path | NULL |
| `extra_images` | TEXT | JSON array of images | NULL |
| `features` | TEXT | JSON array of features | NULL |
| `rules` | TEXT | JSON array of rules | NULL |
| `official_receipt` | TEXT | OR document path | NULL |
| `certificate_of_registration` | TEXT | CR document path | NULL |
| `daily_mileage_limit` | INT(11) | KM limit per day | NULL (unlimited) |
| `excess_mileage_rate` | DECIMAL(10,2) | Cost per excess KM | DEFAULT 10.00 |
| `status` | ENUM | pending/approved/rejected/disabled | DEFAULT 'pending' |
| `rating` | FLOAT | Average rating | DEFAULT 5 |
| `report_count` | INT(11) | Number of reports | DEFAULT 0 |
| `created_at` | TIMESTAMP | Listing date | DEFAULT CURRENT_TIMESTAMP |

**Indexes:**
- PRIMARY KEY (`id`)
- FOREIGN KEY (`owner_id`) → `users(id)`
- INDEX (`owner_id`, `status`)

---

### 3. `motorcycles` - Vehicle Listings (Motorcycles)

Similar structure to `cars` table but with motorcycle-specific fields:

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `owner_id` | INT(11) | FK → users.id |
| `brand` | VARCHAR(50) | Motorcycle brand |
| `model` | VARCHAR(50) | Model name |
| `motorcycle_year` | VARCHAR(50) | Year |
| `engine_displacement` | VARCHAR(100) | Engine size (cc) |
| `transmission_type` | ENUM | Manual/Automatic/Semi-Auto |
| *(other fields similar to cars)* | | |

---

### 4. `bookings` - Rental Bookings

Central table tracking all rental transactions.

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `user_id` | INT(11) | Renter | FK → users.id |
| `owner_id` | INT(11) | Vehicle owner | FK → users.id |
| `car_id` | INT(11) | Vehicle ID | NOT NULL |
| `vehicle_type` | ENUM | 'car' or 'motorcycle' | DEFAULT 'car' |
| `pickup_date` | DATE | Pickup date | NOT NULL |
| `pickup_time` | TIME | Pickup time | NOT NULL |
| `return_date` | DATE | Return date | NOT NULL |
| `return_time` | TIME | Return time | NOT NULL |
| `pickup_location` | VARCHAR(255) | Pickup address | NULL |
| `total_amount` | DECIMAL(10,2) | Total rental cost | NOT NULL |
| `platform_fee` | DECIMAL(10,2) | CarGO fee (10%) | DEFAULT 0.00 |
| `owner_payout` | DECIMAL(10,2) | Owner earnings | DEFAULT 0.00 |
| `status` | ENUM | Booking status | DEFAULT 'pending' |
| `payment_status` | ENUM | Payment status | DEFAULT 'pending' |
| `escrow_status` | ENUM | Escrow status | DEFAULT 'pending' |
| `payout_status` | ENUM | Payout status | DEFAULT 'pending' |
| `rejection_reason` | TEXT | If rejected | NULL |
| `cancellation_reason` | TEXT | If cancelled | NULL |
| `overdue_status` | ENUM | on_time/overdue/severely_overdue | NULL |
| `overdue_days` | INT(11) | Days overdue | DEFAULT 0 |
| `late_fee_amount` | DECIMAL(10,2) | Late fee | DEFAULT 0.00 |
| `late_fee_charged` | TINYINT(1) | Late fee applied | DEFAULT 0 |
| `odometer_start` | INT(11) | Starting odometer | NULL |
| `odometer_end` | INT(11) | Ending odometer | NULL |
| `odometer_start_photo` | VARCHAR(255) | Start photo | NULL |
| `odometer_end_photo` | VARCHAR(255) | End photo | NULL |
| `actual_mileage` | INT(11) | Calculated mileage | NULL |
| `excess_mileage` | INT(11) | KM over limit | DEFAULT 0 |
| `excess_mileage_fee` | DECIMAL(10,2) | Excess fee | DEFAULT 0.00 |
| `mileage_verified_by` | INT(11) | Admin who verified | NULL |
| `mileage_verified_at` | DATETIME | Verification time | NULL |
| `trip_started` | TINYINT(1) | GPS tracking active | DEFAULT 0 |
| `completed_at` | DATETIME | Completion time | NULL |
| `created_at` | TIMESTAMP | Booking creation | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Last update | ON UPDATE CURRENT_TIMESTAMP |

**Booking Status Values:**
- `pending`: Awaiting owner approval
- `approved`: Approved by owner, awaiting payment
- `ongoing`: Trip in progress
- `completed`: Trip completed successfully
- `rejected`: Rejected by owner
- `cancelled`: Cancelled by renter/owner

**Indexes:**
- PRIMARY KEY (`id`)
- FOREIGN KEY (`user_id`) → `users(id)`
- FOREIGN KEY (`owner_id`) → `users(id)`
- INDEX (`status`)
- INDEX (`payment_status`, `booking_id`)

---

### 5. `payments` - Payment Records

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `booking_id` | INT(11) | Related booking | FK → bookings.id |
| `user_id` | INT(11) | Payer | FK → users.id |
| `amount` | DECIMAL(10,2) | Payment amount | NOT NULL |
| `payment_method` | VARCHAR(50) | gcash/cash/bank | NOT NULL |
| `payment_reference` | VARCHAR(100) | Transaction ref | NULL |
| `payment_status` | ENUM | Status | DEFAULT 'pending' |
| `verification_notes` | TEXT | Admin notes | NULL |
| `verified_by` | INT(11) | Admin ID | NULL |
| `verified_at` | DATETIME | Verification time | NULL |
| `payment_date` | DATETIME | Payment timestamp | NULL |
| `created_at` | TIMESTAMP | Record creation | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Last update | ON UPDATE CURRENT_TIMESTAMP |

**Payment Status Values:**
- `pending`: Submitted, awaiting verification
- `verified`: Verified by admin
- `paid`: Payment confirmed
- `rejected`: Payment rejected
- `failed`: Payment failed
- `released`: Released to owner
- `refunded`: Refunded to renter

**Triggers:**
- `trg_payment_verified_to_booking_paid`: Auto-updates booking.payment_status when payment is verified

---

### 6. `escrow` - Escrow Management

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `booking_id` | INT(11) | Related booking | UNIQUE, FK → bookings.id |
| `payment_id` | INT(11) | Payment record | FK → payments.id |
| `held_amount` | DECIMAL(10,2) | Amount in escrow | NOT NULL |
| `platform_fee` | DECIMAL(10,2) | CarGO commission | DEFAULT 0.00 |
| `owner_payout` | DECIMAL(10,2) | Owner earnings | DEFAULT 0.00 |
| `status` | ENUM | Escrow status | DEFAULT 'pending' |
| `held_at` | DATETIME | When funds held | NULL |
| `release_date` | DATE | Scheduled release | NULL |
| `released_at` | DATETIME | Actual release time | NULL |
| `processed_by` | INT(11) | Admin who processed | FK → admin.id |
| `notes` | TEXT | Processing notes | NULL |
| `created_at` | TIMESTAMP | Record creation | DEFAULT CURRENT_TIMESTAMP |

**Escrow Status Values:**
- `pending`: Awaiting payment
- `held`: Funds held in escrow
- `released`: Released to owner
- `refunded`: Refunded to renter
- `disputed`: Under dispute

**Auto-Release Conditions:**
- Booking status = 'completed'
- 24 hours after return_date
- No active disputes
- Mileage verified (if applicable)

---

### 7. `insurance_policies` - Insurance Coverage

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `policy_number` | VARCHAR(100) | Unique policy # | UNIQUE |
| `booking_id` | INT(11) | Related booking | FK → bookings.id |
| `user_id` | INT(11) | Policy holder | FK → users.id |
| `owner_id` | INT(11) | Vehicle owner | FK → users.id |
| `provider_id` | INT(11) | Insurance provider | FK → insurance_providers.id |
| `coverage_type` | ENUM | basic/standard/premium/comprehensive | NOT NULL |
| `premium_amount` | DECIMAL(10,2) | Insurance cost | NOT NULL |
| `coverage_limit` | DECIMAL(12,2) | Max coverage | NOT NULL |
| `deductible` | DECIMAL(10,2) | Deductible amount | DEFAULT 0.00 |
| `policy_start` | DATETIME | Coverage start | NOT NULL |
| `policy_end` | DATETIME | Coverage end | NOT NULL |
| `status` | ENUM | active/expired/cancelled/claimed | DEFAULT 'active' |
| `terms_conditions` | TEXT | Policy terms | NULL |
| `created_at` | TIMESTAMP | Policy creation | DEFAULT CURRENT_TIMESTAMP |

**Coverage Types:**
- `basic`: ₱50,000 limit, 12% premium
- `standard`: ₱100,000 limit, 15% premium
- `premium`: ₱200,000 limit, 18% premium
- `comprehensive`: ₱500,000 limit, 22% premium

---

### 8. `gps_locations` - GPS Tracking

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| `id` | INT(11) | Primary key | PK, AUTO_INCREMENT |
| `booking_id` | INT(11) | Related booking | FK → bookings.id |
| `latitude` | DECIMAL(10,8) | GPS latitude | NOT NULL |
| `longitude` | DECIMAL(11,8) | GPS longitude | NOT NULL |
| `speed` | DECIMAL(5,2) | Speed (km/h) | NULL |
| `accuracy` | DECIMAL(6,2) | GPS accuracy (m) | NULL |
| `timestamp` | DATETIME | Location timestamp | NOT NULL |

**Related Table:** `gps_distance_tracking`
- Stores cumulative distance per booking
- Uses Haversine formula for distance calculation

---

## 🔧 Supporting Tables

### `notifications` - User Notifications

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `user_id` | INT(11) | Recipient |
| `title` | VARCHAR(255) | Notification title |
| `message` | TEXT | Notification body |
| `type` | VARCHAR(50) | booking/payment/system |
| `read_status` | ENUM | read/unread |
| `created_at` | TIMESTAMP | Creation time |

### `reviews` - Ratings & Reviews

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `booking_id` | INT(11) | Related booking |
| `car_id` | INT(11) | Reviewed vehicle |
| `renter_id` | INT(11) | Reviewer |
| `owner_id` | INT(11) | Vehicle owner |
| `rating` | DECIMAL(3,1) | 1-5 stars |
| `review` | TEXT | Review text |
| `categories` | JSON | Category ratings |
| `created_at` | TIMESTAMP | Review date |

**Category Ratings:**
```json
{
  "cleanliness": 5,
  "communication": 4,
  "accuracy": 5,
  "value": 4
}
```

### `favorites` - Saved Vehicles

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `user_id` | INT(11) | User |
| `vehicle_type` | ENUM | car/motorcycle |
| `vehicle_id` | INT(11) | Vehicle ID |
| `created_at` | TIMESTAMP | Save date |

**Unique Constraint:** (`user_id`, `vehicle_type`, `vehicle_id`)

### `vehicle_availability` - Blocked Dates

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `owner_id` | INT(11) | Vehicle owner |
| `vehicle_id` | INT(11) | Vehicle |
| `vehicle_type` | VARCHAR(20) | car/motorcycle |
| `blocked_date` | DATE | Unavailable date |
| `reason` | VARCHAR(255) | Block reason |

### `user_verifications` - ID Verification

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `user_id` | INT(11) | User to verify |
| `first_name` | VARCHAR(100) | Legal first name |
| `last_name` | VARCHAR(100) | Legal last name |
| `id_type` | VARCHAR(100) | License/Passport/etc |
| `id_front_photo` | VARCHAR(255) | ID front image |
| `id_back_photo` | VARCHAR(255) | ID back image |
| `selfie_photo` | VARCHAR(255) | Selfie with ID |
| `status` | ENUM | pending/approved/rejected |
| `verified_at` | TIMESTAMP | Approval time |

**Trigger:** `prevent_duplicate_verification` - Prevents multiple pending verifications

### `reports` - Content Reports

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `reporter_id` | INT(11) | User reporting |
| `report_type` | ENUM | car/motorcycle/user/booking |
| `reported_id` | INT(11) | Entity reported |
| `reason` | VARCHAR(255) | Report reason |
| `details` | TEXT | Additional details |
| `status` | ENUM | pending/resolved/dismissed |
| `priority` | ENUM | low/medium/high |
| `image_path` | VARCHAR(255) | Evidence photo |

### `mileage_disputes` - Odometer Disputes

| Column | Type | Description |
|--------|------|-------------|
| `id` | INT(11) | Primary key |
| `booking_id` | INT(11) | Related booking |
| `dispute_type` | ENUM | Various dispute types |
| `reported_mileage` | INT(11) | System calculated |
| `claimed_mileage` | INT(11) | User claimed |
| `gps_distance` | DECIMAL(10,2) | GPS reference |
| `status` | ENUM | Status |
| `resolution` | TEXT | Admin decision |

---

## 👁️ Database Views

### `v_active_insurance_policies`
Active insurance policies with user and provider details.

### `v_escrows_ready_for_release`
Escrows eligible for automatic release (completed bookings, 24h+ after return).

### `v_escrow_statistics`
Aggregated escrow statistics by status.

### `v_insurance_claims_summary`
Insurance claims with policy and claimant information.

### `v_mileage_statistics`
Comprehensive mileage tracking statistics with GPS comparison.

### `v_overdue_bookings`
All overdue rentals with calculated fees and contact information.

---

## ⚙️ Stored Procedures

### `sp_get_vehicle_availability`
```sql
CALL sp_get_vehicle_availability(vehicle_id, vehicle_type, start_date, end_date);
```
Returns availability status for a vehicle in a date range.

---

## 🔔 Triggers

### `trg_payment_verified_to_booking_paid`
**Table:** `payments`  
**Event:** AFTER UPDATE  
**Action:** Updates booking.payment_status to 'paid' when payment is verified

### `prevent_duplicate_verification`
**Table:** `user_verifications`  
**Event:** BEFORE INSERT  
**Action:** Prevents users from submitting multiple pending verifications

---

## 📊 Indexes

### Performance Indexes

**Bookings:**
- `idx_booking_status` on (`status`)
- `idx_payment_status_booking` on (`payment_status`, `booking_id`)
- `idx_user_bookings` on (`user_id`, `status`, `created_at`)

**Payments:**
- `idx_payment_status` on (`payment_status`)
- `idx_payment_user_status` on (`user_id`, `payment_status`, `created_at`)

**Notifications:**
- `idx_notification_user_status` on (`user_id`, `read_status`)
- `idx_created_at` on (`created_at`)

**Cars/Motorcycles:**
- `idx_owner_status` on (`owner_id`, `status`)
- `idx_location` on (`latitude`, `longitude`)

---

## 🔒 Data Security

### Encrypted Fields
- User passwords (bcrypt hash)
- Payment references
- API keys (insurance providers)

### Access Control
- Row-level security via user_id checks
- Admin-only tables (separate authentication)
- Prepared statements (SQL injection prevention)

### Audit Trails
- `admin_action_logs` - Admin actions
- `escrow_logs` - Escrow transactions
- `mileage_logs` - Odometer tracking
- `overdue_logs` - Late fee history
- `report_logs` - Report status changes

---

## 📈 Database Maintenance

### Backup Strategy
- Daily full backups
- Hourly incremental backups
- 30-day retention policy

### Optimization
- Regular ANALYZE TABLE
- Index optimization monthly
- Partition large tables (logs) by month

### Monitoring
- Query performance tracking
- Slow query log analysis
- Connection pool monitoring

---

## 🔄 Migration History

### Version 1.0.0 (Initial)
- Core tables: users, cars, motorcycles, bookings
- Payment and escrow system
- Basic GPS tracking

### Version 1.1.0
- Insurance system implementation
- Mileage tracking and disputes
- Enhanced escrow automation

### Version 1.2.0
- Online status tracking
- Notification archiving
- Report priority system
- Rental extensions

---

**Schema Version:** 1.2.0  
**Last Updated:** February 2024  
**Maintained By:** CarGO Development Team
