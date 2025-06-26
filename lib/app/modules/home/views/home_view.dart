import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:modified_qrjson/app/widgets/nested_qr_data_widget.dart';
import 'package:modified_qrjson/app/widgets/qr_data_input_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Data Manager'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Obx(
            () =>
                controller.hasQRData.value
                    ? IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: controller.clearData,
                    )
                    : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() => _buildBody()),
      floatingActionButton: Obx(
        () =>
            !controller.hasQRData.value
                ? FloatingActionButton(
                  onPressed: controller.goToCamera,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.camera_alt, color: Colors.white),
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

    // Success State - Has QR Data
    if (controller.hasQRData.value) {
      return Column(
        children: [_buildHeader(), _buildDataList(), _buildSaveButton()],
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
            '${controller.qrDataMap.length} fields detected',
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

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
            Icon(Icons.save),
            SizedBox(width: 8),
            Text(
              'Save All Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey.shade400),
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

  Widget _buildQRCodeDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
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

          // QR Code
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
                child: QrImageView(
                  data: controller.qrCodeData.value,
                  version: QrVersions.auto,
                  size: 300.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.hideQRCode,
                  icon: const Icon(Icons.arrow_back),
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Generate new QR with updated data
                    controller.generateNewQR();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Regenerate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
    );
  }
}
