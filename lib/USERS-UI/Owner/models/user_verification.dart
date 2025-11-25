class UserVerification {
  // --- User Reference ---
  int? userId;
  String verificationStatus; // pending, approved, rejected

  // --- Personal Information ---
  String? firstName;
  String? middleName;
  String? lastName;
  String? suffix;
  String? nationality;
  String? gender;
  DateTime? dateOfBirth;

  // --- Permanent Address ---
  String? permRegion;
  String? permProvince;
  String? permCity;
  String? permBarangay;
  String? permZipCode;
  String? permAddressLine;

  // --- Present Address ---
  bool sameAsPermanent;
  String? presRegion;
  String? presProvince;
  String? presCity;
  String? presBarangay;
  String? presZipCode;
  String? presAddressLine;

  // --- Contact Information ---
  String? email;
  String? mobileNumber;

  // --- Verification Documents ---
  String? idType;
  String? idFrontPhoto;
  String? idBackPhoto;
  String? selfiePhoto;

  UserVerification({
    this.userId,
    this.verificationStatus = "pending",

    // Personal
    this.firstName,
    this.middleName,
    this.lastName,
    this.suffix,
    this.nationality,
    this.gender,
    this.dateOfBirth,

    // Permanent Address
    this.permRegion,
    this.permProvince,
    this.permCity,
    this.permBarangay,
    this.permZipCode,
    this.permAddressLine,

    // Present Address
    this.sameAsPermanent = false,
    this.presRegion,
    this.presProvince,
    this.presCity,
    this.presBarangay,
    this.presZipCode,
    this.presAddressLine,

    // Contact
    this.email,
    this.mobileNumber,

    // Documents
    this.idType,
    this.idFrontPhoto,
    this.idBackPhoto,
    this.selfiePhoto,
  });

  /// Convert model to JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "verificationStatus": verificationStatus,
      "firstName": firstName,
      "middleName": middleName,
      "lastName": lastName,
      "suffix": suffix,
      "nationality": nationality,
      "gender": gender,
      "dateOfBirth": dateOfBirth?.toIso8601String(),

      "permRegion": permRegion,
      "permProvince": permProvince,
      "permCity": permCity,
      "permBarangay": permBarangay,
      "permZipCode": permZipCode,
      "permAddressLine": permAddressLine,

      "sameAsPermanent": sameAsPermanent,
      "presRegion": presRegion,
      "presProvince": presProvince,
      "presCity": presCity,
      "presBarangay": presBarangay,
      "presZipCode": presZipCode,
      "presAddressLine": presAddressLine,

      "email": email,
      "mobileNumber": mobileNumber,

      "idType": idType,
      "idFrontPhoto": idFrontPhoto,
      "idBackPhoto": idBackPhoto,
      "selfiePhoto": selfiePhoto,
    };
  }

  /// Create model from JSON (useful when fetching from API)
  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      userId: json["userId"],
      verificationStatus: json["verificationStatus"] ?? "pending",

      firstName: json["firstName"],
      middleName: json["middleName"],
      lastName: json["lastName"],
      suffix: json["suffix"],
      nationality: json["nationality"],
      gender: json["gender"],
      dateOfBirth: json["dateOfBirth"] != null
          ? DateTime.parse(json["dateOfBirth"])
          : null,

      permRegion: json["permRegion"],
      permProvince: json["permProvince"],
      permCity: json["permCity"],
      permBarangay: json["permBarangay"],
      permZipCode: json["permZipCode"],
      permAddressLine: json["permAddressLine"],

      sameAsPermanent: json["sameAsPermanent"] ?? false,
      presRegion: json["presRegion"],
      presProvince: json["presProvince"],
      presCity: json["presCity"],
      presBarangay: json["presBarangay"],
      presZipCode: json["presZipCode"],
      presAddressLine: json["presAddressLine"],

      email: json["email"],
      mobileNumber: json["mobileNumber"],

      idType: json["idType"],
      idFrontPhoto: json["idFrontPhoto"],
      idBackPhoto: json["idBackPhoto"],
      selfiePhoto: json["selfiePhoto"],
    );
  }

  /// Allows updating only specific fields
  UserVerification copyWith({
    int? userId,
    String? verificationStatus,
    String? firstName,
    String? middleName,
    String? lastName,
    String? suffix,
    String? nationality,
    String? gender,
    DateTime? dateOfBirth,

    String? permRegion,
    String? permProvince,
    String? permCity,
    String? permBarangay,
    String? permZipCode,
    String? permAddressLine,

    bool? sameAsPermanent,
    String? presRegion,
    String? presProvince,
    String? presCity,
    String? presBarangay,
    String? presZipCode,
    String? presAddressLine,

    String? email,
    String? mobileNumber,

    String? idType,
    String? idFrontPhoto,
    String? idBackPhoto,
    String? selfiePhoto,
  }) {
    return UserVerification(
      userId: userId ?? this.userId,
      verificationStatus: verificationStatus ?? this.verificationStatus,

      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      suffix: suffix ?? this.suffix,
      nationality: nationality ?? this.nationality,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,

      permRegion: permRegion ?? this.permRegion,
      permProvince: permProvince ?? this.permProvince,
      permCity: permCity ?? this.permCity,
      permBarangay: permBarangay ?? this.permBarangay,
      permZipCode: permZipCode ?? this.permZipCode,
      permAddressLine: permAddressLine ?? this.permAddressLine,

      sameAsPermanent: sameAsPermanent ?? this.sameAsPermanent,
      presRegion: presRegion ?? this.presRegion,
      presProvince: presProvince ?? this.presProvince,
      presCity: presCity ?? this.presCity,
      presBarangay: presBarangay ?? this.presBarangay,
      presZipCode: presZipCode ?? this.presZipCode,
      presAddressLine: presAddressLine ?? this.presAddressLine,

      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,

      idType: idType ?? this.idType,
      idFrontPhoto: idFrontPhoto ?? this.idFrontPhoto,
      idBackPhoto: idBackPhoto ?? this.idBackPhoto,
      selfiePhoto: selfiePhoto ?? this.selfiePhoto,
    );
  }
}
