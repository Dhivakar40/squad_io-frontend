import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../api_service.dart';

class TeamFeedScreen extends StatefulWidget {
  const TeamFeedScreen({super.key});

  @override
  State<TeamFeedScreen> createState() => _TeamFeedScreenState();
}

class _TeamFeedScreenState extends State<TeamFeedScreen> {
  List<dynamic> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      // 1. Get the User ID FIRST (Outside the http call)
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 2. Now use that ID in the URL
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/teams/find?excludeLeader=$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _teams = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestToJoin(String teamId, String leaderId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl.replaceAll("/match", "")}/teams/join-request'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "teamId": teamId,
          "leaderId": leaderId
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request Sent! 🚀"), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Already requested or error"), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Find a Team")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
          ? const Center(child: Text("No active teams found."))
          : ListView.builder(
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          final leader = team['leader']; // Fetched via foreign key

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(team['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team['description'] ?? "No description"),
                  const SizedBox(height: 4),
                  Text("Leader: ${leader != null ? leader['full_name'] : 'Unknown'}",
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _requestToJoin(team['id'], team['leader_id'] ?? ''), // Safety check needed here if leader_id is missing
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white
                ),
                child: const Text("Join"),
              ),
            ),
          );
        },
      ),
    );
  }
}