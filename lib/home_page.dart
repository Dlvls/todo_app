import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'add_to_do_page.dart';
import 'auth/login_page.dart';

class Checklist {
  final int id;
  final String name;
  final bool checklistCompletionStatus;

  Checklist({
    required this.id,
    required this.name,
    required this.checklistCompletionStatus,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'],
      name: json['name'],
      checklistCompletionStatus: json['checklistCompletionStatus'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String baseUrl = "http://94.74.86.174:8080/api";
  List<Checklist> checklists = [];

  @override
  void initState() {
    super.initState();
    _fetchChecklists();
  }

  // Fetch checklists from the API
  Future<void> _fetchChecklists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checklist'),
        headers: {
          'Accept': 'application/json',
        },
      );

      // Check if response is successful (status code 200)
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> checklistData = data['data'];

        setState(() {
          checklists =
              checklistData.map((item) => Checklist.fromJson(item)).toList();
        });
      } else {
        // Print response body when status code is not 200
        print('Failed to load checklists. Response: ${response.body}');
        throw Exception('Failed to load checklists');
      }
    } catch (e) {
      print('Error fetching checklists: $e');
      // Print the error response body if available
      if (e is http.Response) {
        print('Error response body: ${e.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: checklists.isEmpty
          ? const Center(
              child:
                  CircularProgressIndicator()) // Show a loading indicator if data is not yet available
          : ListView.builder(
              itemCount: checklists.length,
              itemBuilder: (context, index) {
                final checklist = checklists[index];
                return ListTile(
                  title: Text(checklist.name),
                  subtitle: Text(
                    checklist.checklistCompletionStatus
                        ? 'Completed'
                        : 'Incomplete',
                  ),
                  onTap: () {
                    // Navigate to the checklist details page (if necessary)
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddToDoPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Todo',
        elevation: 4.0,
      ),
    );
  }
}
