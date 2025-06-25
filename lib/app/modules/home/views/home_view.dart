import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:modified_qrjson/app/routes/app_pages.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HomeView'), centerTitle: true),
      body: const Center(
        child: Text('HomeView is working', style: TextStyle(fontSize: 20)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.offNamed(Routes.camera),
        backgroundColor: Colors.green,
        child: Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
