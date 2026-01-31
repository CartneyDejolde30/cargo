import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../analytics_models.dart';

class PeakHoursWidget extends StatefulWidget {
  final PeakBookingData peakData;

  const PeakHoursWidget({
    super.key,
    required this.peakData,
  });

  @override
  State<PeakHoursWidget> createState() => _PeakHoursWidgetState();
}

class _PeakHoursWidgetState extends State<PeakHoursWidget> {
  bool _showHourly = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peak Booking Times',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: 20),
          
          _showHourly ? _buildHourlyChart() : _buildDailyChart(),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Hourly', true),
          _buildToggleButton('Daily', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isHourly) {
    final isSelected = _showHourly == isHourly;
    
    return GestureDetector(
      onTap: () => setState(() => _showHourly = isHourly),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyChart() {
    final maxValue = widget.peakData.hourly.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return _buildEmptyState();

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(24, (index) {
          final value = widget.peakData.hourly[index];
          final height = maxValue > 0 ? (value / maxValue) * 120 : 0.0;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value > 0)
                    Container(
                      width: double.infinity,
                      height: height.clamp(4, 120),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (index % 3 == 0)
                    Text(
                      '${index}h',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDailyChart() {
    final maxValue = widget.peakData.daily.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return _buildEmptyState();

    return Column(
      children: widget.peakData.daily.map((day) {
        final percentage = maxValue > 0 ? day.count / maxValue : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  day.day,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                    minHeight: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${day.count}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No booking data yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
