import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Target extends StatefulWidget {
  const Target({super.key});

  @override
  State<Target> createState() => _TargetState();
}

class _TargetState extends State<Target> {
  final targetTypeController = TextEditingController();
  final targetAmountController = TextEditingController();
  final targetDescController = TextEditingController();

  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addTargetToFirestore() async {
    if (targetTypeController.text.isEmpty ||
        targetAmountController.text.isEmpty ||
        targetDescController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection("targets").add({
        'userid': uid,
        'type': targetTypeController.text.trim(),
        'amount': double.parse(targetAmountController.text.trim()),
        'description': targetDescController.text.trim(),
        'status': "pending",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target added successfully!')),
      );

      targetTypeController.clear();
      targetAmountController.clear();
      targetDescController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 240, 255),
      appBar: AppBar(
        title: const Text("Set Target", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF380081),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            _buildTargetForm(),
            const SizedBox(height: 20),
            Expanded(child: _buildTargetList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: targetTypeController.text.isNotEmpty
                  ? targetTypeController.text
                  : null,
              items: const [
                DropdownMenuItem(value: 'Income', child: Text('Income')),
                DropdownMenuItem(value: 'Expense', child: Text('Expense')),
              ],
              onChanged: (value) {
                targetTypeController.text = value!;
              },
              decoration: _inputDecoration("Select target type"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: targetAmountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("Enter target amount"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: targetDescController,
              decoration: _inputDecoration("Enter a brief description"),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addTargetToFirestore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF380081),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Set Target",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("targets")
          .where("userid", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No targets set.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'] ?? '';
            final amount = (data['amount'] ?? 0).toDouble();
            final desc = data['description'] ?? '';
            final status = data['status'] ?? 'pending';

            _autoCheckStatus(type, amount, doc.id, status);

            return TargetCard(
              type: type,
              amount: amount,
              desc: desc,
              status: status,
              docId: doc.id,
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _autoCheckStatus(
    String type,
    double amount,
    String docId,
    String currentStatus,
  ) async {
    if (currentStatus == 'completed') return;

    final accountDoc = await FirebaseFirestore.instance
        .collection("account")
        .doc(uid)
        .get();
    if (!accountDoc.exists) return;

    final account = accountDoc.data()!;
    final balance = (account['balance'] ?? 0).toDouble();
    final withdrawal = (account['withdrawal'] ?? 0).toDouble();

    if ((type == 'Income' && balance >= amount) ||
        (type == 'Expense' && withdrawal >= amount)) {
      await FirebaseFirestore.instance.collection("targets").doc(docId).update({
        'status': 'completed',
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF380081)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF380081), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class TargetCard extends StatelessWidget {
  final String type;
  final double amount;
  final String desc;
  final String status;
  final String docId;

  const TargetCard({
    super.key,
    required this.type,
    required this.amount,
    required this.desc,
    required this.status,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF380081), width: 1.5),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        title: Text(
          "Target: $type",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF380081),
          ),
        ),
        subtitle: Text(
          "Amount: \$$amount\nDescription: $desc\nStatus: $status",
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
        trailing: IconButton(
          icon: Icon(
            status == 'pending' ? Icons.hourglass_empty : Icons.check_circle,
            color: status == 'pending' ? Colors.orange : Colors.green,
            size: 30,
          ),
          onPressed: () {
            if (status == 'pending') {
              _showPendingDialog(context);
            } else {
              _showDeleteDialog(context);
            }
          },
        ),
      ),
    );
  }

  void _showPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Target Incomplete"),
        content: const Text("This target has not been completed yet."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove Completed Target"),
        content: const Text("Are you sure you want to remove this target?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("targets")
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
