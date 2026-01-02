import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _deptController = TextEditingController(); // Simplified for now
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/user/profile/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['full_name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _deptController.text = data['department'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/user/update-profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "fullName": _nameController.text,
          "department": _deptController.text, // Assuming simple text for now
          "year": "2024", // Hardcoded/Hidden or add a controller if needed
          "bio": _bioController.text,
          "skills": [] // Keep existing skills logic if you want
        }),
      );

      if (response.statusCode == 200) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
          Navigator.pop(context); // Go back to dashboard
        }
      }
    } catch (e) {
      // Error handling
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 16),
            TextField(controller: _deptController, decoration: const InputDecoration(labelText: "Department")),
            const SizedBox(height: 16),
            TextField(controller: _bioController, decoration: const InputDecoration(labelText: "Bio"), maxLines: 3),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text("Save Changes")
            )
          ],
        ),
      ),
    );
  }
}