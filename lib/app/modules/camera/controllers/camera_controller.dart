import 'package:get/get.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:flutter/material.dart';
import 'package:modified_qrjson/app/routes/app_pages.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

class CameraController extends GetxController {
  QRViewController? qrController;
  final isReady = false.obs;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final hasScanned = false.obs;
  final isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    isReady.value = true; // QR scanner doesn't need initialization like camera
  }

  @override
  void onClose() {
    disposeQR();
    super.onClose();
  }

  // QR Scanner methods
  void onQRViewCreated(QRViewController controller) {
    qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned.value) {
        onQRScanned(scanData);
      }
    });
  }

  void onQRScanned(Barcode scanData) {
    hasScanned.value = true;

    // Print QR code data to console
    print('QR Code detected: ${scanData.code}');
    print('QR Code format: ${scanData.format}');

    // Pause scanning to prevent multiple scans
    qrController?.pauseCamera();

    // Process the QR data after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      processQRData(scanData.code ?? '');
      hasScanned.value = false;
      qrController?.resumeCamera();
    });
  }

  // Process and decode the QR data
  Future<void> processQRData(String qrData) async {
    isProcessing.value = true;

    try {
      print('Processing QR data...');

      // Step 1: Remove the middle encrypted string
      const String halfJsonEncrypted =
          "5nqHzPKdlILxS9ABpClq"; // Your AppUtils.half_json_encrypted

      if (!qrData.contains(halfJsonEncrypted)) {
        print('Error: QR data does not contain expected separator');
        return;
      }

      // Split and reconstruct original base64
      List<String> parts = qrData.split(halfJsonEncrypted);
      if (parts.length != 2) {
        print('Error: Invalid QR data format');
        return;
      }

      String originalBase64 = parts[0] + parts[1];
      print('Reconstructed Base64: ${originalBase64.substring(0, 50)}...');

      // Step 2: Decode from Base64
      List<int> zipBytes;
      try {
        zipBytes = base64Decode(originalBase64);
        print(
          'Base64 decoded successfully, zip bytes length: ${zipBytes.length}',
        );
      } catch (e) {
        print('Error decoding Base64: $e');
        return;
      }

      // Step 3: Unzip the data
      try {
        Archive archive = ZipDecoder().decodeBytes(zipBytes);

        for (ArchiveFile file in archive) {
          if (file.name == 'output.json') {
            List<int> jsonBytes = file.content as List<int>;
            String jsonString = utf8.decode(jsonBytes);

            print('=== DECODED JSON ===');
            printLongString(jsonString);
            print('===================');

            // Parse JSON and extract all keys dynamically
            try {
              Map<String, dynamic> jsonMap = jsonDecode(jsonString);

              // Get all keys and their values
              Map<String, String> extractedData = {};

              jsonMap.forEach((key, value) {
                extractedData[key] = value.toString();
                print(
                  'Key: $key, Value: ${value.toString().substring(0, value.toString().length > 100 ? 100 : value.toString().length)}${value.toString().length > 100 ? '...' : ''}',
                );
              });

              print('=== EXTRACTED KEYS ===');
              print('Total keys found: ${extractedData.length}');
              extractedData.keys.forEach((key) {
                print('Key: $key');
              });
              print('=====================');

              // Navigate back with the extracted data as arguments
              goToHomeWithData(extractedData);
            } catch (e) {
              print('Could not parse JSON: $e');
              // Navigate back without data if parsing fails
              goToHome();
            }

            return;
          }
        }

        print('Error: output.json not found in zip archive');
      } catch (e) {
        print('Error unzipping data: $e');
      }
    } catch (e) {
      print('Error processing QR data: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  void disposeQR() {
    qrController?.dispose();
    qrController = null;
  }

  void pauseScanning() {
    qrController?.pauseCamera();
  }

  void resumeScanning() {
    qrController?.resumeCamera();
    hasScanned.value = false;
  }

  void toggleFlash() {
    qrController?.toggleFlash();
  }

  void goToHome() {
    disposeQR();
    Get.offNamed(Routes.home);
  }

  void goToHomeWithData(Map<String, String> qrData) {
    disposeQR();

    // Navigate back with arguments
    Get.offNamed(Routes.home, arguments: {'qr_data': qrData});
  }

  // Helper method to print long strings in chunks
  void printLongString(String text) {
    const int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      print(text.substring(i, end));
    }
  }
}
