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
  List<_ChartData> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final endOfWeek = startOfWeek.add(const Duration(days: 6)); // Sunday

    final transactionsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('timestamp',
            isGreaterThanOrEqualTo: startOfWeek.millisecondsSinceEpoch)
        .where('timestamp',
            isLessThanOrEqualTo: endOfWeek.millisecondsSinceEpoch)
        .get();

    Map<String, double> weeklyTotals = {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };

    for (var doc in transactionsQuery.docs) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(doc['timestamp']);
      String day = DateFormat('E').format(date);
      weeklyTotals[day] = (weeklyTotals[day] ?? 0) + doc['amount'];
    }

    setState(() {
      chartData = weeklyTotals.entries
          .map((entry) => _ChartData(entry.key, entry.value))
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                    'P ${chartData.fold(0.0, (sum, item) => sum + item.amount)}',
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
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SfCartesianChart(
                        title: const ChartTitle(text: 'Weekly Transactions'),
                        primaryXAxis: const CategoryAxis(),
                        primaryYAxis: const NumericAxis(),
                        series: <CartesianSeries<_ChartData, String>>[
                          ColumnSeries<_ChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (_ChartData data, _) => data.day,
                            yValueMapper: (_ChartData data, _) => data.amount,
                            color: Colors.green[400],
                            dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
                                textStyle: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
              ),
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
