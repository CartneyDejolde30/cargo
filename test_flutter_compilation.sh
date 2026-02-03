#!/bin/bash

echo "=================================="
echo "Flutter Mileage System Test"
echo "=================================="
echo ""

# Test 1: Check Flutter installation
echo "Test 1: Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    echo "✓ Flutter is installed"
    flutter --version | head -n 1
else
    echo "✗ Flutter not found"
    exit 1
fi

echo ""
echo "Test 2: Analyzing mileage system files..."

# Check if files exist
FILES=(
    "lib/USERS-UI/widgets/odometer_input_screen.dart"
    "lib/USERS-UI/services/gps_distance_calculator.dart"
    "lib/USERS-UI/Renter/payments/excess_mileage_payment_screen.dart"
    "lib/USERS-UI/Owner/car_listing/car_rules_screen.dart"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo ""
echo "Test 3: Running Flutter analyze..."
flutter analyze lib/USERS-UI/widgets/odometer_input_screen.dart \
                lib/USERS-UI/services/gps_distance_calculator.dart \
                lib/USERS-UI/Renter/payments/excess_mileage_payment_screen.dart

echo ""
echo "Test 4: Checking for compilation errors..."
flutter analyze --no-pub 2>&1 | grep -i "error" | head -n 10

echo ""
echo "=================================="
echo "Test Complete!"
echo "=================================="
