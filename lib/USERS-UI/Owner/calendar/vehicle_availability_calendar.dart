import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class VehicleAvailabilityCalendar extends StatefulWidget {
  final int ownerId;
  final int vehicleId;
  final String vehicleType;
  final String vehicleName;

  const VehicleAvailabilityCalendar({
    super.key,
    required this.ownerId,
    required this.vehicleId,
    required this.vehicleType,
    required this.vehicleName,
  });

  @override
  State<VehicleAvailabilityCalendar> createState() => _VehicleAvailabilityCalendarState();
}

class _VehicleAvailabilityCalendarState extends State<VehicleAvailabilityCalendar> {
  final String baseUrl = "http://10.218.197.49/carGOAdmin/";
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _blockedDates = {};
  Set<DateTime> _bookedDates = {};
  Set<DateTime> _selectedDates = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedDates();
  }

  Future<void> _loadBlockedDates() async {
    setState(() => _isLoading = true);
    
    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 6, 0);
      
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
      print('Error loading blocked dates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _blockDates() async {
    if (_selectedDates.isEmpty) {
      _showMessage('Please select dates to block', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/availability/block_dates.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': widget.ownerId,
          'vehicle_id': widget.vehicleId,
          'vehicle_type': widget.vehicleType,
          'dates': _selectedDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
          'reason': 'Blocked by owner',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showMessage(data['message']);
          setState(() {
            _blockedDates.addAll(_selectedDates);
            _selectedDates.clear();
            _isSelectionMode = false;
          });
          await _loadBlockedDates();
        } else {
          _showMessage(data['message'], isError: true);
        }
      }
    } catch (e) {
      _showMessage('Error blocking dates: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockDates() async {
    if (_selectedDates.isEmpty) {
      _showMessage('Please select dates to unblock', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${baseUrl}api/availability/unblock_dates.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': widget.ownerId,
          'vehicle_id': widget.vehicleId,
          'vehicle_type': widget.vehicleType,
          'dates': _selectedDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showMessage(data['message']);
          setState(() {
            _blockedDates.removeAll(_selectedDates);
            _selectedDates.clear();
            _isSelectionMode = false;
          });
          await _loadBlockedDates();
        } else {
          _showMessage(data['message'], isError: true);
        }
      }
    } catch (e) {
      _showMessage('Error unblocking dates: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isDateBlocked(DateTime day) {
    return _blockedDates.any((d) => isSameDay(d, day));
  }

  bool _isDateBooked(DateTime day) {
    return _bookedDates.any((d) => isSameDay(d, day));
  }

  bool _isDateSelected(DateTime day) {
    return _selectedDates.any((d) => isSameDay(d, day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              widget.vehicleName,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDates.clear();
                  _isSelectionMode = false;
                });
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLegendItem('Available', Colors.white, Colors.grey[300]!),
                          _buildLegendItem('Blocked', Colors.red[50]!, Colors.red),
                          _buildLegendItem('Booked', Colors.blue[50]!, Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),

                // Calendar
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => _isDateSelected(day),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      onDaySelected: (selectedDay, focusedDay) {
                        if (selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                          return;
                        }
                        
                        setState(() {
                          _focusedDay = focusedDay;
                          _isSelectionMode = true;
                          
                          if (_selectedDates.any((d) => isSameDay(d, selectedDay))) {
                            _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                          } else {
                            _selectedDates.add(selectedDay);
                          }
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _loadBlockedDates();
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
                        outsideDaysVisible: false,
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_isDateBooked(day)) {
                            return _buildCalendarDay(day, Colors.blue[50]!, Colors.blue);
                          } else if (_isDateBlocked(day)) {
                            return _buildCalendarDay(day, Colors.red[50]!, Colors.red);
                          }
                          return null;
                        },
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // Action Buttons
                if (_isSelectionMode && _selectedDates.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _blockDates,
                            icon: const Icon(Icons.block),
                            label: Text('Block ${_selectedDates.length} Date(s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _unblockDates,
                            icon: const Icon(Icons.check_circle),
                            label: Text('Unblock ${_selectedDates.length} Date(s)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color? borderColor) {
    return Row(
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

  Widget _buildCalendarDay(DateTime day, Color bgColor, Color? borderColor) {
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
}
