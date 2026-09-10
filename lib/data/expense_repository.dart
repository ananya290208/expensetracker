import 'dart:async';
import '../models/expense.dart';

/// A stand-in "backend". In a real app this would talk to sqflite,
/// Hive, Firestore, or a REST API — the async shape stays the same.
class ExpenseRepository {
  ExpenseRepository._internal();
  static final ExpenseRepository instance = ExpenseRepository._internal();

  final List<Expense> _expenses = [
    Expense(
      id: '1',
      title: 'Groceries',
      amount: 1450.0,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: '2',
      title: 'Uber to office',
      amount: 220.0,
      category: 'Transport',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Expense(
      id: '3',
      title: 'Electricity bill',
      amount: 1800.0,
      category: 'Bills',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // Broadcast stream: multiple screens (Home, ExpenseList) can listen
  // to the same running total at once.
  final StreamController<double> _totalController =
      StreamController<double>.broadcast();

  Stream<double> get totalStream => _totalController.stream;

  double get currentTotal =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  void _publishTotal() => _totalController.add(currentTotal);

  /// Simulates an async read (e.g. a DB query or network call).
  Future<List<Expense>> fetchExpenses() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final sorted = List<Expense>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  /// Simulates an async write, then pushes the new total to listeners.
  Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _expenses.add(expense);
    _publishTotal();
  }

  Future<void> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.removeWhere((e) => e.id == id);
    _publishTotal();
  }

  void dispose() => _totalController.close();
}
