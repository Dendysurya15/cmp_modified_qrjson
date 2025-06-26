import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

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

  bool _isNestedJson(String value) {
    try {
      // Check if it starts with { and can be parsed as JSON
      if (value.trim().startsWith('{') && value.trim().endsWith('}')) {
        jsonDecode(value);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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

  void saveAllData() {
    print('=== SAVING DATA ===');
    textControllers.forEach((key, controller) {
      print('$key: ${controller.text}');
    });
    print('==================');

    // You can implement your save logic here
    Get.snackbar(
      'Success',
      'Data saved successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
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
