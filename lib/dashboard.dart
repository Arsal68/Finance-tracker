import 'package:flutter/material.dart';
import 'package:finance_tracker/target.dart';
import 'package:finance_tracker/history.dart';
import 'package:finance_tracker/login_page.dart';
import 'package:finance_tracker/transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ScreenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 240, 255),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF380081),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("account")
                      .doc(uid)
                      .snapshots(),
                  builder: (context, accountSnapshot) {
                    if (accountSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }

                    if (!accountSnapshot.hasData ||
                        !accountSnapshot.data!.exists) {
                      return const Text(
                        "No account found. Please deposit to initialize.",
                        style: TextStyle(color: Colors.black),
                      );
                    }

                    final data = accountSnapshot.data!;
                    final balance = data['balance'] ?? 0.0;
                    final transactions = data['transactions'] ?? 0;
                    final deposit = data['deposit'] ?? 0.0;
                    final withdrawal = data['withdrawal'] ?? 0.0;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, userSnapshot) {
                        final username =
                            userSnapshot.data?.data()
                                as Map<String, dynamic>? ??
                            {};
                        final name = username['username'] ?? 'User';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome, $name ",
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF380081),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _infoRow(
                              "Balance",
                              "\$${balance.toStringAsFixed(1)}",
                            ),
                            _infoRow("Transactions", "$transactions"),
                            _infoRow(
                              "Total Deposit",
                              "\$${deposit.toStringAsFixed(1)}",
                            ),
                            _infoRow(
                              "Total Withdrawal",
                              "\$${withdrawal.toStringAsFixed(1)}",
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double width = constraints.maxWidth;

                  if (width < 650) {
                    // Grid layout for small screens
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildDashboardCard(
                          "Transaction",
                          Icons.swap_horiz,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Transactions(),
                              ),
                            );
                          },
                        ),
                        _buildDashboardCard("History", Icons.history, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistory(),
                            ),
                          );
                        }),
                        _buildDashboardCard("Targets", Icons.flag, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Target()),
                          );
                        }),
                        _buildDashboardCard("Log out", Icons.logout, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        }),
                      ],
                    );
                  } else {
                    // Responsive Row layout for medium and large screens
                    return Row(
                      children: [
                        _buildResponsiveCard(
                          "Transaction",
                          Icons.swap_horiz,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Transactions(),
                              ),
                            );
                          },
                        ),
                        _buildResponsiveCard("History", Icons.history, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionHistory(),
                            ),
                          );
                        }),
                        _buildResponsiveCard("Targets", Icons.flag, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Target()),
                          );
                        }),
                        _buildResponsiveCard("Log out", Icons.logout, () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        }),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:", style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            value,
            style: const TextStyle(
              fontFamily: "Raleway",
              fontWeight: FontWeight.w500,
              color: Color(0xFF380081),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveCard(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildDashboardCard(title, icon, onTap),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 250,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF380081)),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF380081),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
