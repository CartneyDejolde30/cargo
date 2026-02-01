import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'enhanced_calendar_service.dart';

/// Enhanced Vehicle Availability Calendar with advanced features
class EnhancedVehicleCalendar extends StatefulWidget {
  final int ownerId;
  final int vehicleId;
  final String vehicleType;
  final String vehicleName;

  const EnhancedVehicleCalendar({
    super.key,
    required this.ownerId,
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleName,
  });

  @override
  State<EnhancedVehicleCalendar> createState() => _EnhancedVehicleCalendarState();
}

class _EnhancedVehicleCalendarState extends State<EnhancedVehicleCalendar> {
  final EnhancedCalendarService _service = EnhancedCalendarService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  Set<DateTime> _selectedDates = {};
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = true;
  bool _isRangeMode = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 6, 0);
      
      // Load blocked and booked dates
      final result = await _service.getBlockedDates(
        vehicleId: widget.vehicleId,
        vehicleType: widget.vehicleType,
        startDate: startDate,
        endDate: endDate,
      );

      // Load statistics
      final stats = await _service.getAvailabilityStats(
        vehicleId: widget.vehicleId,
        vehicleType: widget.vehicleType,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        if (result['success']) {
          _blockedDates = result['blocked_dates'] as Set<DateTime>;
          _bookedDates = result['booked_dates'] as Set<DateTime>;
          
          debugPrint('📅 Loaded blocked dates: ${_blockedDates.length}');
          debugPrint('📅 Blocked dates: ${_blockedDates.map((d) => d.toString()).join(", ")}');
          debugPrint('📅 Loaded booked dates: ${_bookedDates.length}');
        }
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _blockDates() async {
    if (_selectedDates.isEmpty) {
      _showSnackBar('Please select dates to block', Colors.red);
      return;
    }

    final reason = await _showReasonDialog();
    if (reason == null) return;

    setState(() => _isLoading = true);

    final result = await _service.blockDates(
      ownerId: widget.ownerId,
      vehicleId: widget.vehicleId,
      vehicleType: widget.vehicleType,
      dates: _selectedDates.toList(),
      reason: reason,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackBar(result['message'], Colors.green);
      setState(() {
        _blockedDates.addAll(_selectedDates);
        _selectedDates.clear();
        _rangeStart = null;
        _rangeEnd = null;
      });
      _loadData();
    } else {
      _showSnackBar(result['message'], Colors.red);
    }
  }

  Future<void> _unblockDates() async {
    if (_selectedDates.isEmpty) {
      _showSnackBar('Please select dates to unblock', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _service.unblockDates(
      ownerId: widget.ownerId,
      vehicleId: widget.vehicleId,
      vehicleType: widget.vehicleType,
      dates: _selectedDates.toList(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnackBar(result['message'], Colors.green);
      setState(() {
        _blockedDates.removeAll(_selectedDates);
        _selectedDates.clear();
        _rangeStart = null;
        _rangeEnd = null;
      });
      _loadData();
    } else {
      _showSnackBar(result['message'], Colors.red);
    }
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController(text: 'Blocked by owner');
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block Reason', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for blocking',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Confirm', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_isRangeMode) {
        // Range selection mode
        if (_rangeStart == null) {
          _rangeStart = selectedDay;
          _rangeEnd = null;
          _selectedDates = {selectedDay};
        } else if (_rangeEnd == null) {
          if (selectedDay.isBefore(_rangeStart!)) {
            _rangeEnd = _rangeStart;
            _rangeStart = selectedDay;
          } else {
            _rangeEnd = selectedDay;
          }
          
          // Fill dates between range
          _selectedDates.clear();
          DateTime current = _rangeStart!;
          while (current.isBefore(_rangeEnd!) || current.isAtSameMomentAs(_rangeEnd!)) {
            _selectedDates.add(current);
            current = current.add(const Duration(days: 1));
          }
        } else {
          // Reset range
          _rangeStart = selectedDay;
          _rangeEnd = null;
          _selectedDates = {selectedDay};
        }
      } else {
        // Single/multiple selection mode
        if (_selectedDates.contains(selectedDay)) {
          _selectedDates.remove(selectedDay);
        } else {
          _selectedDates.add(selectedDay);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildContent(),
      bottomNavigationBar: _selectedDates.isNotEmpty ? _buildActionBar() : null,
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
            'Availability Calendar',
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
          icon: Icon(
            _isRangeMode ? Icons.date_range : Icons.calendar_today,
            color: _isRangeMode ? Colors.blue : Colors.black,
          ),
          onPressed: () {
            setState(() {
              _isRangeMode = !_isRangeMode;
              _selectedDates.clear();
              _rangeStart = null;
              _rangeEnd = null;
            });
          },
          tooltip: _isRangeMode ? 'Range Mode' : 'Single Mode',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: _loadData,
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
          _buildStats(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildCalendar(),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics (Next 6 Months)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Available',
                  _stats['available_days']?.toString() ?? '0',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Blocked',
                  _stats['blocked_days']?.toString() ?? '0',
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Booked',
                  _stats['booked_days']?.toString() ?? '0',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Utilization',
                  '${_stats['utilization_rate'] ?? '0'}%',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _buildLegendItem('Available', Colors.green[50]!, Colors.green[700]!)),
              Flexible(child: _buildLegendItem('Blocked', const Color(0xFFFFCDD2), const Color(0xFFD32F2F))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _buildLegendItem('Booked', const Color(0xFFBBDEFB), const Color(0xFF1976D2))),
              Flexible(child: _buildLegendItem('Selected', const Color(0xFFFFE0B2), const Color(0xFFE65100))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color borderColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label, 
            style: GoogleFonts.poppins(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
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
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => _selectedDates.contains(day),
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadData();
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
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            // Normalize day to midnight for comparison
            final normalizedDay = DateTime(day.year, day.month, day.day);
            
            // Check if this day is in blocked or booked dates
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
            
            // Check if date is in the past
            final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
            
            if (isBooked) {
              return _buildDayCell(day, const Color(0xFFBBDEFB), const Color(0xFF1976D2)); // Blue for booked
            } else if (isBlocked) {
              return _buildDayCell(day, const Color(0xFFFFCDD2), const Color(0xFFD32F2F)); // Red for blocked
            } else if (isPast) {
              return _buildDayCell(day, Colors.grey[200]!, Colors.grey[400]); // Gray for past dates
            } else {
              // Available dates - show in GREEN
              return _buildDayCell(day, Colors.green[50]!, Colors.green[700]!); // Green for available
            }
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
      ),
    );
  }

  Widget _buildDayCell(DateTime day, Color bgColor, Color? borderColor) {
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
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedDates.length} date(s) selected',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _blockDates,
                  icon: const Icon(Icons.block),
                  label: const Text('Block'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _unblockDates,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Unblock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
