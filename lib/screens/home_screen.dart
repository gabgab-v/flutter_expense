import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_new/screens/login_screen.dart';
import 'package:expense_tracker_new/widgets/add_transaction_form.dart';
import 'package:expense_tracker_new/widgets/hero_card.dart';
import 'package:expense_tracker_new/widgets/transactions_cards.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLogoutLoading = false;
  String username = "User"; // Default username
  String? userId; // User ID (nullable to prevent crash)

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      fetchUsername();
    }
  }

  Future<void> fetchUsername() async {
    try {
      if (userId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          setState(() {
            username = doc.data()?['username'] ?? "User";
          });
        }
      }
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> logOut() async {
    setState(() => isLogoutLoading = true);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
    setState(() => isLogoutLoading = false);
  }

  _dialogBuilder(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          content: AddTransactionForm(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow.shade700,
        onPressed: () => _dialogBuilder(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.yellow.shade700,
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min, // Prevents full-width stretching
            children: [
              Image.asset(
                'assets/logo2.png', // Change to your image path
                height: 40, // Increase size for better visibility
                width: 40, // Keep it proportional
              ),
              const Text(
                "xpensify",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36, // Slightly bigger title
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: logOut,
            icon: isLogoutLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.exit_to_app, color: Colors.white),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (userId != null) HeroCard(userId: userId!), // Prevent crash
            const TransactionsCard(),
          ],
        ),
      ),
    );
  }
}
