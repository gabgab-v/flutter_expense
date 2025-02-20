import 'package:expense_tracker_new/screens/home_screen.dart';
import 'package:expense_tracker_new/screens/transaction_screen.dart';
import 'package:expense_tracker_new/widgets/navbar.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var isLogoutLoading = false;
  int currentIndex = 0;
  var pageViewList = [const HomeScreen(), const TransactionScreen()];

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Navbar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int value) {
            setState(() {
              currentIndex = value;
            });
          }),
      
      body: pageViewList[currentIndex],
    );
  }
}
