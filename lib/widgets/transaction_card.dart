import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_new/utils/icons_list.dart';
import 'package:expense_tracker_new/widgets/category_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  TransactionCard({
    super.key,
    required this.data,
  });

  final dynamic data;
  var appIcons = AppIcons();

  // Function to delete transaction
  void _deleteTransaction(
      BuildContext context, Map<String, dynamic>? data) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in")),
      );
      return;
    }

    if (data == null ||
        !data.containsKey('id') ||
        !data.containsKey('amount') ||
        !data.containsKey('timestamp') ||
        !data.containsKey('type')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid transaction data")),
      );
      return;
    }

    bool isDeleting = false; // Flag to prevent multiple clicks

    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction"),
        content:
            const Text("Are you sure you want to delete this transaction?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return; // If the user cancels, stop execution

    try {
      isDeleting = true; // Set flag to prevent multiple deletes
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final transactionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection("transactions");

      // Get the transaction document
      DocumentSnapshot transactionDoc;
      try {
        transactionDoc = await transactionRef.doc(data['id']).get();
        if (!transactionDoc.exists) throw "Transaction not found";
      } catch (e) {
        throw "Failed to retrieve transaction: $e";
      }

      double transactionAmount = data['amount'].toDouble();
      bool isCredit = data['type'] == 'credit';

      // Find the previous transaction (before this one)
      QuerySnapshot previousTransactions;
      double previousRemainingAmount = 0;

      try {
        previousTransactions = await transactionRef
            .orderBy('timestamp', descending: true)
            .where('timestamp', isLessThan: data['timestamp'])
            .limit(1)
            .get();

        if (previousTransactions.docs.isNotEmpty) {
          previousRemainingAmount =
              previousTransactions.docs.first['remainingAmount'].toDouble();
        }
      } catch (e) {
        throw "Error fetching previous transactions: $e";
      }

      // Get all transactions after this one
      QuerySnapshot futureTransactions;
      try {
        futureTransactions = await transactionRef
            .orderBy('timestamp')
            .where('timestamp', isGreaterThan: data['timestamp'])
            .get();
      } catch (e) {
        throw "Error fetching future transactions: $e";
      }

      // Update remainingAmount for future transactions
      try {
        for (var doc in futureTransactions.docs) {
          double newRemainingAmount = doc['remainingAmount'].toDouble();
          if (isCredit) {
            newRemainingAmount -= transactionAmount;
          } else {
            newRemainingAmount += transactionAmount;
          }
          await transactionRef
              .doc(doc.id)
              .update({'remainingAmount': newRemainingAmount});
        }
      } catch (e) {
        throw "Error updating future transactions: $e";
      }

      // user's main remainingAmount, totalCredit, and totalDebit
      try {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          int remainingAmount = userDoc['remainingAmount'];
          int totalCredit = userDoc['totalCredit'];
          int totalDebit = userDoc['totalDebit'];

          // Prevent deletion if removing the credit will cause negative balance
          if (isCredit && remainingAmount - transactionAmount.toInt() < 0) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Error: Cannot delete this transaction as it will result in a negative balance.")),
            );
            return;
          }

          if (isCredit) {
            remainingAmount -= transactionAmount.toInt();
            totalCredit -= transactionAmount.toInt();
          } else {
            remainingAmount += transactionAmount.toInt();
            totalDebit -= transactionAmount.toInt();
          }

          await userDocRef.update({
            "remainingAmount": remainingAmount,
            "totalCredit": totalCredit,
            "totalDebit": totalDebit,
            "updatedAt": DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        throw "Error updating user's remaining balance: $e";
      }

      // Delete the transaction
      try {
        await transactionRef.doc(data['id']).delete();
      } catch (e) {
        throw "Error deleting transaction: $e";
      }

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction deleted successfully")),
      );
    } catch (error) {
      Navigator.pop(context); // Close loading dialog if an error occurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    } finally {
      isDeleting = false; // Reset flag
    }
  }

  void _editTransaction(BuildContext context, QueryDocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;

    TextEditingController titleController =
        TextEditingController(text: data['title'] ?? '');
    TextEditingController amountController =
        TextEditingController(text: data['amount']?.toString() ?? '0');

    String type = data['type'] ?? 'credit';
    String category = data['category'] ?? 'Other'; // Store initial category
    double oldAmount = data['amount']?.toDouble() ?? 0; // Store old amount

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Transaction"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
              ),
              CategoryDropdown(
                cattype: category,
                onChanged: (String? value) {
                  if (value != null) {
                    category = value; // Update category
                  }
                },
              ),
              DropdownButtonFormField<String>(
                value: type,
                items: ["credit", "debit"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  type = newValue!;
                },
                decoration: const InputDecoration(labelText: "Type"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                double newAmount = double.tryParse(amountController.text) ?? 0;
                double amountDifference =
                    newAmount - oldAmount; // Find the difference

                DocumentReference userDoc = FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid);

                await FirebaseFirestore.instance
                    .runTransaction((transaction) async {
                  DocumentSnapshot snapshot = await transaction.get(userDoc);
                  if (!snapshot.exists) return;

                  Map<String, dynamic> userData =
                      snapshot.data() as Map<String, dynamic>;

                  double totalDebit = userData['totalDebit']?.toDouble() ?? 0;
                  double totalCredit = userData['totalCredit']?.toDouble() ?? 0;
                  double remainingAmount =
                      userData['remainingAmount']?.toDouble() ?? 0;

                  // Adjust totals based on type and difference
                  if (type == "credit") {
                    totalCredit += amountDifference;
                    remainingAmount += amountDifference;
                  } else if (type == "debit") {
                    totalDebit += amountDifference;
                    remainingAmount -= amountDifference;
                  }

                  // Update transaction data
                  transaction.update(userDoc, {
                    'totalDebit': totalDebit,
                    'totalCredit': totalCredit,
                    'remainingAmount': remainingAmount,
                  });

                  transaction.update(
                    userDoc.collection("transactions").doc(document.id),
                    {
                      'title': titleController.text.trim(),
                      'amount': newAmount,
                      'type': type,
                      'category': category, // Update category in Firestore
                      'updatedAt': DateTime.now().millisecondsSinceEpoch,
                    },
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Transaction updated successfully")),
                );
              },
              child: const Text("Save", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(data['timestamp']);
    String formatedDate = DateFormat('d MMM hh:mma').format(date);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  offset: const Offset(0, 10),
                  color: Colors.grey.withOpacity(0.09),
                  blurRadius: 10.0,
                  spreadRadius: 4.0),
            ]),
        child: ListTile(
            minVerticalPadding: 10,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
            leading: SizedBox(
              width: 70,
              height: 100,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: data['type'] == 'credit'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2)),
                child: Center(
                  child: FaIcon(
                      appIcons.getExpensesCategoryIcons('${data['category']}'),
                      color:
                          data['type'] == 'credit' ? Colors.green : Colors.red),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text("${data['title']}")),
                Text(
                  "${data['type'] == 'credit' ? '+' : '-'} ₱${data['amount']}",
                  style: TextStyle(
                      color:
                          data['type'] == 'credit' ? Colors.green : Colors.red),
                )
              ],
            ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Balance",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      "₱ ${data['remainingAmount']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    )
                  ],
                ),
                Text(
                  formatedDate,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    _editTransaction(context, data);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    _deleteTransaction(
                        context, data.data() as Map<String, dynamic>?);
                  },
                ),
              ],
            )),
      ),
    );
  }
}
