class OverdueBooking {
  final int bookingId;
  final int userId;
  final int ownerId;
  final String vehicleName;
  final String vehicleImage;
  final String renterName;
  final String renterContact;
  final String ownerName;
  final String ownerContact;
  final DateTime returnDate;
  final String returnTime;
  final int daysOverdue;
  final int hoursOverdue;
  final double lateFeeAmount;
  final double totalAmount;
  final double totalDue;
  final String overdueStatus; // 'overdue' or 'severely_overdue'
  final bool lateFeeCharged;
  final bool isRentalPaid; // NEW: Check if rental payment is verified

  OverdueBooking({
    required this.bookingId,
    required this.userId,
    required this.ownerId,
    required this.vehicleName,
    required this.vehicleImage,
    required this.renterName,
    required this.renterContact,
    required this.ownerName,
    required this.ownerContact,
    required this.returnDate,
    required this.returnTime,
    required this.daysOverdue,
    required this.hoursOverdue,
    required this.lateFeeAmount,
    required this.totalAmount,
    required this.totalDue,
    required this.overdueStatus,
    required this.lateFeeCharged,
    this.isRentalPaid = false, // Default to false
  });

  bool get isSeverlyOverdue => overdueStatus == 'severely_overdue';
  bool get hasLateFee => lateFeeAmount > 0;

  factory OverdueBooking.fromJson(Map<String, dynamic> json) {
    return OverdueBooking(
      bookingId: int.tryParse(json['booking_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      ownerId: int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0,
      vehicleName: json['vehicle_name']?.toString() ?? 'Unknown Vehicle',
      vehicleImage: json['vehicle_image']?.toString() ?? '',
      renterName: json['renter_name']?.toString() ?? 'Unknown',
      renterContact: json['renter_contact']?.toString() ?? '',
      ownerName: json['owner_name']?.toString() ?? 'Unknown',
      ownerContact: json['owner_contact']?.toString() ?? '',
      returnDate: DateTime.tryParse(json['return_date']?.toString() ?? '') ?? DateTime.now(),
      returnTime: json['return_time']?.toString() ?? '00:00:00',
      daysOverdue: int.tryParse(json['overdue_days']?.toString() ?? '0') ?? 0,
      hoursOverdue: int.tryParse(json['hours_overdue']?.toString() ?? '0') ?? 0,
      lateFeeAmount: double.tryParse(json['late_fee_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      totalDue: double.tryParse(json['total_due']?.toString() ?? '0') ?? 0.0,
      overdueStatus: json['overdue_status']?.toString() ?? 'on_time',
      lateFeeCharged: json['late_fee_charged'] == true || json['late_fee_charged'] == 1,
      isRentalPaid: json['payment_status']?.toString() == 'paid' || 
                    json['payment_status']?.toString() == 'verified',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'owner_id': ownerId,
      'vehicle_name': vehicleName,
      'vehicle_image': vehicleImage,
      'renter_name': renterName,
      'renter_contact': renterContact,
      'owner_name': ownerName,
      'owner_contact': ownerContact,
      'return_date': returnDate.toIso8601String(),
      'return_time': returnTime,
      'overdue_days': daysOverdue,
      'hours_overdue': hoursOverdue,
      'late_fee_amount': lateFeeAmount,
      'total_amount': totalAmount,
      'total_due': totalDue,
      'overdue_status': overdueStatus,
      'late_fee_charged': lateFeeCharged,
    };
  }
}

class ExtensionRequest {
  final int? id;
  final int bookingId;
  final int requestedBy;
  final DateTime originalReturnDate;
  final DateTime requestedReturnDate;
  final int extensionDays;
  final double extensionFee;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final int? approvedBy;
  final String? approvalReason;
  final DateTime? createdAt;

  ExtensionRequest({
    this.id,
    required this.bookingId,
    required this.requestedBy,
    required this.originalReturnDate,
    required this.requestedReturnDate,
    required this.extensionDays,
    required this.extensionFee,
    required this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.approvalReason,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory ExtensionRequest.fromJson(Map<String, dynamic> json) {
    return ExtensionRequest(
      id: int.tryParse(json['id']?.toString() ?? '0'),
      bookingId: int.tryParse(json['booking_id']?.toString() ?? '0') ?? 0,
      requestedBy: int.tryParse(json['requested_by']?.toString() ?? '0') ?? 0,
      originalReturnDate: DateTime.tryParse(json['original_return_date']?.toString() ?? '') ?? DateTime.now(),
      requestedReturnDate: DateTime.tryParse(json['requested_return_date']?.toString() ?? '') ?? DateTime.now(),
      extensionDays: int.tryParse(json['extension_days']?.toString() ?? '0') ?? 0,
      extensionFee: double.tryParse(json['extension_fee']?.toString() ?? '0') ?? 0.0,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      approvedBy: int.tryParse(json['approved_by']?.toString() ?? '0'),
      approvalReason: json['approval_reason']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'booking_id': bookingId,
      'requested_by': requestedBy,
      'original_return_date': originalReturnDate.toIso8601String().split('T')[0],
      'requested_return_date': requestedReturnDate.toIso8601String().split('T')[0],
      'extension_days': extensionDays,
      'extension_fee': extensionFee,
      'reason': reason,
      'status': status,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (approvalReason != null) 'approval_reason': approvalReason,
    };
  }
}
