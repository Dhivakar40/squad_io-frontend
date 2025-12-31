import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';
import '../main.dart'; // Navigate to TeammateFeed after success

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createTeam() async {
    // 1. Validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Team Name is required!")));
      return;
    }

    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/teams/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "description": _descController.text.trim(),
          "leaderId": userId,
          "bucketId": 1
        }),
      ).timeout(const Duration(seconds: 10)
      );

      // 3. Handle Response
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Team Created Successfully! 🚀"), backgroundColor: Colors.green)
          );

          // DELAY slightly so user sees the success message
          await Future.delayed(const Duration(seconds: 1));

          // 4. NAVIGATE to the Marketplace (Find Teammates)
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TeammateFeed())
          );
        }
      } else {
        // Parse error message from server
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Unknown error");
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Squad")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Team Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Project Idea / Description", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create Team & Find Members"),
              ),
            )
          ],
        ),
      ),
    );
  }
}