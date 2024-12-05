import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AddToDoPage extends StatefulWidget {
  const AddToDoPage({Key? key}) : super(key: key);

  @override
  State<AddToDoPage> createState() => _AddToDoPageState();
}

class _AddToDoPageState extends State<AddToDoPage> {
  final TextEditingController titleController = TextEditingController();
  final List<TextEditingController> checklistControllers = [];
  final String baseUrl = "http://94.74.86.174:8080/api";
  final Uuid uuid = const Uuid();

  void addChecklistItem() {
    setState(() {
      checklistControllers.add(TextEditingController());
    });
  }

  void removeChecklistItem(int index) {
    setState(() {
      checklistControllers.removeAt(index);
    });
  }

  Future<void> saveChecklist() async {
    final String title = titleController.text;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final List<String> checklistItems = checklistControllers
        .map((controller) => controller.text)
        .where((text) => text.isNotEmpty)
        .toList();

    try {
      // Retrieve the token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Token not found. Please login again.');
      }

      // Step 1: Save the checklist
      final checklistResponse = await http.post(
        Uri.parse('$baseUrl/checklist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': title}),
      );

      if (checklistResponse.statusCode == 200 ||
          checklistResponse.statusCode == 201) {
        final Map<String, dynamic> checklistData =
            jsonDecode(checklistResponse.body);

        // Debugging response to see the full response body
        print('Checklist Response Body: ${checklistResponse.body}');

        // Memastikan checklistId ada dan bertipe int
        if (checklistData['id'] == null || checklistData['id'] is! int) {
          throw Exception('Checklist ID not found or is not a valid integer.');
        }

        final int checklistId = checklistData['id'];

        // Step 2: Save checklist items
        for (final item in checklistItems) {
          final itemResponse = await http.post(
            Uri.parse('$baseUrl/checklist/$checklistId/item'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'itemName': item}),
          );

          if (itemResponse.statusCode != 200 &&
              itemResponse.statusCode != 201) {
            print('Error saving item: $item');
            print('Status Code: ${itemResponse.statusCode}');
            print('Response Body: ${itemResponse.body}');
            throw Exception('Failed to save checklist item: $item');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist saved successfully!')),
        );

        // Clear the title and checklist items after saving
        titleController.clear();
        setState(() {
          checklistControllers.clear();
        });
      } else {
        print('Error saving checklist');
        print('Status Code: ${checklistResponse.statusCode}');
        print('Response Body: ${checklistResponse.body}');
        throw Exception('Failed to save checklist');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving checklist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Todo Page'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            const Text(
              'Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter title here',
              ),
            ),
            const SizedBox(height: 16),

            // Check List Section
            const Text(
              'Check List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Checklist List
            Expanded(
              child: ListView.builder(
                itemCount: checklistControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: checklistControllers[index],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter checklist item',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () => removeChecklistItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Add Checklist Button
            ElevatedButton(
              onPressed: addChecklistItem,
              child: const Text('Add Checklist Item'),
            ),

            const SizedBox(height: 16),

            // Save and Clear Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: saveChecklist,
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    titleController.clear();
                    setState(() {
                      checklistControllers.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Todo cleared')),
                    );
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
