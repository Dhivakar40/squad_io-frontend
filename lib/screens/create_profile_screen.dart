import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_service.dart'; // To access the baseUrl
import '../main.dart'; // To navigate to TeammateFeed
import 'dashboard_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _skillController = TextEditingController();

  String? _selectedDept;
  String? _selectedYear;
  final List<String> _skills = [];
  bool _isLoading = false;

  final List<String> _departments = [
    'CSE', 'IT', 'AIDS', 'ECE', 'EEE', 'MECH', 'CIVIL', 'BME', 'MCTS'
  ];

  final List<String> _years = ['1', '2', '3', '4'];

  // Add a skill to the list
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  // Remove a skill
  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one skill")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/user/update-profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "fullName": _nameController.text.trim(),
          "department": _selectedDept,
          "year": _selectedYear,
          "bio": _bioController.text.trim(),
          "github": _githubController.text.trim(),
          "linkedin": _linkedinController.text.trim(),
          "skills": _skills,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          // Navigate to Home and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()), // <--- CORRECT
                (route) => false,
          );
        }
      } else {
        throw Exception("Failed to update: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tell us about yourself", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 16),

              // Row for Dept and Year
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDept,
                      items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _selectedDept = v),
                      decoration: const InputDecoration(labelText: "Dept", border: OutlineInputBorder()),
                      validator: (value) => value == null ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      items: _years.map((y) => DropdownMenuItem(value: y, child: Text("Year $y"))).toList(),
                      onChanged: (v) => setState(() => _selectedYear = v),
                      decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()),
                      validator: (value) => value == null ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Skills Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillController,
                      decoration: const InputDecoration(labelText: "Add Skill (e.g. Python)", border: OutlineInputBorder()),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 32),
                    onPressed: _addSkill,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Skills Chips Display
              Wrap(
                spacing: 8.0,
                children: _skills.map((skill) => Chip(
                  label: Text(skill),
                  onDeleted: () => _removeSkill(skill),
                  backgroundColor: Colors.deepPurple.shade50,
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Bio / Tagline", border: OutlineInputBorder(), hintText: "E.g. Looking for a hackathon team..."),
              ),
              const SizedBox(height: 16),

              // Links
              TextFormField(
                controller: _githubController,
                decoration: const InputDecoration(labelText: "GitHub URL (Optional)", prefixIcon: Icon(Icons.code), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(labelText: "LinkedIn URL (Optional)", prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}