import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      debugPrint('Firebase initialization notice: $e');
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Root widget listens to auth state changes:
      // - Authenticated: HomeScreen (Expense Tracker)
      // - Unauthenticated: AuthScreen (Login/Registration)
      home: AuthGate(authenticatedHome: HomeScreen()),
    );
  }
}

// Simple data class. Just holds values, nothing else.
class Expense {
  String title;
  double amount;
  String category;

  Expense(this.title, this.amount, this.category);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;

  // A StreamController lets us push new total values over time,
  // and any widget listening (see StreamBuilder below) updates itself.
  StreamController<double> totalController = StreamController<double>();

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // Pretends to fetch data from a server or database.
  void loadExpenses() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      expenses = [
        Expense('Groceries', 1450, 'Food'),
        Expense('Uber', 220, 'Transport'),
        Expense('Electricity Bill', 1800, 'Bills'),
      ];
      isLoading = false;
    });

    updateTotal();
  }

  void updateTotal() {
    double total = 0;
    for (var expense in expenses) {
      total = total + expense.amount;
    }
    totalController.add(total);
  }

  void addExpense(Expense expense) {
    setState(() {
      expenses.add(expense);
    });
    updateTotal();
  }

  void deleteExpense(int index) {
    setState(() {
      expenses.removeAt(index);
    });
    updateTotal();
  }

  void goToAddExpenseScreen() async {
    var newExpense = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen()),
    );

    if (newExpense != null) {
      addExpense(newExpense);
    }
  }

  /// Secure Logout: Invalidates local session tokens and resets the auth stream
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to log out? Your local session tokens will be invalidated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      // AuthGate automatically redirects to AuthScreen
    }
  }

  @override
  void dispose() {
    totalController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          if (currentUser?.email != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Tooltip(
                message: 'Logged in as ${currentUser!.email}',
                child: Chip(
                  avatar: const Icon(Icons.account_circle, size: 18),
                  label: Text(
                    currentUser.email!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Secure Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<double>(
                    stream: totalController.stream,
                    initialData: 0,
                    builder: (context, snapshot) {
                      return Text(
                        'Total: ₹${snapshot.data!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      var expense = expenses[index];
                      return ListTile(
                        title: Text(expense.title),
                        subtitle: Text(expense.category),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('₹${expense.amount.toStringAsFixed(2)}'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.pinkAccent),
                              onPressed: () => deleteExpense(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToAddExpenseScreen,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String selectedCategory = 'Food';

  List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void saveExpense() {
    String title = titleController.text;
    String amountText = amountController.text;

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double? amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number for amount')),
      );
      return;
    }

    Expense newExpense = Expense(title, amount, selectedCategory);
    Navigator.pop(context, newExpense);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: 200,
                child: TextField(
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.center,
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'ExpTitle',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: TextField(
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedCategory,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: saveExpense,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
