import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int weekOffset = 0; // Keeps track of the selected week (0 = current week)

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("User not logged in"));
    }

    // Determine the start and end of the selected week
    final now = DateTime.now();
    final selectedWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1) + (7 * weekOffset),
    );
    final selectedWeekEnd = DateTime(
      selectedWeekStart.year,
      selectedWeekStart.month,
      selectedWeekStart.day + 6,
      23,
      59,
      59,
    );

    // Format the displayed week range
    final weekRangeText =
        "${DateFormat('MMM d, yyyy').format(selectedWeekStart)} - ${DateFormat('MMM d, yyyy').format(selectedWeekEnd)}";

    return Scaffold(
      backgroundColor: Colors.amber[200],
      appBar: AppBar(
        title: const Text(
          'Weekly Transactions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.amber[600],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Week Navigation Controls
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.amber[600],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      weekOffset--; // Move to previous week
                    });
                  },
                ),
                Text(
                  weekRangeText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      weekOffset++; // Move to next week
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('transactions')
                  .where('timestamp',
                      isGreaterThanOrEqualTo:
                          selectedWeekStart.millisecondsSinceEpoch)
                  .where('timestamp',
                      isLessThanOrEqualTo:
                          selectedWeekEnd.millisecondsSinceEpoch)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }

                // Debugging: Print fetched documents
                print(
                    "Week: $weekRangeText | Transactions fetched: ${snapshot.data!.docs.length}");
                print(
                    "Selected Week Start: ${selectedWeekStart.toLocal()} | Milliseconds: ${selectedWeekStart.millisecondsSinceEpoch}");
                print(
                    "Selected Week End: ${selectedWeekEnd.toLocal()} | Milliseconds: ${selectedWeekEnd.millisecondsSinceEpoch}");

                print("Current time: ${DateTime.now()}");
                print("UTC time: ${DateTime.now().toUtc()}");

                for (var doc in snapshot.data!.docs) {
                  print("Transaction Data: ${doc.data()}");
                }

                // Initialize weekly totals
                Map<String, double> weeklyTotals = {
                  'Mon': 0,
                  'Tue': 0,
                  'Wed': 0,
                  'Thu': 0,
                  'Fri': 0,
                  'Sat': 0,
                  'Sun': 0,
                };

                // Process transactions
                for (var doc in snapshot.data!.docs) {
                  try {
                    int timestamp = doc['timestamp'];
                    double amount = (doc['amount'] as num).toDouble();

                    DateTime date =
                        DateTime.fromMillisecondsSinceEpoch(timestamp);
                    String day =
                        DateFormat('E').format(date); // "Mon", "Tue", etc.

                    if (weeklyTotals.containsKey(day)) {
                      weeklyTotals[day] = (weeklyTotals[day] ?? 0) + amount;
                    }
                  } catch (e) {
                    print("Error processing transaction: $e");
                  }
                }

                // Convert to chart data
                List<_ChartData> chartData = weeklyTotals.entries
                    .map((entry) => _ChartData(entry.key, entry.value))
                    .toList();

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Transactions',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                              '₱ ${chartData.fold(0.0, (sum, item) => sum + item.amount)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SfCartesianChart(
                            title:
                                const ChartTitle(text: 'Weekly Transactions'),
                            primaryXAxis: const CategoryAxis(),
                            primaryYAxis: const NumericAxis(),
                            series: <CartesianSeries<_ChartData, String>>[
                              ColumnSeries<_ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (_ChartData data, _) => data.day,
                                yValueMapper: (_ChartData data, _) =>
                                    data.amount,
                                color: Colors.green[400],
                                dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                    textStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String day;
  final double amount;

  _ChartData(this.day, this.amount);
}
