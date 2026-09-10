import 'package:flutter/material.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../add_expense_screen.dart';
import '../expense_list_screen.dart';

/// StatefulWidget: holds a Future that gets replaced (and the screen
/// rebuilt) every time the underlying data changes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ExpenseRepository.instance;
  late Future<List<Expense>> _recentExpenses;

  @override
  void initState() {
    super.initState();
    _recentExpenses = _repo.fetchExpenses();
  }

  void _reload() {
    setState(() {
      _recentExpenses = _repo.fetchExpenses();
    });
  }

  Future<void> _goToAddExpense() async {
    // Navigation forward + waiting for a result on the way back.
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (added == true) _reload();
  }

  void _goToFullList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
    ).then((_) => _reload()); // refresh recent list after any edits there
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _TotalCard(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: _goToFullList, child: const Text('See all')),
              ],
            ),
            FutureBuilder<List<Expense>>(
              future: _recentExpenses,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Failed to load: ${snapshot.error}');
                }
                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('No expenses yet. Add one!')),
                  );
                }
                return Column(
                  children: expenses
                      .take(5)
                      .map((e) => _ExpenseTile(expense: e))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

/// StatelessWidget: has no state of its own — it just wires the
/// repository's stream into the UI. The StreamBuilder inside it is
/// what actually reacts to change.
class _TotalCard extends StatelessWidget {
  const _TotalCard();

  @override
  Widget build(BuildContext context) {
    final repo = ExpenseRepository.instance;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Spent'),
            const SizedBox(height: 8),
            StreamBuilder<double>(
              stream: repo.totalStream,
              initialData: repo.currentTotal,
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                return Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// StatelessWidget: pure display — same input always renders the same output.
class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Text(expense.category[0])),
        title: Text(expense.title),
        subtitle: Text('${expense.category} • ${_formatDate(expense.date)}'),
        trailing: Text(
          '-₹${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
