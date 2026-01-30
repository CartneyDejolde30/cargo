# Revenue Breakdown Widget - Usage Guide

## 📦 What's Included

Three widgets for displaying revenue breakdown:

1. **`RevenueBreakdownWidget`** - Full detailed breakdown for one period
2. **`ExpandableRevenueBreakdown`** - Switchable between all periods (Total/Month/Week/Today)
3. **`CompactRevenueSummary`** - Quick summary card with optional tap to expand

---

## 🎨 Widget 1: RevenueBreakdownWidget

Shows detailed revenue breakdown for a specific period.

### Usage

```dart
import 'package:cargo/USERS-UI/Owner/dashboard/revenue_breakdown_widget.dart';

RevenueBreakdownWidget(
  revenueBreakdown: dashboardStats.revenueBreakdown,
  period: 'total', // 'total', 'monthly', 'weekly', or 'today'
)
```

### Example

```dart
// In your dashboard screen
Widget build(BuildContext context) {
  return Column(
    children: [
      // Your existing widgets...
      
      // Add revenue breakdown
      RevenueBreakdownWidget(
        revenueBreakdown: _stats?.revenueBreakdown,
        period: 'total',
      ),
    ],
  );
}
```

### Features
- ✅ Shows gross revenue
- ✅ Shows late fees (if any)
- ✅ Shows refunds (if any)
- ✅ Shows net revenue (bold, highlighted)
- ✅ Beautiful gradient design
- ✅ Color-coded amounts (green for positive, red for negative)

---

## 🎨 Widget 2: ExpandableRevenueBreakdown (RECOMMENDED)

Shows revenue breakdown with period selector tabs.

### Usage

```dart
ExpandableRevenueBreakdown(
  revenueBreakdown: dashboardStats.revenueBreakdown,
)
```

### Example

```dart
// In your dashboard screen
class DashboardScreen extends StatelessWidget {
  final DashboardStats stats;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Dashboard header
          DashboardHeader(...),
          
          // Revenue Overview (existing)
          RevenueOverview(
            totalIncome: stats.totalIncome,
            monthlyIncome: stats.monthlyIncome,
            weeklyIncome: stats.weeklyIncome,
            todayIncome: stats.todayIncome,
          ),
          
          // NEW: Expandable Revenue Breakdown
          ExpandableRevenueBreakdown(
            revenueBreakdown: stats.revenueBreakdown,
          ),
          
          // Rest of dashboard...
          QuickActions(),
          UpcomingBookings(),
        ],
      ),
    );
  }
}
```

### Features
- ✅ Tab selector for All Time / Month / Week / Today
- ✅ Smooth transitions between periods
- ✅ Responsive design
- ✅ Shows detailed breakdown per period

---

## 🎨 Widget 3: CompactRevenueSummary

Quick summary card with optional tap-to-expand functionality.

### Usage

```dart
CompactRevenueSummary(
  revenueBreakdown: dashboardStats.revenueBreakdown,
  onTapDetails: () {
    // Navigate to detailed view or show modal
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => RevenueDetailsScreen(),
    ));
  },
)
```

### Example

```dart
// As a summary card
Column(
  children: [
    CompactRevenueSummary(
      revenueBreakdown: stats.revenueBreakdown,
      onTapDetails: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: EdgeInsets.all(20),
            child: ExpandableRevenueBreakdown(
              revenueBreakdown: stats.revenueBreakdown,
            ),
          ),
        );
      },
    ),
  ],
)
```

### Features
- ✅ Compact single-line display
- ✅ Shows net revenue prominently
- ✅ Shows refund summary if applicable
- ✅ Optional tap handler for navigation
- ✅ Arrow icon when tappable

---

## 📊 Data Structure

The widgets expect this data structure from the API:

```dart
Map<String, dynamic> revenueBreakdown = {
  'total': {
    'gross_revenue': 22755.60,
    'late_fees': 0.00,
    'refunds_issued': 256.20,
    'net_revenue': 22499.40
  },
  'monthly': {
    'gross_revenue': 22755.60,
    'refunds_issued': 256.20,
    'net_revenue': 22499.40
  },
  'weekly': {
    'gross_revenue': 3296.16,
    'refunds_issued': 256.20,
    'net_revenue': 3039.96
  },
  'today': {
    'gross_revenue': 0.00,
    'refunds_issued': 0.00,
    'net_revenue': 0.00
  }
};
```

---

## 🔧 Integration Steps

### Step 1: Update DashboardStats Model (Optional)

If you want strongly-typed access:

```dart
// In dashboard_stats.dart
class DashboardStats {
  final double totalIncome;
  final double monthlyIncome;
  final double weeklyIncome;
  final double todayIncome;
  final Map<String, dynamic>? revenueBreakdown; // ADD THIS
  
  // ... rest of fields
  
  DashboardStats({
    required this.totalIncome,
    required this.monthlyIncome,
    required this.weeklyIncome,
    required this.todayIncome,
    this.revenueBreakdown, // ADD THIS
    // ... rest of fields
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalIncome: double.tryParse(json['total_income']?.toString() ?? '0') ?? 0.0,
      monthlyIncome: double.tryParse(json['monthly_income']?.toString() ?? '0') ?? 0.0,
      weeklyIncome: double.tryParse(json['weekly_income']?.toString() ?? '0') ?? 0.0,
      todayIncome: double.tryParse(json['today_income']?.toString() ?? '0') ?? 0.0,
      revenueBreakdown: json['revenue_breakdown'], // ADD THIS
      // ... rest of parsing
    );
  }
}
```

### Step 2: Add Widget to Dashboard

```dart
// In dashboard.dart or owner_home_screen.dart
import 'package:cargo/USERS-UI/Owner/dashboard/revenue_breakdown_widget.dart';

// Inside your build method, add after RevenueOverview:
ExpandableRevenueBreakdown(
  revenueBreakdown: _stats?.revenueBreakdown,
),
```

### Step 3: Test

Run your app and navigate to the owner dashboard. You should see the revenue breakdown widget appear below the revenue overview.

---

## 🎨 Customization Options

### Change Colors

```dart
RevenueBreakdownWidget(
  revenueBreakdown: data,
  period: 'total',
  // Colors are hardcoded but you can modify the widget:
  // - Blue for gross revenue
  // - Orange for late fees
  // - Red for refunds
  // - Green for net revenue
)
```

### Modify Layout

The widget uses:
- Gradient background (blue to purple)
- Rounded corners (20px border radius)
- Shadow effects
- Icon indicators

All can be customized by editing `revenue_breakdown_widget.dart`

---

## 📱 Responsive Design

The widget automatically adapts to:
- Different screen sizes
- Light/dark mode (uses theme colors where applicable)
- Long currency values (formats with commas)

---

## 🧪 Testing

### Test with Real Data

Your API response already includes the breakdown:
```json
{
  "revenue_breakdown": {
    "total": {
      "gross_revenue": 22755.6,
      "late_fees": 0,
      "refunds_issued": 256.2,
      "net_revenue": 22499.4
    }
  }
}
```

### Test with Mock Data

```dart
// For testing
final mockBreakdown = {
  'total': {
    'gross_revenue': 50000.0,
    'late_fees': 1500.0,
    'refunds_issued': 2000.0,
    'net_revenue': 49500.0,
  },
  'monthly': {
    'gross_revenue': 15000.0,
    'refunds_issued': 500.0,
    'net_revenue': 14500.0,
  },
  'weekly': {
    'gross_revenue': 5000.0,
    'refunds_issued': 100.0,
    'net_revenue': 4900.0,
  },
  'today': {
    'gross_revenue': 1200.0,
    'refunds_issued': 0.0,
    'net_revenue': 1200.0,
  },
};

ExpandableRevenueBreakdown(
  revenueBreakdown: mockBreakdown,
)
```

---

## 🚀 Recommended Implementation

### Option A: Replace Revenue Overview (Bold)

```dart
// Remove the old RevenueOverview widget
// Replace with ExpandableRevenueBreakdown
ExpandableRevenueBreakdown(
  revenueBreakdown: _stats?.revenueBreakdown,
),
```

### Option B: Add Below Revenue Overview (Recommended)

```dart
// Keep existing RevenueOverview for quick glance
RevenueOverview(
  totalIncome: _stats?.totalIncome ?? 0,
  monthlyIncome: _stats?.monthlyIncome ?? 0,
  weeklyIncome: _stats?.weeklyIncome ?? 0,
  todayIncome: _stats?.todayIncome ?? 0,
),

// Add detailed breakdown below
ExpandableRevenueBreakdown(
  revenueBreakdown: _stats?.revenueBreakdown,
),
```

### Option C: Use Compact Summary with Modal

```dart
// Show compact summary
CompactRevenueSummary(
  revenueBreakdown: _stats?.revenueBreakdown,
  onTapDetails: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Breakdown
            Expanded(
              child: SingleChildScrollView(
                child: ExpandableRevenueBreakdown(
                  revenueBreakdown: _stats?.revenueBreakdown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
),
```

---

## 📸 Visual Examples

### Full Breakdown Widget
- Card with gradient background
- Gross revenue in blue with up arrow
- Late fees in orange (if any)
- Refunds in red (if any)
- Net revenue highlighted in green with bold text
- Status chip showing "Active" or "No Activity"

### Expandable Widget
- Tab bar with 4 options: All Time / Month / Week / Today
- Selected tab highlighted in blue
- Smooth transition when switching tabs

### Compact Summary
- Single line card
- Net revenue displayed prominently
- Subtle refund summary below
- Arrow icon indicating it's tappable

---

## 🎯 Summary

**Quickest Implementation:**
1. Import the widget file
2. Add `ExpandableRevenueBreakdown` to your dashboard
3. Pass `stats.revenueBreakdown` from API
4. Done! 🎉

**The widget will automatically:**
- ✅ Show/hide late fees based on value
- ✅ Show/hide refunds based on value
- ✅ Format currency properly
- ✅ Handle null/missing data gracefully
- ✅ Adapt to different screen sizes

---

## 🆘 Troubleshooting

**Widget not showing?**
- Check if `revenueBreakdown` is null
- Verify API response includes `revenue_breakdown` field
- Check if selected period exists in data

**Wrong amounts?**
- Verify API is returning correct data
- Check number parsing (should handle strings and numbers)
- Ensure currency formatting is working

**Layout issues?**
- Widget uses responsive sizing
- Check parent constraints
- Try wrapping in `SingleChildScrollView` if needed

---

**Enjoy your new revenue breakdown widgets! 🎉**
