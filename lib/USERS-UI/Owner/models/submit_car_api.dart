import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'car_listing.dart';

Future<bool> submitCarListing({
  required CarListing listing,
  required File? mainPhoto,
  required File? orFile,
  required File? crFile,
  required List<File> extraPhotos,
}) async {
  final url = Uri.parse("http://10.72.15.180/carGOAdmin/cars_api.php");

  final request = http.MultipartRequest("POST", url);

  // Required action for API
  request.fields["action"] = "insert";

  // -------- TEXT FIELDS (Mapped to PHP Expected Keys) --------
  request.fields.addAll({
    "owner_id": listing.owner.toString(),
    "status": listing.carStatus ?? "Available",
    "year": listing.year ?? "",
    "brand": listing.brand ?? "",
    "model": listing.model ?? "",
    "body_style": listing.bodyStyle ?? "",
    "trim": listing.trim ?? "",
    "plate_number": listing.plateNumber ?? "",
    "color": listing.color ?? "",
    "description": listing.description ?? "",

    "advance_notice": listing.advanceNotice ?? "",
    "min_trip_duration": listing.minTripDuration ?? "",
    "max_trip_duration": listing.maxTripDuration ?? "",

    "delivery_types": jsonEncode(listing.deliveryTypes),
    "features": jsonEncode(listing.features),
    "rules": jsonEncode(listing.rules),

    "has_unlimited_mileage": listing.hasUnlimitedMileage ? "1" : "0",
    "mileage_limit": listing.mileageLimit.toString(),

    "price_per_day": listing.dailyRate.toString(), // FIXED NAME!
    "location": listing.location ?? "",
    "latitude": listing.latitude.toString(),
    "longitude": listing.longitude.toString(),
  });

  print("🚗 Sending Car Data: ${request.fields}");

  // -------- FILE UPLOADS (Correct field names) --------

  if (mainPhoto != null) {
  request.files.add(await http.MultipartFile.fromPath("image", mainPhoto.path));
  print("📤 Main Photo Attached: ${mainPhoto.path}");
}

if (orFile != null) {
  request.files.add(await http.MultipartFile.fromPath("official_receipt", orFile.path));
  print("📤 Official Receipt Uploaded: ${orFile.path}");
}

if (crFile != null) {
  request.files.add(await http.MultipartFile.fromPath("certificate_of_registration", crFile.path));
  print("📤 Certificate of Registration Uploaded: ${crFile.path}");
}

  if (extraPhotos.isNotEmpty) {
    for (var file in extraPhotos) {
      request.files.add(await http.MultipartFile.fromPath("extra_images[]", file.path));
    }
    print("📤 Extra Images Uploaded: ${extraPhotos.length}");
  }

  // -------- SEND REQUEST --------

  try {
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print("🔍 STATUS CODE: ${response.statusCode}");
    print("📌 SERVER RESPONSE: $responseBody");

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(responseBody);

      if (jsonResp["success"] == true) {
        print("✅ Upload Successful!");
        return true;
      } else {
        print("❌ Upload Failed: ${jsonResp["message"]}");
      }
    } else {
      print("❌ Server rejected upload (Code ${response.statusCode})");
    }

    return false;

  } catch (err) {
    print("🛑 ERROR DURING UPLOAD: $err");
    return false;
  }
}
