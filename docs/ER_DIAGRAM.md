# 🗄️ CarGO Database - Entity Relationship Diagram

## Overview
This document provides a comprehensive visual representation of the CarGO database schema, showing relationships between entities and their attributes.

---

## Entity Relationship Diagram

```mermaid
erDiagram
    USERS ||--o{ CARS : owns
    USERS ||--o{ MOTORCYCLES : owns
    USERS ||--o{ BOOKINGS : "rents/provides"
    USERS ||--o{ PAYMENTS : makes
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ REVIEWS : "writes/receives"
    USERS ||--o{ REPORTS : submits
    USERS ||--o{ MESSAGES : sends
    USERS ||--o{ VERIFICATION : submits
    USERS ||--o{ FAVORITES : saves
    
    CARS ||--o{ BOOKINGS : "booked_via"
    CARS ||--o{ REVIEWS : "reviewed_in"
    CARS ||--o{ CAR_IMAGES : has
    CARS ||--o{ BLOCKED_DATES : has
    
    MOTORCYCLES ||--o{ BOOKINGS : "booked_via"
    MOTORCYCLES ||--o{ MOTORCYCLE_IMAGES : has
    MOTORCYCLES ||--o{ BLOCKED_DATES : has
    
    BOOKINGS ||--o{ PAYMENTS : "paid_with"
    BOOKINGS ||--o{ ESCROW_TRANSACTIONS : "secured_by"
    BOOKINGS ||--o{ INSURANCE_POLICIES : "insured_by"
    BOOKINGS ||--o{ GPS_LOCATIONS : "tracked_in"
    BOOKINGS ||--o{ MILEAGE_RECORDS : "has"
    BOOKINGS ||--o{ TRIP_EXTENSIONS : "extended_by"
    BOOKINGS ||--|| ODOMETER_START : "starts_with"
    BOOKINGS ||--|| ODOMETER_END : "ends_with"
    
    INSURANCE_POLICIES ||--o{ INSURANCE_CLAIMS : "generates"
    
    MILEAGE_RECORDS ||--o{ MILEAGE_DISPUTES : "disputed_in"
    
    PAYMENTS ||--o{ PAYOUT_REQUESTS : "generates"
    
    USERS {
        int id PK
        string name
        string email UK
        string password
        string phone
        string role "owner/renter/admin"
        string profile_image
        string address
        boolean is_verified
        boolean is_online
        datetime last_seen
        datetime created_at
    }
    
    CARS {
        int id PK
        int owner_id FK
        string brand
        string model
        int year
        string plate_number UK
        string color
        int seats
        string transmission "Manual/Automatic"
        string fuel_type
        float price_per_day
        string location
        float latitude
        float longitude
        string status "available/rented/maintenance"
        string main_image
        text description
        text features
        datetime created_at
    }
    
    MOTORCYCLES {
        int id PK
        int owner_id FK
        string brand
        string model
        int year
        string plate_number UK
        string color
        string type "Scooter/Sport/Cruiser"
        float engine_size
        float price_per_day
        string location
        float latitude
        float longitude
        string status "available/rented/maintenance"
        string main_image
        text description
        datetime created_at
    }
    
    BOOKINGS {
        int id PK
        int user_id FK "renter"
        int owner_id FK
        int car_id FK "nullable"
        int motorcycle_id FK "nullable"
        string vehicle_type "car/motorcycle"
        date start_date
        date end_date
        float total_price
        string status "pending/confirmed/ongoing/completed/cancelled/rejected"
        string pickup_location
        text cancellation_reason
        datetime trip_started_at
        datetime trip_ended_at
        boolean is_overdue
        float late_fee
        datetime created_at
    }
    
    PAYMENTS {
        int id PK
        int booking_id FK
        int user_id FK
        float amount
        string payment_method "GCash/Cash"
        string payment_proof
        string status "pending/completed/refunded"
        string transaction_id UK
        datetime payment_date
        datetime created_at
    }
    
    ESCROW_TRANSACTIONS {
        int id PK
        int booking_id FK UK
        int payment_id FK
        float amount
        string status "held/released/refunded"
        datetime held_at
        datetime released_at
        text release_reason
        datetime created_at
    }
    
    INSURANCE_POLICIES {
        int id PK
        int booking_id FK UK
        int user_id FK
        string policy_number UK
        string coverage_type "Basic/Standard/Premium"
        float coverage_amount
        float premium_amount
        date start_date
        date end_date
        string status "active/expired/claimed"
        text terms
        string pdf_path
        datetime created_at
    }
    
    INSURANCE_CLAIMS {
        int id PK
        int policy_id FK
        int booking_id FK
        string claim_number UK
        string incident_type
        text description
        float claim_amount
        string status "pending/approved/rejected/paid"
        string evidence_photos
        datetime incident_date
        datetime created_at
    }
    
    GPS_LOCATIONS {
        int id PK
        int booking_id FK
        float latitude
        float longitude
        float speed
        string address
        datetime recorded_at
    }
    
    MILEAGE_RECORDS {
        int id PK
        int booking_id FK
        string type "start/end"
        float odometer_reading
        string photo_proof
        float gps_latitude
        float gps_longitude
        datetime recorded_at
        int recorded_by FK "user_id"
    }
    
    MILEAGE_DISPUTES {
        int id PK
        int booking_id FK
        int mileage_record_id FK
        int reported_by FK "user_id"
        float reported_odometer
        float system_calculated_distance
        float discrepancy
        string status "pending/resolved/rejected"
        text resolution_notes
        datetime created_at
    }
    
    ODOMETER_START {
        int id PK
        int booking_id FK UK
        float reading
        string photo
        float latitude
        float longitude
        datetime recorded_at
    }
    
    ODOMETER_END {
        int id PK
        int booking_id FK UK
        float reading
        string photo
        float latitude
        float longitude
        datetime recorded_at
    }
    
    TRIP_EXTENSIONS {
        int id PK
        int booking_id FK
        date original_end_date
        date new_end_date
        int extended_days
        float additional_cost
        string status "pending/approved/rejected"
        datetime requested_at
        datetime approved_at
    }
    
    NOTIFICATIONS {
        int id PK
        int user_id FK
        string title
        text message
        string type "booking/payment/message/system"
        string related_id "booking_id/payment_id"
        boolean is_read
        datetime created_at
    }
    
    REVIEWS {
        int id PK
        int booking_id FK UK
        int reviewer_id FK "user_id"
        int reviewed_user_id FK "owner_id"
        int car_id FK "nullable"
        int motorcycle_id FK "nullable"
        int rating "1-5"
        text comment
        text response
        datetime created_at
    }
    
    REPORTS {
        int id PK
        int reporter_id FK "user_id"
        int reported_user_id FK "nullable"
        int booking_id FK "nullable"
        string category "user/vehicle/payment/other"
        string priority "low/medium/high/urgent"
        text description
        string evidence_files
        string status "pending/investigating/resolved/closed"
        text admin_notes
        datetime created_at
    }
    
    MESSAGES {
        int id PK
        int sender_id FK "user_id"
        int receiver_id FK "user_id"
        int booking_id FK "nullable"
        text message
        boolean is_read
        datetime created_at
    }
    
    CAR_IMAGES {
        int id PK
        int car_id FK
        string image_path
        string image_type "main/or/cr/extra"
        datetime uploaded_at
    }
    
    MOTORCYCLE_IMAGES {
        int id PK
        int motorcycle_id FK
        string image_path
        string image_type "main/or/cr/extra"
        datetime uploaded_at
    }
    
    BLOCKED_DATES {
        int id PK
        int vehicle_id FK
        string vehicle_type "car/motorcycle"
        date blocked_date
        string reason
        datetime created_at
    }
    
    VERIFICATION {
        int id PK
        int user_id FK
        string id_type "Driver License/Passport/National ID"
        string id_number
        string id_front_image
        string id_back_image
        string selfie_image
        string status "pending/approved/rejected"
        text rejection_reason
        datetime submitted_at
        datetime verified_at
    }
    
    FAVORITES {
        int id PK
        int user_id FK
        int vehicle_id FK
        string vehicle_type "car/motorcycle"
        datetime created_at
    }
    
    PAYOUT_REQUESTS {
        int id PK
        int owner_id FK "user_id"
        int booking_id FK
        int payment_id FK
        float amount
        string method "GCash/Bank Transfer"
        string account_details
        string proof_image
        string status "pending/processing/completed/rejected"
        datetime requested_at
        datetime completed_at
    }
```

---

## Key Relationships Explained

### 1. **User-Centric Relationships**
- **Users ↔ Vehicles**: One user (owner) can have multiple cars and motorcycles
- **Users ↔ Bookings**: Users can be both renters and owners in different bookings
- **Users ↔ Reviews**: Users can write reviews and receive reviews
- **Users ↔ Verification**: Each user can submit one verification request

### 2. **Booking-Centric Relationships**
- **Bookings ↔ Vehicles**: Each booking is for one vehicle (either car OR motorcycle)
- **Bookings ↔ Payments**: One booking can have multiple payments (partial payments, refunds)
- **Bookings ↔ Insurance**: One booking has one insurance policy
- **Bookings ↔ GPS Tracking**: Bookings have multiple GPS location records during trips
- **Bookings ↔ Mileage**: Each booking has start and end odometer readings

### 3. **Payment Flow**
- **Payments → Escrow**: Payment creates escrow transaction (held until trip completion)
- **Escrow → Payout**: Released escrow triggers payout to owner
- **Insurance → Claims**: Active policies can generate claims

### 4. **Vehicle Management**
- **Vehicles ↔ Images**: Multiple images per vehicle (main, OR, CR, extras)
- **Vehicles ↔ Blocked Dates**: Owners can block dates for personal use
- **Vehicles ↔ Reviews**: Vehicles accumulate reviews from completed bookings

---

## Database Statistics

| Entity | Estimated Records | Growth Rate |
|--------|------------------|-------------|
| Users | 100-500 | Medium |
| Cars | 50-200 | Medium |
| Motorcycles | 30-100 | Low |
| Bookings | 500-2000 | High |
| Payments | 500-2000 | High |
| GPS Locations | 10,000+ | Very High |
| Notifications | 5,000+ | High |
| Reviews | 200-800 | Medium |

---

## Indexes & Performance

### Primary Indexes (Primary Keys)
All tables have auto-incrementing `id` as primary key.

### Foreign Key Indexes
- `bookings.user_id` → `users.id`
- `bookings.owner_id` → `users.id`
- `bookings.car_id` → `cars.id`
- `bookings.motorcycle_id` → `motorcycles.id`
- `payments.booking_id` → `bookings.id`
- `gps_locations.booking_id` → `bookings.id`

### Unique Constraints
- `users.email` - Ensures unique user accounts
- `cars.plate_number` - Prevents duplicate vehicle registration
- `insurance_policies.policy_number` - Unique policy identification
- `payments.transaction_id` - Prevents duplicate transactions

### Composite Indexes (Performance Optimization)
- `(booking_id, created_at)` on `gps_locations` - For trip tracking queries
- `(user_id, status)` on `bookings` - For user dashboard
- `(vehicle_id, blocked_date)` on `blocked_dates` - For availability checks
- `(user_id, is_read)` on `notifications` - For unread counts

---

## Data Integrity Rules

### Cascading Deletes
- Deleting a car/motorcycle → Archive bookings (soft delete)
- Deleting a user → Archive all related data (GDPR compliance)

### Status Transitions
**Booking Status Flow:**
```
pending → confirmed → ongoing → completed
        ↓           ↓
    rejected    cancelled
```

**Payment Status Flow:**
```
pending → completed → (optional) refunded
```

**Escrow Status Flow:**
```
held → released
     ↓
   refunded
```

---

## Caraga Region Context

### Location Data
- **Coordinates**: Latitude/Longitude for Butuan City, Surigao, Agusan regions
- **Coverage Area**: Agusan del Norte, Agusan del Sur, Surigao del Norte, Surigao del Sur
- **Primary Cities**: Butuan City, Surigao City, Tandag, Bayugan

### Local Considerations
- Vehicle plate numbers follow Philippine LTO format
- Pricing in Philippine Peso (₱)
- Phone numbers in Philippine format (+63)
- Timezone: Asia/Manila (UTC+8)

---

## Security & Privacy

### Sensitive Data
- Passwords: Hashed using bcrypt/password_hash()
- Payment proofs: Stored with restricted access
- ID verification images: Encrypted at rest
- GPS locations: Anonymized after 90 days

### Access Control
- Role-based permissions (Admin/Owner/Renter)
- Owners can only modify their own vehicles
- Users can only view their own bookings/payments
- Admins have read-only access to sensitive data

---

## Backup & Recovery

### Backup Strategy
- **Full Backup**: Daily at 2:00 AM Manila Time
- **Incremental Backup**: Every 6 hours
- **Retention**: 30 days for daily, 7 days for incremental
- **Location**: Off-site secure storage

### Critical Tables (Priority Backup)
1. `users` - User accounts
2. `bookings` - Booking records
3. `payments` - Financial transactions
4. `escrow_transactions` - Held funds
5. `insurance_policies` - Active policies

---

**Last Updated:** February 16, 2026  
**Database Version:** 2.0  
**Total Tables:** 25+  
**Total Relationships:** 40+
