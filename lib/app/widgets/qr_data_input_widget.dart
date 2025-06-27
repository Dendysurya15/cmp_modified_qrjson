import 'package:flutter/material.dart';

class QRDataInputWidget extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final Function(String)? onChanged;

  const QRDataInputWidget({
    Key? key,
    required this.title,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ MULTILINE Text Field
            TextField(
              controller: controller,
              onChanged: onChanged,
              // ✅ KEY CHANGES FOR MULTILINE:
              maxLines: null, // Allow unlimited lines
              minLines: 1, // Start with 1 line
              keyboardType:
                  TextInputType.multiline, // Enable multiline keyboard
              textInputAction: TextInputAction.done, // Show enter key

              decoration: InputDecoration(
                hintText: 'Enter ${title.toLowerCase()} value...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16, // ✅ Increased vertical padding for multiline
                ),
                // ✅ Ensure the field expands properly
                alignLabelWithHint: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),

            // Character count info
            if (controller.text.length > 50) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Length: ${controller.text.length} characters',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
