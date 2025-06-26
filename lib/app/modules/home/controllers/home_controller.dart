import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

class HomeController extends GetxController {
  final isLoading = true.obs;
  final hasQRData = false.obs;
  final qrDataMap = <String, String>{}.obs;
  final textControllers = <String, TextEditingController>{}.obs;

  @override
  void onInit() {
    super.onInit();
    processArguments();
  }

  @override
  void onClose() {
    // Dispose all text controllers
    textControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.onClose();
  }

  Future<void> processArguments() async {
    try {
      // Simulate loading for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if we have QR data from scanner
      if (Get.arguments != null) {
        var args = Get.arguments as Map<String, dynamic>;

        if (args.containsKey('qr_data')) {
          Map<String, String> qrData = args['qr_data'];
          int timestamp = args['scan_timestamp'];
          int totalKeys = args['total_keys'];

          print('=== HOME CONTROLLER ===');
          print('Received QR data with $totalKeys keys');
          print('Scan timestamp: $timestamp');

          // Store the QR data
          qrDataMap.value = qrData;
          hasQRData.value = true;

          // Create text controllers for each key
          createTextControllers(qrData);

          print('Created ${textControllers.length} text controllers');
          print('======================');
        } else {
          print('No QR data found in arguments');
          hasQRData.value = false;
        }
      } else {
        print('No arguments received');
        hasQRData.value = false;
      }
    } catch (e) {
      print('Error processing arguments: $e');
      hasQRData.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void createTextControllers(Map<String, String> qrData) {
    // Clear existing controllers
    textControllers.forEach((key, controller) {
      controller.dispose();
    });
    textControllers.clear();

    // Create new controllers for each key
    qrData.forEach((key, value) {
      // Check if value is a nested JSON object
      if (_isNestedJson(value)) {
        // For nested JSON, store the original value but we'll handle display differently
        textControllers[key] = TextEditingController(text: value);
        print(
          'Created controller for nested key: $key with ${_getNestedCount(value)} children',
        );
      } else {
        textControllers[key] = TextEditingController(text: value);
        print('Created controller for simple key: $key');
      }
    });
  }

  Map<String, dynamic> parseNestedJson(String value) {
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  int _getNestedCount(String value) {
    try {
      Map<String, dynamic> parsed = jsonDecode(value);
      return parsed.length;
    } catch (e) {
      return 0;
    }
  }

  void updateNestedValue(String parentKey, String childKey, String newValue) {
    if (textControllers.containsKey(parentKey)) {
      try {
        Map<String, dynamic> nestedData = parseNestedJson(
          textControllers[parentKey]!.text,
        );
        nestedData[childKey] = newValue;
        String updatedJson = jsonEncode(nestedData);
        textControllers[parentKey]!.text = updatedJson;
        qrDataMap[parentKey] = updatedJson;
        print('Updated nested value: $parentKey.$childKey = $newValue');
      } catch (e) {
        print('Error updating nested value: $e');
      }
    }
  }

  void updateValue(String key, String value) {
    if (qrDataMap.containsKey(key)) {
      qrDataMap[key] = value;
      print('Updated $key: $value');
    }
  }

  void generateNewQR() async {
    print('=== GENERATING NEW QR ===');

    try {
      // Step 1: Collect all data from text controllers
      Map<String, dynamic> finalJsonMap = {};

      textControllers.forEach((key, controller) {
        String value = controller.text;
        print(
          'Processing $key: ${value.length > 50 ? value.substring(0, 50) + "..." : value}',
        );

        // Check if this is nested JSON data
        if (_isNestedJson(value)) {
          try {
            // Parse the nested JSON back to Map
            Map<String, dynamic> nestedData = jsonDecode(value);
            finalJsonMap[key] = nestedData;
            print(
              '✅ Added nested data for $key with ${nestedData.length} children',
            );
          } catch (e) {
            print('❌ Error parsing nested JSON for $key: $e');
            finalJsonMap[key] = value; // Fallback to string
          }
        } else {
          // Simple string value
          finalJsonMap[key] = value;
          print('✅ Added simple value for $key');
        }
      });

      // Step 2: Convert to JSON string
      String finalJsonString = jsonEncode(finalJsonMap);
      print('Final JSON length: ${finalJsonString.length}');

      // Step 3: Encode to QR format (ZIP + Base64 + Insert middle string)
      String? qrData = await _encodeJsonToQRFormat(finalJsonString);

      if (qrData != null) {
        // Step 4: Show QR code
        qrCodeData.value = qrData;
        showQRCode.value = true;

        Get.snackbar(
          'Success',
          'QR Code generated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        print('🎉 QR Code generated with ${qrData.length} characters');
      } else {
        throw Exception('Failed to encode QR data');
      }
    } catch (e) {
      print('❌ Error generating QR: $e');
      Get.snackbar(
        'Error',
        'Failed to generate QR code: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    print('========================');
  }

  bool _isNestedJson(String value) {
    try {
      if (value.trim().startsWith('{') && value.trim().endsWith('}')) {
        jsonDecode(value.trim());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _encodeJsonToQRFormat(String jsonData) async {
    try {
      if (jsonData.isEmpty) {
        throw Exception('JSON data is empty');
      }

      print('Step 1: Minifying JSON...');
      // Minify JSON (remove unnecessary whitespace)
      Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      String minifiedJson = jsonEncode(jsonMap);

      if (minifiedJson == "{}") {
        throw Exception('Empty JSON detected');
      }

      print('Step 2: Creating ZIP archive...');
      // Create ZIP archive
      Archive archive = Archive();

      // Add JSON file to archive
      ArchiveFile file = ArchiveFile(
        'output.json',
        minifiedJson.length,
        minifiedJson.codeUnits,
      );
      archive.addFile(file);

      // Compress with best compression
      List<int> zipBytes = ZipEncoder().encode(archive)!;
      print('ZIP created with ${zipBytes.length} bytes');

      print('Step 3: Base64 encoding...');
      // Encode to Base64
      String base64Encoded = base64Encode(zipBytes);
      print('Base64 encoded with ${base64Encoded.length} characters');

      print('Step 4: Inserting middle string...');
      // Insert middle string
      const String halfJsonEncrypted = "5nqHzPKdlILxS9ABpClq";
      int midPoint = base64Encoded.length ~/ 2;
      String firstHalf = base64Encoded.substring(0, midPoint);
      String secondHalf = base64Encoded.substring(midPoint);

      String finalQRData = firstHalf + halfJsonEncrypted + secondHalf;
      print('Final QR data length: ${finalQRData.length}');

      return finalQRData;
    } catch (e) {
      print('Encoding error: $e');
      return null;
    }
  }

  final qrCodeData = ''.obs;
  final showQRCode = false.obs;

  void hideQRCode() {
    showQRCode.value = false;
    qrCodeData.value = '';
  }

  void clearData() {
    qrDataMap.clear();
    textControllers.forEach((key, controller) {
      controller.dispose();
    });
    textControllers.clear();
    hasQRData.value = false;

    Get.snackbar(
      'Cleared',
      'All data cleared!',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  void goToCamera() {
    Get.offNamed('/camera'); // Update this with your actual camera route
  }
}
