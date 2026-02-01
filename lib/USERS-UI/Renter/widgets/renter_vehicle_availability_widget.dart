import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../Owner/mycar/api_constants.dart';

/// Read-only availability calendar for renters
/// Shows available, blocked, and booked dates for a vehicle
class RenterVehicleAvailabilityWidget extends StatefulWidget {
  final int vehicleId;
  final String vehicleType;
  final String vehicleName;
  final Function(DateTime, DateTime)? onDateRangeSelected;

  const RenterVehicleAvailabilityWidget({
    super.key,
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleName,
    this.onDateRangeSelected,
  });

  @override
  State<RenterVehicleAvailabilityWidget> createState() => _RenterVehicleAvailabilityWidgetState();
}

class _RenterVehicleAvailabilityWidgetState extends State<RenterVehicleAvailabilityWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  /// Load availability data from server
  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 6, 0);
      
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}api/availability/get_blocked_dates.php?'
          'vehicle_id=${widget.vehicleId}&'
          'vehicle_type=${widget.vehicleType}&'
          'start_date=${DateFormat('yyyy-MM-dd').format(startDate)}&'
          'end_date=${DateFormat('yyyy-MM-dd').format(endDate)}'
        ),
      ).timeout(ApiConstants.apiTimeout);

      debugPrint('🔵 [Renter] Response status: ${response.statusCode}');
      debugPrint('🔵 [Renter] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _blockedDates = (data['blocked_dates'] as List)
                .map((date) => DateTime.parse(date))
                .toSet();
            _bookedDates = (data['booked_dates'] as List)
                .map((date) => DateTime.parse(date))
                .toSet();
            
            debugPrint('✅ [Renter] Blocked dates: ${_blockedDates.length}');
            debugPrint('✅ [Renter] Booked dates: ${_bookedDates.length}');
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading availability: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Check if a date is available for booking
  bool _isDateAvailable(DateTime day) {
    return !_isDateBlocked(day) && 
           !_isDateBooked(day) && 
           day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool _isDateBlocked(DateTime day) {
    // Compare only date components, ignore time
    return _blockedDates.any((d) => 
      d.year == day.year && 
      d.month == day.month && 
      d.day == day.day
    );
  }

  bool _isDateBooked(DateTime day) {
    // Compare only date components, ignore time
    return _bookedDates.any((d) => 
      d.year == day.year && 
      d.month == day.month && 
      d.day == day.day
    );
  }

  /// Handle date selection (range selection for booking)
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Only allow selecting available dates
    if (!_isDateAvailable(selectedDay)) {
      _showSnackBar('This date is not available', Colors.red);
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_rangeStart == null) {
        // First date selection
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else if (_rangeEnd == null) {
        // Second date selection
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }

        // Check if all dates in range are available
        if (_isRangeAvailable(_rangeStart!, _rangeEnd!)) {
          // Notify parent widget
          if (widget.onDateRangeSelected != null) {
            widget.onDateRangeSelected!(_rangeStart!, _rangeEnd!);
          }
          _showSnackBar(
            '${_rangeStart!.day}/${_rangeStart!.month} - ${_rangeEnd!.day}/${_rangeEnd!.month} selected',
            Colors.green,
          );
        } else {
          _showSnackBar('Some dates in this range are not available', Colors.red);
          _rangeStart = null;
          _rangeEnd = null;
        }
      } else {
        // Reset and start new selection
        _rangeStart = selectedDay;
        _rangeEnd = null;
      }
    });
  }

  /// Check if entire date range is available
  bool _isRangeAvailable(DateTime start, DateTime end) {
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (!_isDateAvailable(current)) {
        return false;
      }
      current = current.add(const Duration(days: 1));
    }
    return true;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildLegend(),
          const Divider(height: 1),
          _isLoading ? _buildLoading() : _buildCalendar(),
          if (_rangeStart != null) _buildSelectedRange(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blue[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Availability Calendar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Select your rental dates',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _loadAvailability,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: _buildLegendItem('Available', Colors.green[50]!, Colors.green[700]!, Icons.check_circle)),
          Flexible(child: _buildLegendItem('Booked', const Color(0xFFBBDEFB), const Color(0xFF1976D2), Icons.event_busy)),
          Flexible(child: _buildLegendItem('Blocked', const Color(0xFFFFCDD2), const Color(0xFFD32F2F), Icons.block)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color borderColor, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Icon(icon, size: 8, color: borderColor),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label, 
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadAvailability();
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        selectedDayPredicate: (day) {
          return isSameDay(day, _rangeStart) || isSameDay(day, _rangeEnd);
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.green[500],
            shape: BoxShape.circle,
          ),
          rangeHighlightColor: Colors.green.withValues(alpha: 0.2),
          rangeStartDecoration: BoxDecoration(
            color: Colors.green[600],
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: Colors.green[600],
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            // Normalize day to midnight for comparison
            final normalizedDay = DateTime(day.year, day.month, day.day);
            
            // Check date status with normalized comparison
            final isBlocked = _blockedDates.any((d) => 
              d.year == normalizedDay.year && 
              d.month == normalizedDay.month && 
              d.day == normalizedDay.day
            );
            
            final isBooked = _bookedDates.any((d) => 
              d.year == normalizedDay.year && 
              d.month == normalizedDay.month && 
              d.day == normalizedDay.day
            );
            
            final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
            
            // Check in priority order: booked, blocked, past dates, then available
            if (isBooked) {
              return _buildCalendarDay(day, const Color(0xFFBBDEFB), const Color(0xFF1976D2), Icons.event_busy); // Blue for booked
            } else if (isBlocked) {
              return _buildCalendarDay(day, const Color(0xFFFFCDD2), const Color(0xFFD32F2F), Icons.block); // RED for blocked
            } else if (isPast) {
              // Past dates - gray (disabled)
              return _buildCalendarDay(day, Colors.grey[100]!, Colors.grey[400]!, Icons.close);
            } else {
              // Available dates - show in GREEN
              return _buildCalendarDay(day, Colors.green[50]!, Colors.green[700]!, Icons.check_circle);
            }
          },
          outsideBuilder: (context, day, focusedDay) {
            return Container(); // Hide outside days
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          formatButtonTextStyle: GoogleFonts.poppins(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, Color bgColor, Color borderColor, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: Icon(icon, size: 10, color: borderColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedRange() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Dates',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[900],
                  ),
                ),
                Text(
                  _rangeEnd == null
                      ? DateFormat('MMM dd, yyyy').format(_rangeStart!)
                      : '${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd, yyyy').format(_rangeEnd!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _rangeStart = null;
                _rangeEnd = null;
              });
            },
            icon: const Icon(Icons.clear, size: 16),
            label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
