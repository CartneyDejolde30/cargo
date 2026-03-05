# 📚 CarGO API Documentation

**Version:** 1.0.0  
**Base URL:** `https://your-domain.com/cargoAdmin/api/`  
**Authentication:** Session-based with token support

---

## 📑 Table of Contents

1. [Authentication](#authentication)
2. [Vehicle Management](#vehicle-management)
3. [Booking Management](#booking-management)
4. [Payment & Escrow](#payment--escrow)
5. [Insurance System](#insurance-system)
6. [GPS Tracking](#gps-tracking)
7. [User Management](#user-management)
8. [Notifications](#notifications)
9. [Reviews & Ratings](#reviews--ratings)
10. [Reports & Analytics](#reports--analytics)

---

## 🔐 Authentication

### Register User
**Endpoint:** `POST /register.php`

**Request Body:**
```json
{
  "fullname": "John Doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "contact": "+639123456789",
  "auth_provider": "email"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registration successful",
  "user_id": 123,
  "user": {
    "id": 123,
    "fullname": "John Doe",
    "email": "john@example.com",
    "contact": "+639123456789"
  }
}
```

### Login
**Endpoint:** `POST /login.php`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 123,
    "fullname": "John Doe",
    "email": "john@example.com",
    "contact": "+639123456789",
    "profile_image": "uploads/profile_123.jpg",
    "is_verified": true,
    "is_online": true
  }
}
```

### Google Sign-In
**Endpoint:** `POST /google_register.php`

**Request Body:**
```json
{
  "google_uid": "google-user-id",
  "email": "john@gmail.com",
  "fullname": "John Doe",
  "profile_image": "https://lh3.googleusercontent.com/..."
}
```

### Facebook Sign-In
**Endpoint:** `POST /facebook_register.php`

**Request Body:**
```json
{
  "facebook_id": "facebook-user-id",
  "email": "john@facebook.com",
  "fullname": "John Doe",
  "profile_image": "https://graph.facebook.com/..."
}
```

---

## 🚗 Vehicle Management

### Get All Cars (Filtered)
**Endpoint:** `GET /api/get_cars_filtered.php`

**Query Parameters:**
- `location` (optional): Filter by location
- `min_price` (optional): Minimum price per day
- `max_price` (optional): Maximum price per day
- `seats` (optional): Number of seats
- `transmission` (optional): "Automatic" or "Manual"
- `fuel_type` (optional): "Gasoline", "Diesel", "Electric"
- `features` (optional): Comma-separated features
- `user_id` (optional): For personalized results

**Example:**
```
GET /api/get_cars_filtered.php?location=Manila&min_price=500&max_price=2000&seats=4&transmission=Automatic
```

**Response:**
```json
{
  "success": true,
  "cars": [
    {
      "id": 1,
      "brand": "Toyota",
      "model": "Vios",
      "car_year": "2023",
      "price_per_day": 1500,
      "location": "Manila",
      "seats": 4,
      "transmission": "Automatic",
      "fuel_type": "Gasoline",
      "rating": 4.8,
      "image": "uploads/car_1.jpg",
      "latitude": 14.5995,
      "longitude": 120.9842,
      "is_favorite": false,
      "features": ["Air Conditioning", "Bluetooth", "GPS"]
    }
  ],
  "total": 15
}
```

### Get Car Details
**Endpoint:** `GET /api/get_car_details.php?car_id={id}`

**Response:**
```json
{
  "success": true,
  "car": {
    "id": 1,
    "brand": "Toyota",
    "model": "Vios",
    "car_year": "2023",
    "color": "White",
    "price_per_day": 1500,
    "description": "Well-maintained sedan...",
    "location": "Manila",
    "seats": 4,
    "transmission": "Automatic",
    "fuel_type": "Gasoline",
    "rating": 4.8,
    "review_count": 24,
    "images": [
      "uploads/car_1_main.jpg",
      "uploads/car_1_interior.jpg"
    ],
    "features": ["Air Conditioning", "Bluetooth", "GPS"],
    "rules": ["No smoking", "No pets"],
    "owner": {
      "id": 5,
      "fullname": "Jane Smith",
      "profile_image": "uploads/profile_5.jpg",
      "rating": 4.9,
      "total_rentals": 45,
      "member_since": "2023-01-15"
    },
    "availability": {
      "blocked_dates": ["2024-02-20", "2024-02-21"]
    }
  }
}
```

### Add Vehicle (Owner)
**Endpoint:** `POST /api/vechicle/add_car.php`

**Request Body (multipart/form-data):**
```
brand: Toyota
model: Vios
car_year: 2023
color: White
price_per_day: 1500
description: Well-maintained sedan
location: Manila
seats: 4
transmission: Automatic
fuel_type: Gasoline
features: ["Air Conditioning", "Bluetooth", "GPS"]
plate_number: ABC1234
latitude: 14.5995
longitude: 120.9842
main_image: [file]
official_receipt: [file]
certificate_of_registration: [file]
extra_images: [file, file, file]
```

**Response:**
```json
{
  "success": true,
  "message": "Car listed successfully. Pending admin approval.",
  "car_id": 123,
  "status": "pending"
}
```

### Get Motorcycles (Filtered)
**Endpoint:** `GET /api/get_motorcycles_filtered.php`

**Query Parameters:**
- `location`, `min_price`, `max_price`, `transmission_type`, `engine_displacement`

---

## 📅 Booking Management

### Create Booking
**Endpoint:** `POST /api/create_booking.php`

**Request Body:**
```json
{
  "user_id": 123,
  "car_id": 45,
  "vehicle_type": "car",
  "pickup_date": "2024-02-20",
  "pickup_time": "10:00:00",
  "return_date": "2024-02-25",
  "return_time": "18:00:00",
  "pickup_location": "Manila Hotel",
  "total_amount": 7500,
  "insurance_id": 2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Booking created successfully",
  "booking_id": 456,
  "status": "pending",
  "requires_payment": true
}
```

### Get My Bookings
**Endpoint:** `GET /api/get_my_bookings.php?user_id={id}&status={status}`

**Query Parameters:**
- `user_id`: Required
- `status`: Optional ("pending", "approved", "ongoing", "completed", "cancelled")
- `page`: Optional (default: 1)
- `limit`: Optional (default: 20)

**Response:**
```json
{
  "success": true,
  "bookings": [
    {
      "id": 456,
      "vehicle_type": "car",
      "vehicle": {
        "id": 45,
        "brand": "Toyota",
        "model": "Vios",
        "image": "uploads/car_45.jpg"
      },
      "pickup_date": "2024-02-20",
      "pickup_time": "10:00:00",
      "return_date": "2024-02-25",
      "return_time": "18:00:00",
      "status": "approved",
      "payment_status": "paid",
      "total_amount": 7500,
      "owner": {
        "id": 5,
        "fullname": "Jane Smith",
        "contact": "+639987654321"
      },
      "can_review": true,
      "can_track": true
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 3,
    "total_bookings": 45
  }
}
```

### Approve/Reject Booking (Owner)
**Endpoint:** `POST /api/approve_request.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "action": "approve"
}
```

**Reject:**
```json
{
  "booking_id": 456,
  "action": "reject",
  "rejection_reason": "Vehicle unavailable for maintenance"
}
```

### Cancel Booking
**Endpoint:** `POST /api/cancel_booking.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "user_id": 123,
  "cancellation_reason": "Change of plans"
}
```

---

## 💰 Payment & Escrow

### Submit Payment
**Endpoint:** `POST /api/submit_payment.php`

**Request Body (multipart/form-data):**
```
booking_id: 456
user_id: 123
amount: 7500
payment_method: gcash
gcash_number: 09123456789
payment_reference: GC-2024-123456
payment_proof: [file]
```

**Response:**
```json
{
  "success": true,
  "message": "Payment submitted. Awaiting admin verification.",
  "payment_id": 789
}
```

### Get Payment Status
**Endpoint:** `GET /api/payment/get_payment_status.php?booking_id={id}`

**Response:**
```json
{
  "success": true,
  "payment": {
    "id": 789,
    "booking_id": 456,
    "amount": 7500,
    "payment_method": "gcash",
    "payment_status": "verified",
    "payment_reference": "GC-2024-123456",
    "verified_at": "2024-02-18 14:30:00"
  },
  "escrow": {
    "status": "held",
    "held_amount": 7500,
    "platform_fee": 750,
    "owner_payout": 6750,
    "release_date": "2024-02-26"
  }
}
```

### Request Payout (Owner)
**Endpoint:** `POST /api/payout/request_payout.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "owner_id": 5,
  "gcash_number": "09987654321",
  "amount": 6750
}
```

---

## 🛡️ Insurance System

### Get Insurance Plans
**Endpoint:** `GET /api/insurance/get_plans.php`

**Response:**
```json
{
  "success": true,
  "plans": [
    {
      "id": 1,
      "coverage_type": "basic",
      "coverage_name": "Basic Protection",
      "description": "Covers collision and theft up to ₱50,000",
      "premium_rate": 0.12,
      "coverage_limit": 50000,
      "features": [
        "Collision damage waiver",
        "Theft protection",
        "Third-party liability"
      ]
    },
    {
      "id": 2,
      "coverage_type": "premium",
      "coverage_name": "Premium Protection",
      "description": "Comprehensive coverage up to ₱200,000",
      "premium_rate": 0.18,
      "coverage_limit": 200000,
      "features": [
        "Full collision coverage",
        "Theft protection",
        "Personal injury protection",
        "Roadside assistance"
      ]
    }
  ]
}
```

### Create Insurance Policy
**Endpoint:** `POST /api/insurance/create_policy.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "user_id": 123,
  "coverage_type": "premium",
  "rental_amount": 7500
}
```

**Response:**
```json
{
  "success": true,
  "policy": {
    "policy_number": "POL-2024-001234",
    "coverage_type": "premium",
    "premium_amount": 1350,
    "coverage_limit": 200000,
    "policy_start": "2024-02-20 10:00:00",
    "policy_end": "2024-02-25 18:00:00",
    "status": "active"
  }
}
```

### File Insurance Claim
**Endpoint:** `POST /api/insurance/file_claim.php`

**Request Body (multipart/form-data):**
```
policy_id: 123
booking_id: 456
claim_type: collision
incident_date: 2024-02-22 15:30:00
incident_location: EDSA, Quezon City
incident_description: Minor collision while parking
claimed_amount: 15000
evidence_photos: [file, file, file]
police_report: [file]
```

---

## 📍 GPS Tracking

### Update GPS Location
**Endpoint:** `POST /api/GPS_tracking/update_location.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "latitude": 14.5995,
  "longitude": 120.9842,
  "speed": 45.5,
  "accuracy": 10.2,
  "timestamp": "2024-02-22 10:30:00"
}
```

### Get Vehicle Location
**Endpoint:** `GET /api/GPS_tracking/get_location.php?booking_id={id}`

**Response:**
```json
{
  "success": true,
  "location": {
    "booking_id": 456,
    "latitude": 14.5995,
    "longitude": 120.9842,
    "speed": 45.5,
    "last_updated": "2024-02-22 10:30:00",
    "total_distance_km": 125.5
  }
}
```

### Get Trip History
**Endpoint:** `GET /api/GPS_tracking/get_trip_history.php?booking_id={id}`

**Response:**
```json
{
  "success": true,
  "trip": {
    "booking_id": 456,
    "total_distance_km": 125.5,
    "waypoints_count": 342,
    "started_at": "2024-02-20 10:00:00",
    "last_updated": "2024-02-22 10:30:00",
    "waypoints": [
      {
        "latitude": 14.5995,
        "longitude": 120.9842,
        "speed": 45.5,
        "timestamp": "2024-02-22 10:30:00"
      }
    ]
  }
}
```

---

## 👤 User Management

### Get User Profile
**Endpoint:** `GET /api/get_profile.php?user_id={id}`

**Response:**
```json
{
  "success": true,
  "user": {
    "id": 123,
    "fullname": "John Doe",
    "email": "john@example.com",
    "contact": "+639123456789",
    "profile_image": "uploads/profile_123.jpg",
    "is_verified": true,
    "verification_status": "approved",
    "member_since": "2023-06-15",
    "stats": {
      "total_bookings": 12,
      "completed_trips": 10,
      "rating": 4.9,
      "reviews_count": 8
    }
  }
}
```

### Update Profile
**Endpoint:** `POST /api/update_profile.php`

**Request Body (multipart/form-data):**
```
user_id: 123
fullname: John Doe
contact: +639123456789
profile_image: [file]
```

### Submit Verification
**Endpoint:** `POST /api/submit_verification.php`

**Request Body (multipart/form-data):**
```
user_id: 123
first_name: John
last_name: Doe
email: john@example.com
mobile_number: +639123456789
region: NCR
province: Metro Manila
municipality: Quezon City
barangay: Diliman
date_of_birth: 1995-05-15
id_type: Drivers License
id_front_photo: [file]
id_back_photo: [file]
selfie_photo: [file]
```

---

## 🔔 Notifications

### Get Notifications
**Endpoint:** `GET /api/notifications/get_notifications.php?user_id={id}&limit={limit}`

**Response:**
```json
{
  "success": true,
  "notifications": [
    {
      "id": 789,
      "title": "Booking Approved",
      "message": "Your booking for Toyota Vios has been approved!",
      "type": "booking",
      "read_status": "unread",
      "created_at": "2024-02-18 14:30:00",
      "link": "/bookings/456"
    }
  ],
  "unread_count": 3
}
```

### Mark as Read
**Endpoint:** `POST /api/notifications/mark_read.php`

**Request Body:**
```json
{
  "notification_id": 789
}
```

### Save FCM Token
**Endpoint:** `POST /api/save_fcm_token.php`

**Request Body:**
```json
{
  "user_id": 123,
  "fcm_token": "firebase-cloud-messaging-token"
}
```

---

## ⭐ Reviews & Ratings

### Submit Review
**Endpoint:** `POST /api/submit_review.php`

**Request Body:**
```json
{
  "booking_id": 456,
  "car_id": 45,
  "renter_id": 123,
  "owner_id": 5,
  "rating": 5,
  "review": "Excellent service! Car was clean and owner was very accommodating.",
  "categories": {
    "cleanliness": 5,
    "communication": 5,
    "accuracy": 5,
    "value": 4
  }
}
```

### Get Vehicle Reviews
**Endpoint:** `GET /api/get_reviews.php?car_id={id}&vehicle_type=car`

**Response:**
```json
{
  "success": true,
  "reviews": [
    {
      "id": 123,
      "renter": {
        "fullname": "John Doe",
        "profile_image": "uploads/profile_123.jpg"
      },
      "rating": 5,
      "review": "Excellent service!",
      "categories": {
        "cleanliness": 5,
        "communication": 5,
        "accuracy": 5,
        "value": 4
      },
      "created_at": "2024-02-15 10:00:00"
    }
  ],
  "average_rating": 4.8,
  "total_reviews": 24
}
```

---

## 📊 Reports & Analytics

### Submit Report
**Endpoint:** `POST /api/submit_report.php`

**Request Body (multipart/form-data):**
```
reporter_id: 123
report_type: car
reported_id: 45
reason: Misleading information
details: The car condition doesn't match the photos
evidence_image: [file]
```

### Get Dashboard Stats (Owner)
**Endpoint:** `GET /api/dashboard/get_stats.php?owner_id={id}`

**Response:**
```json
{
  "success": true,
  "stats": {
    "total_vehicles": 5,
    "active_bookings": 3,
    "pending_requests": 2,
    "total_revenue": 125000,
    "monthly_revenue": 45000,
    "average_rating": 4.8,
    "total_trips": 156
  },
  "recent_bookings": [],
  "revenue_trend": []
}
```

### Export Bookings
**Endpoint:** `GET /api/analytics/export_bookings.php?owner_id={id}&format=pdf`

**Query Parameters:**
- `owner_id`: Required
- `format`: "pdf" or "excel"
- `start_date`: Optional
- `end_date`: Optional

---

## 📝 Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error message description",
  "error_code": "ERROR_CODE",
  "details": "Additional error details (in development mode)"
}
```

### Common Error Codes
- `AUTH_REQUIRED`: Authentication required
- `INVALID_CREDENTIALS`: Invalid email or password
- `USER_NOT_FOUND`: User does not exist
- `BOOKING_NOT_FOUND`: Booking not found
- `PAYMENT_REQUIRED`: Payment verification required
- `INSUFFICIENT_BALANCE`: Insufficient escrow balance
- `UNAUTHORIZED`: User not authorized for this action
- `VALIDATION_ERROR`: Input validation failed
- `SERVER_ERROR`: Internal server error

---

## 🔄 Status Codes

### HTTP Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `422`: Validation Error
- `500`: Internal Server Error

### Booking Statuses
- `pending`: Awaiting owner approval
- `approved`: Approved by owner
- `ongoing`: Trip in progress
- `completed`: Trip completed successfully
- `rejected`: Rejected by owner
- `cancelled`: Cancelled by renter or owner

### Payment Statuses
- `pending`: Payment submitted, awaiting verification
- `verified`: Payment verified by admin
- `paid`: Payment confirmed
- `rejected`: Payment rejected
- `failed`: Payment processing failed
- `refunded`: Payment refunded to renter

### Escrow Statuses
- `pending`: Awaiting payment
- `held`: Funds held in escrow
- `released`: Funds released to owner
- `refunded`: Funds refunded to renter

---

## 🔧 Rate Limiting

- **Anonymous requests**: 100 requests per hour
- **Authenticated users**: 1000 requests per hour
- **Owner accounts**: 2000 requests per hour

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 998
X-RateLimit-Reset: 1709123456
```

---

## 📞 Support

For API support and technical questions:
- **Email**: api-support@cargo.com
- **Documentation**: https://docs.cargo.com
- **Status Page**: https://status.cargo.com

---

**Last Updated:** February 2024  
**API Version:** 1.0.0
