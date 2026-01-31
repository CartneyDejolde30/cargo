import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Read-only availability calendar for renters
/// Shows which dates are available, blocked, or booked
class RenterAvailabilityCalendar extends StatefulWidget {
  final int vehicleId;
  final String vehicleType;
  final String vehicleName;
  final Function(DateTime?, DateTime?)? onDatesSelected;

  const RenterAvailabilityCalendar({
    super.key,
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleName,
    this.onDatesSelected,
  });

  @override
  State<RenterAvailabilityCalendar> createState() => _RenterAvailabilityCalendarState();
}

class _RenterAvailabilityCalendarState extends State<RenterAvailabilityCalendar> {
  final String baseUrl = "http://10.218.197.49/carGOAdmin/";
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 3, 0); // 3 months ahead
      
      final response = await http.get(
        Uri.parse(
          '${baseUrl}api/availability/get_blocked_dates.php?'
          'vehicle_id=${widget.vehicleId}&'
          'vehicle_type=${widget.vehicleType}&'
          'start_date=${DateFormat('yyyy-MM-dd').format(startDate)}&'
          'end_date=${DateFormat('yyyy-MM-dd').format(endDate)}'
        ),
      );

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
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isDateBlocked(DateTime day) {
    return _blockedDates.any((d) => isSameDay(d, day));
  }

  bool _isDateBooked(DateTime day) {
    return _bookedDates.any((d) => isSameDay(d, day));
  }

  bool _isDateAvailable(DateTime day) {
    // Past dates are not available
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    // Blocked or booked dates are not available
    return !_isDateBlocked(day) && !_isDateBooked(day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Only allow selecting available dates
    if (!_isDateAvailable(selectedDay)) {
      _showMessage('This date is not available', Colors.orange);
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_selectedStart == null || (_selectedStart != null && _selectedEnd != null)) {
        // Start new selection
        _selectedStart = selectedDay;
        _selectedEnd = null;
      } else if (_selectedStart != null && _selectedEnd == null) {
        // Complete range selection
        if (selectedDay.isBefore(_selectedStart!)) {
          _selectedEnd = _selectedStart;
          _selectedStart = selectedDay;
        } else {
          _selectedEnd = selectedDay;
        }

        // Check if any date in range is unavailable
        if (!_isRangeAvailable(_selectedStart!, _selectedEnd!)) {
          _showMessage('Some dates in this range are not available', Colors.red);
          _selectedStart = null;
          _selectedEnd = null;
          return;
        }

        // Notify parent
        if (widget.onDatesSelected != null) {
          widget.onDatesSelected!(_selectedStart, _selectedEnd);
        }
      }
    });
  }

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

  void _showMessage(String message, Color color) {
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
      bottomNavigationBar: _selectedStart != null ? _buildActionBar() : null,
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
            'Check Availability',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Text(
            widget.vehicleName,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.black),
          onPressed: () => _showInfoDialog(),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select your pickup and return dates. Green dates are available for booking.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Legend',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Available', Colors.green[50]!, Colors.green),
              _buildLegendItem('Blocked', Colors.red[50]!, Colors.red),
              _buildLegendItem('Booked', Colors.blue[50]!, Colors.blue),
              _buildLegendItem('Selected', Colors.orange[50]!, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color? borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor ?? Colors.transparent, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          if (_selectedStart != null && _selectedEnd != null) {
            return day.isAfter(_selectedStart!.subtract(const Duration(days: 1))) &&
                   day.isBefore(_selectedEnd!.add(const Duration(days: 1)));
          }
          return isSameDay(day, _selectedStart);
        },
        rangeStartDay: _selectedStart,
        rangeEndDay: _selectedEnd,
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadAvailability();
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          rangeHighlightColor: Colors.orange.withValues(alpha: 0.2),
          rangeStartDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (_isDateBooked(day)) {
              return _buildDayCell(day, Colors.blue[50]!, Colors.blue, false);
            } else if (_isDateBlocked(day)) {
              return _buildDayCell(day, Colors.red[50]!, Colors.red, false);
            } else if (_isDateAvailable(day)) {
              return _buildDayCell(day, Colors.green[50]!, Colors.green, true);
            }
            return null;
          },
          disabledBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, Colors.grey[200]!, Colors.grey[400], false);
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        enabledDayPredicate: (day) {
          return _isDateAvailable(day);
        },
      ),
    );
  }

  Widget _buildDayCell(DateTime day, Color bgColor, Color? borderColor, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? Colors.transparent, width: 2),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.poppins(
            color: isAvailable ? Colors.black87 : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final daysDiff = _selectedEnd != null 
        ? _selectedEnd!.difference(_selectedStart!).inDays + 1
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Dates',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedEnd != null
                          ? '${DateFormat('MMM dd').format(_selectedStart!)} - ${DateFormat('MMM dd').format(_selectedEnd!)}'
                          : DateFormat('MMM dd, yyyy').format(_selectedStart!),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_selectedEnd != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      '$daysDiff ${daysDiff == 1 ? 'day' : 'days'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStart = null;
                        _selectedEnd = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'start': _selectedStart,
                        'end': _selectedEnd ?? _selectedStart,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Continue to Booking',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How to Book', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('1', 'Select your pickup date (tap any green date)'),
            _buildInfoItem('2', 'Select your return date (tap another green date)'),
            _buildInfoItem('3', 'Review your selection and tap "Continue to Booking"'),
            const SizedBox(height: 12),
            Text(
              '💡 Tip: Only green dates are available. Red dates are blocked and blue dates are already booked.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
