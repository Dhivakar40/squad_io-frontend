import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';

class MySquadsScreen extends StatefulWidget {
  const MySquadsScreen({super.key});

  @override
  State<MySquadsScreen> createState() => _MySquadsScreenState();
}

class _MySquadsScreenState extends State<MySquadsScreen> {
  List<dynamic> _myTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyTeams();
  }

  Future<void> _fetchMyTeams() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/user/my-teams/$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _myTeams = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Squads")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myTeams.isEmpty
              ? const Center(child: Text("You haven't created any squads yet."))
              : ListView.builder(
                  itemCount: _myTeams.length,
                  itemBuilder: (context, index) {
                    final team = _myTeams[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.purple.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.deepPurple),
                        title: Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(team['description'] ?? ""),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                           // Future: Open Team Management (See members, etc.)
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Management Coming Soon!")));
                        },
                      ),
                    );
                  },
                ),
    );
  }
}