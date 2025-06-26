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
                Icon(_getIconForKey(title), color: Colors.blue, size: 20),
                const SizedBox(width: 8),
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

            // Text Field
            TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: _getMaxLinesForKey(title),
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
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),

            // Value preview for long values
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

  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'username':
        return Icons.person;
      case 'nik':
        return Icons.badge;
      case 'tgl':
        return Icons.date_range;
      case 'kemandoran_id':
        return Icons.location_on;
      default:
        if (key.startsWith('tph_')) {
          return Icons.data_array;
        }
        return Icons.text_fields;
    }
  }

  int _getMaxLinesForKey(String key) {
    if (key.startsWith('tph_') || key == 'nik') {
      return 5; // Multi-line for long data
    }
    return 1; // Single line for short data
  }
}
