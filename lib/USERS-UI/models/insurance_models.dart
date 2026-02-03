// Insurance Models for Flutter

class InsuranceCoverage {
  final int id;
  final String name;
  final String code;
  final String description;
  final double premiumRate;
  final double minCoverage;
  final double maxCoverage;
  final bool isMandatory;
  final CoverageFeatures features;

  InsuranceCoverage({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.premiumRate,
    required this.minCoverage,
    required this.maxCoverage,
    required this.isMandatory,
    required this.features,
  });

  factory InsuranceCoverage.fromJson(Map<String, dynamic> json) {
    return InsuranceCoverage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      premiumRate: double.tryParse(json['premium_rate'].toString()) ?? 0.0,
      minCoverage: double.tryParse(json['min_coverage'].toString()) ?? 0.0,
      maxCoverage: double.tryParse(json['max_coverage'].toString()) ?? 0.0,
      isMandatory: json['is_mandatory'] == true || json['is_mandatory'] == 1 || json['is_mandatory'] == '1',
      features: CoverageFeatures.fromJson(json['features'] ?? {}),
    );
  }
}

class CoverageFeatures {
  final double collisionDamage;
  final double thirdPartyLiability;
  final double theftProtection;
  final double personalInjury;
  final bool roadsideAssistance;
  final double deductible;

  CoverageFeatures({
    required this.collisionDamage,
    required this.thirdPartyLiability,
    required this.theftProtection,
    required this.personalInjury,
    required this.roadsideAssistance,
    required this.deductible,
  });

  factory CoverageFeatures.fromJson(Map<String, dynamic> json) {
    return CoverageFeatures(
      collisionDamage: double.tryParse(json['collision_damage']?.toString() ?? '0') ?? 0.0,
      thirdPartyLiability: double.tryParse(json['third_party_liability']?.toString() ?? '0') ?? 0.0,
      theftProtection: double.tryParse(json['theft_protection']?.toString() ?? '0') ?? 0.0,
      personalInjury: double.tryParse(json['personal_injury']?.toString() ?? '0') ?? 0.0,
      roadsideAssistance: json['roadside_assistance'] == true || json['roadside_assistance'] == 1 || json['roadside_assistance'] == '1',
      deductible: double.tryParse(json['deductible']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class InsurancePolicy {
  final int policyId;
  final String policyNumber;
  final int bookingId;
  final InsuranceProvider provider;
  final PolicyCoverage coverage;
  final double premiumAmount;
  final DateTime policyStart;
  final DateTime policyEnd;
  final String status;
  final bool isExpired;
  final int daysRemaining;
  final Renter renter;
  final String vehicleType;
  final bool termsAccepted;
  final DateTime issuedAt;

  InsurancePolicy({
    required this.policyId,
    required this.policyNumber,
    required this.bookingId,
    required this.provider,
    required this.coverage,
    required this.premiumAmount,
    required this.policyStart,
    required this.policyEnd,
    required this.status,
    required this.isExpired,
    required this.daysRemaining,
    required this.renter,
    required this.vehicleType,
    required this.termsAccepted,
    required this.issuedAt,
  });

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      policyId: int.tryParse(json['policy_id']?.toString() ?? '0') ?? 0,
      policyNumber: json['policy_number'] ?? '',
      bookingId: int.tryParse(json['booking_id']?.toString() ?? '0') ?? 0,
      provider: InsuranceProvider.fromJson(json['provider'] ?? {}),
      coverage: PolicyCoverage.fromJson(json['coverage'] ?? {}),
      premiumAmount: double.tryParse(json['premium_amount']?.toString() ?? '0') ?? 0.0,
      policyStart: DateTime.parse(json['policy_start']),
      policyEnd: DateTime.parse(json['policy_end']),
      status: json['status'] ?? '',
      isExpired: json['is_expired'] == true || json['is_expired'] == 1 || json['is_expired'] == '1',
      daysRemaining: int.tryParse(json['days_remaining']?.toString() ?? '0') ?? 0,
      renter: Renter.fromJson(json['renter'] ?? {}),
      vehicleType: json['vehicle_type'] ?? '',
      termsAccepted: json['terms_accepted'] == true || json['terms_accepted'] == 1 || json['terms_accepted'] == '1',
      issuedAt: DateTime.parse(json['issued_at']),
    );
  }
}

class InsuranceProvider {
  final String name;
  final String email;
  final String phone;

  InsuranceProvider({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory InsuranceProvider.fromJson(Map<String, dynamic> json) {
    return InsuranceProvider(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class PolicyCoverage {
  final String type;
  final double limit;
  final double deductible;
  final double collision;
  final double liability;
  final double theft;
  final double personalInjury;
  final bool roadsideAssistance;

  PolicyCoverage({
    required this.type,
    required this.limit,
    required this.deductible,
    required this.collision,
    required this.liability,
    required this.theft,
    required this.personalInjury,
    required this.roadsideAssistance,
  });

  factory PolicyCoverage.fromJson(Map<String, dynamic> json) {
    return PolicyCoverage(
      type: json['type'] ?? '',
      limit: double.tryParse(json['limit'].toString()) ?? 0.0,
      deductible: double.tryParse(json['deductible'].toString()) ?? 0.0,
      collision: double.tryParse(json['collision'].toString()) ?? 0.0,
      liability: double.tryParse(json['liability'].toString()) ?? 0.0,
      theft: double.tryParse(json['theft'].toString()) ?? 0.0,
      personalInjury: double.tryParse(json['personal_injury'].toString()) ?? 0.0,
      roadsideAssistance: json['roadside_assistance'] ?? false,
    );
  }
}

class Renter {
  final String name;
  final String email;
  final String contact;

  Renter({
    required this.name,
    required this.email,
    required this.contact,
  });

  factory Renter.fromJson(Map<String, dynamic> json) {
    return Renter(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? '',
    );
  }
}

class InsuranceClaim {
  final int claimId;
  final String claimNumber;
  final String policyNumber;
  final String claimType;
  final DateTime incidentDate;
  final String incidentLocation;
  final String incidentDescription;
  final double claimedAmount;
  final double approvedAmount;
  final double payoutAmount;
  final String status;
  final String priority;
  final String? policeReportNumber;
  final List<String> evidencePhotos;
  final String? reviewNotes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  InsuranceClaim({
    required this.claimId,
    required this.claimNumber,
    required this.policyNumber,
    required this.claimType,
    required this.incidentDate,
    required this.incidentLocation,
    required this.incidentDescription,
    required this.claimedAmount,
    required this.approvedAmount,
    required this.payoutAmount,
    required this.status,
    required this.priority,
    this.policeReportNumber,
    required this.evidencePhotos,
    this.reviewNotes,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
  });

  factory InsuranceClaim.fromJson(Map<String, dynamic> json) {
    return InsuranceClaim(
      claimId: json['claim_id'] ?? 0,
      claimNumber: json['claim_number'] ?? '',
      policyNumber: json['policy_number'] ?? '',
      claimType: json['claim_type'] ?? '',
      incidentDate: DateTime.parse(json['incident_date']),
      incidentLocation: json['incident_location'] ?? '',
      incidentDescription: json['incident_description'] ?? '',
      claimedAmount: double.tryParse(json['claimed_amount'].toString()) ?? 0.0,
      approvedAmount: double.tryParse(json['approved_amount'].toString()) ?? 0.0,
      payoutAmount: double.tryParse(json['payout_amount'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      policeReportNumber: json['police_report_number'],
      evidencePhotos: List<String>.from(json['evidence_photos'] ?? []),
      reviewNotes: json['review_notes'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
    );
  }
}
