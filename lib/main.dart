import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'api_service.dart';
import 'user_model.dart';
import 'screens/create_profile_screen.dart'; // Ensure this file exists
import 'screens/dashboard_screen.dart';      // Ensure this file exists

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://easucizkxzurvcsgacqx.supabase.co',
    anonKey: 'sb_publishable_pFyA-pWRmZDUZsrkWvGVcw_mMmwIpEN',
  );

  runApp(const SquadApp());
}

class SquadApp extends StatelessWidget {
  const SquadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Squad.io',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // CORRECTED: Restored AuthGate to handle Login vs Dashboard
      home: const AuthGate(),
    );
  }
}

// ------------------- THE AUTH GATE -------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Loading state (while checking auth)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // 2. User is logged in! Now check if their profile is complete.
          return FutureBuilder(
            // Fetch the specific user row from the database
            future: Supabase.instance.client
                .from('users')
                .select()
                .eq('id', session.user.id)
                .single(),
            builder: (context, userSnapshot) {
              // Loading while fetching profile data...
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Check if we have data
              final data = userSnapshot.data;

              // 3. THE DECISION LOGIC
              // If data is null OR full_name is empty/null -> Go to Setup
              if (data == null || data['full_name'] == null || data['full_name'] == '') {
                return const CreateProfileScreen();
              }

              // Otherwise -> Profile is ready, go to Dashboard
              return const DashboardScreen();
            },
          );
        } else {
          // User is NOT logged in -> Go to Login
          return const LoginScreen();
        }
      },
    );
  }
}

// ------------------- TEAMMATE FEED SCREEN -------------------
// (Note: This is used when navigating from the Dashboard)
class TeammateFeed extends StatefulWidget {
  const TeammateFeed({super.key});

  @override
  State<TeammateFeed> createState() => _TeammateFeedState();
}

class _TeammateFeedState extends State<TeammateFeed> {
  final ApiService apiService = ApiService();
  late Future<List<AppUser>> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = apiService.findTeammates();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    // AuthGate handles the redirect automatically
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommended Squads"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<AppUser>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No teammates found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              AppUser user = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(user.fullName.isNotEmpty ? user.fullName[0] : "?"),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text("${user.department} • Match Score: ${user.score}"),
                  trailing: const Icon(Icons.person_add_alt_1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}