import 'package:flutter/material.dart';
import 'dart:convert';

class NestedQRDataWidget extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final Function(String, String)? onNestedChanged;

  const NestedQRDataWidget({
    Key? key,
    required this.title,
    required this.controller,
    this.onNestedChanged,
  }) : super(key: key);

  @override
  State<NestedQRDataWidget> createState() => _NestedQRDataWidgetState();
}

class _NestedQRDataWidgetState extends State<NestedQRDataWidget> {
  Map<String, TextEditingController> childControllers = {};
  Map<String, dynamic> nestedData = {};
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _parseNestedData();
    widget.controller.addListener(_onParentChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onParentChanged);
    childControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  void _onParentChanged() {
    _parseNestedData();
  }

  void _parseNestedData() {
    try {
      Map<String, dynamic> parsed = jsonDecode(widget.controller.text);

      if (parsed != nestedData) {
        setState(() {
          nestedData = parsed;
          _createChildControllers();
        });
      }
    } catch (e) {
      print('Error parsing nested data for ${widget.title}: $e');
    }
  }

  void _createChildControllers() {
    // Dispose existing controllers
    childControllers.forEach((key, controller) {
      controller.dispose();
    });
    childControllers.clear();

    // Create new controllers
    nestedData.forEach((key, value) {
      childControllers[key] = TextEditingController(text: value.toString());
    });
  }

  void _updateNestedValue(String childKey, String newValue) {
    setState(() {
      nestedData[childKey] = newValue;
      String updatedJson = jsonEncode(nestedData);
      widget.controller.text = updatedJson;
    });

    if (widget.onNestedChanged != null) {
      widget.onNestedChanged!(childKey, newValue);
    }
  }

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
      child: Column(
        children: [
          // Parent Header
          InkWell(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForKey(widget.title),
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${nestedData.length} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NESTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Children
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState:
                isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children:
                    nestedData.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: childControllers[entry.key],
                              onChanged:
                                  (value) =>
                                      _updateNestedValue(entry.key, value),
                              decoration: InputDecoration(
                                hintText: 'Enter value for ${entry.key}...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'tgl':
        return Icons.date_range;
      case 'nik':
        return Icons.badge;
      default:
        return Icons.folder_open;
    }
  }
}
