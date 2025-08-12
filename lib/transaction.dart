import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  final amount = TextEditingController();
  final description = TextEditingController();
  String? selectedTransactionType;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 56, 0, 129),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 56, 0, 129),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 251, 0)),
        title: Text(
          'Transactions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Select Transaction Type'),
                  value: selectedTransactionType,
                  items: ['Deposit', 'Withdrawal'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() {
                    selectedTransactionType = value!;
                  }),
                  validator: (value) =>
                      value == null ? 'Please select a transaction type' : null,
                  dropdownColor: const Color.fromARGB(255, 56, 0, 129),
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amount,
                  decoration: _inputDecoration('Enter Amount'),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    return (parsed == null || parsed <= 0)
                        ? 'Enter a valid amount'
                        : null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: description,
                  decoration: _inputDecoration('Enter Description'),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      try {
                        final amountValue = double.parse(amount.text);
                        final accountRef = FirebaseFirestore.instance
                            .collection('account')
                            .doc(uid);

                        final accountSnapshot = await accountRef.get();
                        if (!accountSnapshot.exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Account not found. Please contact support.',
                              ),
                            ),
                          );
                          return;
                        }

                        final balance = (accountSnapshot['balance'] ?? 0.0);

                        if (selectedTransactionType == 'Deposit') {
                          await accountRef.update({
                            'balance': FieldValue.increment(amountValue),
                            'deposit': FieldValue.increment(amountValue),
                            'transactions': FieldValue.increment(1),
                          });
                        } else {
                          if (amountValue > balance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Insufficient balance'),
                              ),
                            );
                            return;
                          }
                          await accountRef.update({
                            'balance': FieldValue.increment(-amountValue),
                            'withdrawal': FieldValue.increment(amountValue),
                            'transactions': FieldValue.increment(1),
                          });
                        }

                        await FirebaseFirestore.instance
                            .collection('transactions')
                            .add({
                              'userid': uid,
                              'type': selectedTransactionType,
                              'description': description.text,
                              'amount': amountValue,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaction successful!'),
                          ),
                        );

                        setState(() {
                          amount.clear();
                          description.clear();
                          selectedTransactionType = null;
                        });
                      } catch (e) {
                        debugPrint('Transaction error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Something went wrong')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 251, 0),
                      foregroundColor: const Color.fromARGB(255, 56, 0, 129),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 234, 0, 255),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: const Color.fromARGB(255, 85, 35, 145),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 221, 0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 251, 0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
