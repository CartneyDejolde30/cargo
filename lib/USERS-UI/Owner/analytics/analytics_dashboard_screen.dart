import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'analytics_service.dart';
import 'analytics_models.dart';
import 'widgets/overview_stats_widget.dart';
import 'widgets/booking_trends_chart.dart';
import 'widgets/revenue_breakdown_chart.dart';
import 'widgets/popular_vehicles_widget.dart';
import 'widgets/peak_hours_widget.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final int ownerId;
  final String ownerName;

  const AnalyticsDashboardScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  bool _isLoading = true;
  AnalyticsOverview? _overview;
  List<BookingTrend> _trends = [];
  RevenueBreakdown? _revenueBreakdown;
  PopularVehicles? _popularVehicles;
  PeakBookingData? _peakHours;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('📊 Loading analytics for owner ID: ${widget.ownerId}');
      
      final data = await _analyticsService.getComprehensiveAnalytics(
        ownerId: widget.ownerId,
      );

      debugPrint('📊 Analytics data received:');
      debugPrint('   - Overview: ${data['overview'] != null ? 'loaded' : 'null'}');
      debugPrint('   - Trends: ${(data['booking_trends'] as List?)?.length ?? 0} items');
      debugPrint('   - Revenue breakdown: ${data['revenue_breakdown'] != null ? 'loaded' : 'null'}');
      debugPrint('   - Popular vehicles: ${data['popular_vehicles'] != null ? 'loaded' : 'null'}');
      debugPrint('   - Peak hours: ${data['peak_hours'] != null ? 'loaded' : 'null'}');

      setState(() {
        _overview = data['overview'];
        _trends = data['booking_trends'] ?? [];
        _revenueBreakdown = data['revenue_breakdown'];
        _popularVehicles = data['popular_vehicles'];
        _peakHours = data['peak_hours'];
        _isLoading = false;
      });

      // Show message if all data is empty
      if (_overview == null && _trends.isEmpty && _revenueBreakdown == null && 
          _popularVehicles == null && _peakHours == null) {
        debugPrint('⚠️ All analytics data is empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No analytics data available yet. Start renting vehicles to see insights!',
                style: GoogleFonts.poppins(),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading analytics: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load analytics. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            widget.ownerName,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: _loadAnalytics,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildContent() {
    // Check if we have any data at all
    final hasData = _overview != null || _trends.isNotEmpty || 
                    _revenueBreakdown != null || _popularVehicles != null || 
                    _peakHours != null;

    if (!hasData) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_overview != null)
              OverviewStatsWidget(overview: _overview!)
            else
              _buildPlaceholder('Overview'),
            
            const SizedBox(height: 24),
            
            if (_trends.isNotEmpty)
              BookingTrendsChart(trends: _trends)
            else
              _buildPlaceholder('Booking Trends'),
            
            const SizedBox(height: 24),
            
            if (_revenueBreakdown != null)
              RevenueBreakdownChart(breakdown: _revenueBreakdown!)
            else
              _buildPlaceholder('Revenue Breakdown'),
            
            const SizedBox(height: 24),
            
            if (_popularVehicles != null)
              PopularVehiclesWidget(vehicles: _popularVehicles!)
            else
              _buildPlaceholder('Popular Vehicles'),
            
            const SizedBox(height: 24),
            
            if (_peakHours != null)
              PeakHoursWidget(peakData: _peakHours!)
            else
              _buildPlaceholder('Peak Hours'),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Analytics Data Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start renting your vehicles to see analytics and insights here.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String title) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No $title Data',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
