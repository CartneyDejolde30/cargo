import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './status_helper.dart';
import './api_constants.dart';
import './delete_car_dialog.dart';
import './car_services.dart';
import '../calendar/enhanced_vehicle_calendar.dart';

class CarDetailPage extends StatefulWidget {
  final Map<String, dynamic> car;
  final VoidCallback? onDelete;
  final int? ownerId;

  const CarDetailPage({
    super.key,
    required this.car,
    this.onDelete,
    this.ownerId,
  });

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late Map<String, dynamic> car;

  @override
  void initState() {
    super.initState();
    car = Map<String, dynamic>.from(widget.car);
  }

  String get status => (car['status'] ?? 'Unknown').toString().toLowerCase();
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isRented => status == 'rented';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusBanner(context),
                _buildCarInfo(context),
                _buildSpecifications(context),
                _buildPricing(context),
                if (isRented) _buildRentalInfo(context),
                if (isRejected) _buildRejectionReason(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final imageUrl = ApiConstants.getCarImageUrl(car['image']);

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
       backgroundColor: Theme.of(context).iconTheme.color,




      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.directions_car,
                  size: 80,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StatusHelper.getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: StatusHelper.getStatusColor(status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            StatusHelper.getStatusIcon(status),
            color: StatusHelper.getStatusColor(status),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: StatusHelper.getStatusColor(status),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusMessage(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage() {
    if (isPending) return "Your car is under review by admin";
    if (isApproved) return "Your car is live and available for rent";
    if (isRejected) return "Your car listing was not approved";
    if (isRented) return "This car is currently being rented";
    return "Status unknown";
  }

  Widget _buildCarInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text(
            "${car['brand']} ${car['model']}",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            car['year']?.toString() ?? 'N/A',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Text(
            "Specifications",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow(
            Icons.local_gas_station_outlined,
            "Fuel Type",
            car['fuel_type']?.toString() ?? 'N/A',
          ),
          _buildSpecRow(
            Icons.settings_outlined,
            "Transmission",
            car['transmission']?.toString() ?? 'N/A',
          ),
          _buildSpecRow(
            Icons.event_seat_outlined,
            "Seats",
            car['seating_capacity']?.toString() ?? 'N/A',
          ),
          _buildSpecRow(
            Icons.palette_outlined,
            "Color",
            car['color']?.toString() ?? 'N/A',
          ),
          _buildSpecRow(
            Icons.confirmation_number_outlined,
            "Plate Number",
            car['plate_number']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricing(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rental Price",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "₱${car['price_per_day']}/day",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (!isRented)
            IconButton(
              onPressed: () => _showEditPriceDialog(context),
              icon: const Icon(Icons.edit, color: Colors.white70),
              tooltip: 'Edit Price',
            )
          else
            Icon(
              Icons.payments_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteVehicle(BuildContext context) async {
    final ownerIdFromCar = int.tryParse(car['owner_id']?.toString() ?? '0') ?? 0;
    final finalOwnerId = ownerIdFromCar > 0 ? ownerIdFromCar : (widget.ownerId ?? 0);
    final vehicleId = int.tryParse(car['id']?.toString() ?? '0') ?? 0;
    final vehicleType = car['vehicle_type']?.toString() ?? 'car';

    final confirm = await DeleteCarDialog.show(context);
    if (confirm != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Deleting vehicle...', style: GoogleFonts.poppins(fontSize: 14)),
          ],
        ),
        duration: const Duration(seconds: 30),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final result = await CarService().deleteVehicle(vehicleId, vehicleType, finalOwnerId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result['success'] == true) {
      widget.onDelete?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Vehicle deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to delete vehicle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditPriceDialog(BuildContext context) async {
    final ownerIdFromCar = int.tryParse(car['owner_id']?.toString() ?? '0') ?? 0;
    final finalOwnerId = ownerIdFromCar > 0 ? ownerIdFromCar : (widget.ownerId ?? 0);
    final vehicleId = int.tryParse(car['id']?.toString() ?? '0') ?? 0;
    final vehicleType = car['vehicle_type']?.toString() ?? 'car';

    final currentPrice = double.tryParse(car['price_per_day']?.toString() ?? '0') ?? 0;
    final controller = TextEditingController(text: currentPrice.toStringAsFixed(0));

    final suggestions = [500, 800, 1000, 1200, 1500, 2000, 2500, 3000];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Rental Price',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set new price per day',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                autofocus: true,
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  suffixText: '/day',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Text(
                'Suggested prices',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: suggestions.map((price) {
                  final isSelected = controller.text == price.toString();
                  return GestureDetector(
                    onTap: () {
                      controller.text = price.toString();
                      setStateDialog(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '₱$price',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final newPrice = double.tryParse(controller.text);
    if (newPrice == null || newPrice <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final result = await CarService().updatePrice(vehicleId, vehicleType, finalOwnerId, newPrice);

    if (!context.mounted) return;

    if (result['success'] == true) {
      setState(() => car['price_per_day'] = newPrice);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Price updated to ₱${newPrice.toStringAsFixed(2)}/day'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Update failed'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildRentalInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                "Current Rental",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "This car is currently being rented. You cannot edit or delete it until the rental period ends.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReason(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                "Rejection Reason",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            car['rejection_reason']?.toString() ?? 
            "Your car listing did not meet the requirements. Please review and resubmit with correct information.",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Get owner_id from car data - ensure it's an integer
    // Use fallback ownerId parameter if car data doesn't have owner_id
    final ownerIdFromCar = int.tryParse(car['owner_id']?.toString() ?? '0') ?? 0;
    final finalOwnerId = ownerIdFromCar > 0 ? ownerIdFromCar : (widget.ownerId ?? 0);
    final vehicleId = int.tryParse(car['id']?.toString() ?? '0') ?? 0;
    final vehicleType = car['vehicle_type']?.toString() ?? 'car';
    final vehicleName = "${car['brand']} ${car['model']}";
    
    // Debug logging
    debugPrint('🔍 CarDetailPage - Full car data: $car');
    debugPrint('🔍 CarDetailPage - ownerIdFromCar: $ownerIdFromCar, fallback: ${widget.ownerId}, final: $finalOwnerId');
    debugPrint('🔍 CarDetailPage - vehicleId: $vehicleId, vehicleType: $vehicleType');
    debugPrint('🔍 CarDetailPage - car[owner_id]: ${car['owner_id']}, car[id]: ${car['id']}');
    
    // Safety check
    if (finalOwnerId == 0 || vehicleId == 0) {
      debugPrint('❌ Invalid owner_id or vehicle_id - car data might be corrupted');
      debugPrint('❌ Please ensure owner_id is passed to CarDetailPage or exists in car data');
    }

    // Rented cars can't be edited or deleted, but can manage availability
    if (isRented) {
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
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnhancedVehicleCalendar(
                    ownerId: finalOwnerId,
                    vehicleId: vehicleId,
                    vehicleType: vehicleType,
                    vehicleName: vehicleName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: Text(
              "View Availability",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    // For approved cars, show manage availability and delete buttons
    if (isApproved) {
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
              // Manage Availability Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EnhancedVehicleCalendar(
                          ownerId: finalOwnerId,
                          vehicleId: vehicleId,
                          vehicleType: vehicleType,
                          vehicleName: vehicleName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    "Manage Availability",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Delete Button (Full Width)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteVehicle(context),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    "Delete Vehicle",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300, width: 2),
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
      );
    }

    // For pending/rejected, show delete button only
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
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _deleteVehicle(context),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              "Delete Vehicle",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.shade300, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}