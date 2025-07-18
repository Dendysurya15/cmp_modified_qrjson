import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modified_qrjson/app/widgets/nested_qr_data_widget.dart';
import 'package:modified_qrjson/app/widgets/qr_data_input_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../controllers/home_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('Modified QR - v${snapshot.data!.version}');
            }
            return const Text('Modified QR');
          },
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF5F8575),
        foregroundColor: Colors.white,
      ),
      body: Obx(() => _buildBody()),
      floatingActionButton: Obx(
        () =>
            !controller.hasQRData.value
                ? Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 10, 20),
                  child: FloatingActionButton(
                    onPressed: controller.goToCamera,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.photo_camera, color: Colors.white),
                  ),
                )
                : const SizedBox(),
      ),
    );
  }

  Widget _buildBody() {
    // Loading State
    if (controller.isLoading.value) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Processing QR data...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // QR Code Display State
    if (controller.showQRCode.value) {
      return _buildQRCodeDisplay();
    }

    // Success State - Has QR Data
    if (controller.hasQRData.value) {
      return Column(
        children: [
          _buildHeader(),
          _buildDataList(),
          _buildActionButtons(),
        ], // ✅ Changed to _buildActionButtons
      );
    }

    // Default State - No QR Data
    return _buildEmptyState();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'QR Data Loaded',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Total ${controller.qrDataMap.length} key',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    return Expanded(
      child: ListView.builder(
        itemCount: controller.qrDataMap.length,
        itemBuilder: (context, index) {
          String key = controller.qrDataMap.keys.elementAt(index);
          String value = controller.qrDataMap[key]!;

          // Check if this is nested JSON data
          if (_isNestedJson(value)) {
            return NestedQRDataWidget(
              title: key,
              controller: controller.textControllers[key]!,
              onNestedChanged: (childKey, newValue) {
                controller.updateNestedValue(key, childKey, newValue);
              },
            );
          } else {
            return QRDataInputWidget(
              title: key,
              controller: controller.textControllers[key]!,
              onChanged: (value) => controller.updateValue(key, value),
            );
          }
        },
      ),
    );
  }

  bool _isNestedJson(String value) {
    try {
      if (value.trim().startsWith('{') && value.trim().endsWith('}')) {
        var decoded = jsonDecode(value.trim());
        return decoded is Map && decoded.isNotEmpty;
      }
      return false;
    } catch (e) {
      print("JSON decode error: $e");
      return false;
    }
  }

  Widget _buildActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: controller.clearData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Clear',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton(
              onPressed: controller.generateNewQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Generate QR',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No QR Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a QR code to see data here',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Updated _buildQRCodeDisplay method with Share button

  Widget _buildQRCodeDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.qr_code, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  'Generated QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Scan this QR code with your app',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QR Code with RepaintBoundary for capturing
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: controller.qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.white,
                    child: QrImageView(
                      data: controller.qrCodeData.value,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      errorCorrectionLevel: QrErrorCorrectLevel.L,
                      semanticsLabel: 'QR Code with JSON data',
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ✅ Updated Buttons with Save and Share
          Column(
            children: [
              // Save and Share buttons row
              Row(
                children: [
                  // Save to Gallery Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.saveQRToGallery,
                      icon: const Icon(Icons.save_alt, size: 20),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ✅ Share Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.shareQRCode,
                      icon: const Icon(Icons.share, size: 20),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Back to Edit button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.hideQRCode,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back to Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
