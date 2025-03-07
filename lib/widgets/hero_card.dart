import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot<Map<String, dynamic>>> usersStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .map((snapshot) => snapshot);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("Document does not exist");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }

        var data = snapshot.data!.data();

        if (data == null) {
          return const Text("No data found");
        }

        return Cards(
          data: data,
        );
      },
    );
  }
}

class Cards extends StatelessWidget {
  const Cards({
    super.key,
    required this.data,
  });
  final Map data;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${data['username'] ?? 'User'}", // Ensure it doesn't crash if username is missing
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5), // Add spacing

                const Text(
                  "Total Balance",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.2,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  "P ${data['remainingAmount'] < 0 ? 0 : data['remainingAmount']}",
                  style: const TextStyle(
                      fontSize: 44,
                      color: Colors.white,
                      height: 1.2,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.only(top: 30, bottom: 10, left: 10, right: 10),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                CardOne(
                  color: Colors.green,
                  heading: 'Credit',
                  amount: "${data['totalCredit']}",
                ),
                const SizedBox(
                  width: 10,
                ),
                CardOne(
                  color: Colors.red,
                  heading: 'Debit',
                  amount: "${data['totalDebit']}",
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CardOne extends StatelessWidget {
  const CardOne({
    super.key,
    required this.color,
    required this.heading,
    required this.amount,
  });
  final Color color;
  final String heading;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: TextStyle(color: color, fontSize: 14),
                  ),
                  Text(
                    "P $amount",
                    style: TextStyle(
                        color: color,
                        fontSize: 30,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  heading == "Credit"
                      ? Icons.arrow_upward_outlined
                      : Icons.arrow_downward_outlined,
                  color: color,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
