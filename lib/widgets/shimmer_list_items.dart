import 'package:flutter/material.dart';
import 'loading_widgets.dart';

/// Shimmer loading widgets for different list types
/// Provides skeleton screens for better loading UX

// ============================================================================
// VEHICLE CARD SHIMMER (for car/motorcycle lists)
// ============================================================================

class VehicleCardShimmer extends StatelessWidget {
  const VehicleCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const ShimmerLoading(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const ShimmerLoading(width: 180, height: 20),
                const SizedBox(height: 8),
                // Subtitle
                const ShimmerLoading(width: 120, height: 16),
                const SizedBox(height: 12),
                // Price and rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerLoading(width: 100, height: 18),
                    const ShimmerLoading(width: 60, height: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// VEHICLE GRID SHIMMER (for grid views)
// ============================================================================

class VehicleGridShimmer extends StatelessWidget {
  const VehicleGridShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          const ShimmerLoading(
            width: double.infinity,
            height: 140,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(width: 100, height: 16),
                SizedBox(height: 6),
                ShimmerLoading(width: 80, height: 14),
                SizedBox(height: 8),
                ShimmerLoading(width: 60, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOOKING CARD SHIMMER
// ============================================================================

class BookingCardShimmer extends StatelessWidget {
  const BookingCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vehicle image
          const ShimmerLoading(
            width: 100,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(width: 150, height: 18),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 100, height: 14),
                const SizedBox(height: 8),
                const ShimmerLoading(width: 120, height: 14),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const ShimmerLoading(width: 80, height: 24),
                    const SizedBox(width: 8),
                    const ShimmerLoading(width: 80, height: 24),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REVIEW CARD SHIMMER
// ============================================================================

class ReviewCardShimmer extends StatelessWidget {
  const ReviewCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              const ShimmerLoading(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 120, height: 16),
                    const SizedBox(height: 4),
                    const ShimmerLoading(width: 80, height: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerLoading(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          const ShimmerLoading(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          const ShimmerLoading(width: 200, height: 14),
        ],
      ),
    );
  }
}

// ============================================================================
// SHIMMER LIST BUILDERS
// ============================================================================

/// Pre-built shimmer list for vehicle cards
class VehicleListShimmer extends StatelessWidget {
  final int itemCount;
  
  const VehicleListShimmer({Key? key, this.itemCount = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const VehicleCardShimmer(),
    );
  }
}

/// Pre-built shimmer grid for vehicle cards
class VehicleGridShimmerList extends StatelessWidget {
  final int itemCount;
  
  const VehicleGridShimmerList({Key? key, this.itemCount = 6}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const VehicleGridShimmer(),
    );
  }
}

/// Pre-built shimmer list for booking cards
class BookingListShimmer extends StatelessWidget {
  final int itemCount;
  
  const BookingListShimmer({Key? key, this.itemCount = 4}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const BookingCardShimmer(),
    );
  }
}

/// Pre-built shimmer list for reviews
class ReviewListShimmer extends StatelessWidget {
  final int itemCount;
  
  const ReviewListShimmer({Key? key, this.itemCount = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ReviewCardShimmer(),
    );
  }
}
