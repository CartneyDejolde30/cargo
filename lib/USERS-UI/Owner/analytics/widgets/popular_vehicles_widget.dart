import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../analytics_models.dart';

class PopularVehiclesWidget extends StatefulWidget {
  final PopularVehicles vehicles;

  const PopularVehiclesWidget({
    super.key,
    required this.vehicles,
  });

  @override
  State<PopularVehiclesWidget> createState() => _PopularVehiclesWidgetState();
}

class _PopularVehiclesWidgetState extends State<PopularVehiclesWidget> {
  bool _showCars = true;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _showCars ? widget.vehicles.cars : widget.vehicles.motorcycles;

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
                'Popular Vehicles',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildToggle(),
            ],
          ),
          const SizedBox(height: 16),
          
          if (vehicles.isEmpty)
            _buildEmptyState()
          else
            ...vehicles.take(5).map((vehicle) => _buildVehicleCard(vehicle)),
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
          _buildToggleButton('Cars', true),
          _buildToggleButton('Bikes', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isCar) {
    final isSelected = _showCars == isCar;
    
    return GestureDetector(
      onTap: () => setState(() => _showCars = isCar),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(VehicleStats vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#${widget.vehicles.cars.indexOf(vehicle) + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicle.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 11, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text(
                              '${vehicle.bookings} bookings',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 11, color: Colors.amber[600]),
                            const SizedBox(width: 3),
                            Text(
                              vehicle.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatCurrency(vehicle.revenue),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
                Text(
                  'revenue',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
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
          children: [
            Icon(
              _showCars ? Icons.directions_car : Icons.two_wheeler,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No ${_showCars ? 'cars' : 'motorcycles'} yet',
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
