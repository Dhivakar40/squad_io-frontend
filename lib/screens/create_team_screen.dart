import 'dart:async'; // Required for TimeoutException
import 'dart:io';    // Required for SocketException
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';
import '../main.dart'; // Navigate to TeammateFeed

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
      _showSnackBar("Team Name is required!", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      _showSnackBar("User session expired. Please login again.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 2. HTTP Request with Timeout
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/teams/create'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "description": _descController.text.trim(),
          "leaderId": userId,
          "bucketId": 1 // You might want to make this dynamic later
        }),
      ).timeout(const Duration(seconds: 10)); // Stop waiting after 10 seconds

      // 3. Handle Response Codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSnackBar("Team Created Successfully! 🚀", isError: false);

          await Future.delayed(const Duration(seconds: 1));

          // 4. Navigate
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeammateFeed()),
            );
          }
        }
      } else {
        // Parse server error message
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Server Error: ${response.statusCode}");
      }

    } on SocketException {
      // HANDLE NO INTERNET
      _showSnackBar("No internet connection. Please check your network.", isError: true);
    } on TimeoutException {
      // HANDLE TIMEOUT
      _showSnackBar("Server timed out. Please try again later.", isError: true);
    } on http.ClientException {
      // HANDLE GENERIC NETWORK ERRORS
      _showSnackBar("Network error. Connection failed.", isError: true);
    } catch (e) {
      // HANDLE EVERYTHING ELSE
      _showSnackBar("Failed: ${e.toString().replaceAll("Exception:", "").trim()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for cleaner SnackBar code
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent light background
      appBar: AppBar(
        title: const Text("Create Your Squad", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image or Icon (Optional polish)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups_rounded, size: 48, color: Colors.deepPurple.shade400),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            _buildTextField(
              controller: _nameController,
              label: "Team Name",
              icon: Icons.flag_outlined,
              hint: "e.g. Hackathon Winners",
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descController,
              label: "Project Idea / Description",
              icon: Icons.lightbulb_outline,
              hint: "Briefly describe what you are building...",
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTeam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text(
                  "Create Team & Find Members",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 1.5)
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}