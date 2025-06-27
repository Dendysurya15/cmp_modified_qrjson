import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class HomeController extends GetxController {
  final isLoading = true.obs;
  final hasQRData = false.obs;
  final qrDataMap = <String, String>{}.obs;
  final textControllers = <String, TextEditingController>{}.obs;
  final qrCodeData = ''.obs;
  final showQRCode = false.obs;

  // Add GlobalKey for QR code widget
  final GlobalKey qrKey = GlobalKey();

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

  Future<void> saveQRToGallery() async {
    print('=== SAVING QR TO GALLERY ===');

    // Chain the operations with proper dialog dismissal
    _captureQRCode()
        .then((imageBytes) async {
          if (imageBytes == null)
            throw Exception('Failed to capture QR code image');

          // Save to temp file
          Directory tempDir = await getTemporaryDirectory();
          String fileName =
              'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
          String filePath = '${tempDir.path}/$fileName';

          File tempFile = File(filePath);
          await tempFile.writeAsBytes(imageBytes);

          // Save to gallery
          bool? success = await GallerySaver.saveImage(filePath);

          // Clean up
          if (await tempFile.exists()) {
            await tempFile.delete();
          }

          if (success != true) throw Exception('Failed to save to gallery');

          return success;
        })
        .then((success) {
          // Success - dismiss dialog and show success message
          print("seharusnya dismiss bro ");
          Get.back(); // Close dialog
          Get.snackbar(
            'Success',
            'QR Code saved to gallery!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
          print('✅ QR Code saved successfully');
        })
        .catchError((error) {
          // Error - dismiss dialog and show error
          Get.back(); // Close dialog
          print('❌ Error saving QR to gallery: $error');
          Get.snackbar(
            'Error',
            'Failed to save QR code. Please check storage permissions.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        });
  }

  Future<void> shareQRCode() async {
    try {
      print('=== SHARING QR CODE ===');

      // Step 1: Capture QR code as image
      Uint8List? imageBytes = await _captureQRCode();

      if (imageBytes != null) {
        // Step 2: Save to temporary file
        Directory tempDir = await getTemporaryDirectory();
        String fileName =
            'QR_Code_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String filePath = '${tempDir.path}/$fileName';

        // Write image to file
        File tempFile = File(filePath);
        await tempFile.writeAsBytes(imageBytes);

        // Step 3: Share using correct share_plus API
        final params = ShareParams(
          text: 'QR Code generated by Modified QR App',
          files: [XFile(filePath)],
          subject: 'My QR Code',
        );

        final result = await SharePlus.instance.share(params);

        // Handle share result
        if (result.status == ShareResultStatus.success) {
          Get.snackbar(
            'Success',
            'QR Code shared successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          print('📱 User dismissed share dialog');
        } else {
          print('⚠️ Share result: ${result.status}');
        }

        // Clean up temp file after a delay
        Future.delayed(const Duration(seconds: 30), () async {
          if (await tempFile.exists()) {
            await tempFile.delete();
            print('🗑️ Temporary file cleaned up');
          }
        });
      } else {
        Get.back(); // Close loading dialog
        throw Exception('Failed to capture QR code image');
      }
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      print('❌ Error sharing QR code: $e');

      Get.snackbar(
        'Error',
        'Failed to share QR code: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }

    print('======================');
  }

  // Capture QR code widget as image
  Future<Uint8List?> _captureQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing QR code: $e');
      return null;
    }
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

      print("ini json data $jsonData");
      // Minify JSON (remove unnecessary whitespace)
      Map<String, dynamic> jsonMap = jsonDecode(jsonData);
      String minifiedJson = jsonEncode(jsonMap);

      print("minfiedjson $minifiedJson");
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

      print(finalQRData);
      print('Final QR data length: ${finalQRData.length}');

      return finalQRData;
    } catch (e) {
      print('Encoding error: $e');
      return null;
    }
  }

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

    showQRCode.value = false; // Hide QR code display
    qrCodeData.value = '';

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
