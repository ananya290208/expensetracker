import 'package:flutter/material.dart';
import 'data/expense_repository.dart';
import 'models/expense.dart';

/// StatefulWidget: holds the Future for the full list and reloads it
/// after every delete.
class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _repo = ExpenseRepository.instance;
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = _repo.fetchExpenses();
  }

  void _reload() {
    setState(() {
      _expensesFuture = _repo.fetchExpenses();
    });
  }

  Future<void> _delete(Expense e) async {
    await _repo.deleteExpense(e.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Expenses'),
        actions: [
          // Same total stream as HomeScreen — both stay in sync automatically.
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StreamBuilder<double>(
                stream: _repo.totalStream,
                initialData: _repo.currentTotal,
                builder: (context, snapshot) =>
                    Text('₹${(snapshot.data ?? 0).toStringAsFixed(0)}'),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses yet.'));
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final e = expenses[index];
              return Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _delete(e),
                child: ListTile(
                  leading: CircleAvatar(child: Text(e.category[0])),
                  title: Text(e.title),
                  subtitle: Text(e.category),
                  trailing: Text('-₹${e.amount.toStringAsFixed(2)}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
