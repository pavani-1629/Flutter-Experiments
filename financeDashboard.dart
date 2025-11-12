import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(FinanceDashboardApp());

class FinanceDashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0B0C10),
        primaryColor: Color(0xFF4DD0E1),
      ),
      home: FinanceHome(),
    );
  }
}

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });
}

class FinanceHome extends StatefulWidget {
  @override
  _FinanceHomeState createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> with SingleTickerProviderStateMixin {
  final List<TransactionItem> _transactions = [];
  final Random _rng = Random();

  final Map<String, Color> _categoryColors = {
    'Food': Color(0xFFFF8A80),
    'Transport': Color(0xFFFFCC80),
    'Shopping': Color(0xFFCE93D8),
    'Bills': Color(0xFF90CAF9),
    'Salary': Color(0xFFA5D6A7),
    'Other': Color(0xFFBDBDBD),
  };

  double _forecastPercent = 0.0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _seedSampleData();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _controller.forward();
  }

  void _seedSampleData() {
    final now = DateTime.now();
    _transactions.addAll([
      TransactionItem(
          id: 't1', title: 'Campus Food', category: 'Food', amount: -120.0, date: now.subtract(Duration(days: 1)), note: 'Lunch'),
      TransactionItem(
          id: 't2', title: 'Bus Recharge', category: 'Transport', amount: -60.0, date: now.subtract(Duration(days: 2)), note: ''),
      TransactionItem(
          id: 't3', title: 'Part-time pay', category: 'Salary', amount: 800.0, date: now.subtract(Duration(days: 3)), note: 'May payout'),
      TransactionItem(
          id: 't4', title: 'Electric bill', category: 'Bills', amount: -240.0, date: now.subtract(Duration(days: 4)), note: 'May'),
      TransactionItem(
          id: 't5', title: 'New shoes', category: 'Shopping', amount: -180.0, date: now.subtract(Duration(days: 6)), note: 'sale'),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get incomeTotal => _transactions.where((t) => t.amount > 0).fold(0.0, (a, b) => a + b.amount);

  double get expenseTotal => _transactions.where((t) => t.amount < 0).fold(0.0, (a, b) => a + (-b.amount));

  double get balance => incomeTotal - expenseTotal;

  Map<String, double> get categoryExpenses {
    final Map<String, double> map = {};
    for (var t in _transactions) {
      if (t.amount < 0) {
        map[t.category] = (map[t.category] ?? 0) + (-t.amount);
      }
    }
    for (var c in _categoryColors.keys) {
      map.putIfAbsent(c, () => 0.0);
    }
    return map;
  }

  double get projectedBalance {
    final currentExpenses = expenseTotal;
    final reduced = currentExpenses * (1 - _forecastPercent);
    final newExpenses = reduced;
    return incomeTotal - newExpenses;
  }

  void _addTransaction(TransactionItem t) {
    setState(() {
      _transactions.insert(0, t);
      _controller.forward(from: 0.0);
    });
  }

  void _removeTransaction(String id) {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
      _controller.forward(from: 0.0);
    });
  }

  String _fmtCurrency(double v) {
    final sign = v < 0 ? '-' : '';
    final absVal = v.abs();
    return '$sign₹${absVal.toStringAsFixed(2)}';
  }

  void _openAddTransaction() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return AddTransactionSheet(
            categories: _categoryColors.keys.toList(),
            onAdd: (title, category, amount, isIncome, note) {
              final t = TransactionItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                category: category,
                amount: isIncome ? amount : -amount,
                date: DateTime.now(),
                note: note,
              );
              _addTransaction(t);
              Navigator.of(ctx).pop();
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final catData = categoryExpenses;
    final totalExpense = catData.values.fold(0.0, (a, b) => a + b);
    final topCategories = catData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_chart),
            tooltip: 'Quick Demo Add Income/Expense',
            onPressed: () {
              final sample = TransactionItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Quick ${_rng.nextInt(99)}',
                category: ['Food', 'Transport', 'Shopping', 'Bills', 'Other'][_rng.nextInt(5)],
                amount: _rng.nextBool() ? 150.0 : -(_rng.nextInt(300) + 30).toDouble(),
                date: DateTime.now(),
                note: 'Demo',
              );
              _addTransaction(sample);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        backgroundColor: Color(0xFF4DD0E1),
        child: Icon(Icons.add, color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: SummaryCard(
                  label: 'Balance',
                  value: _fmtCurrency(balance),
                  accent: Color(0xFFFFF59D),
                )),
                SizedBox(width: 10),
                Expanded(
                    child: SummaryCard(
                  label: 'Income',
                  value: _fmtCurrency(incomeTotal),
                  accent: Color(0xFFA5D6A7),
                )),
                SizedBox(width: 10),
                Expanded(
                    child: SummaryCard(
                  label: 'Expenses',
                  value: _fmtCurrency(-expenseTotal).replaceFirst('-', ''),
                  accent: Color(0xFFFF8A80),
                )),
              ],
            ),

            SizedBox(height: 14),

            Card(
              color: Color(0xFF0F1114),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Spending by category', style: TextStyle(fontWeight: FontWeight.bold)),
                        Spacer(),
                        Text('Total: ${_fmtCurrency(-expenseTotal)}', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    SizedBox(height: 10),

                    Row(
                      children: [
                        SizedBox(
                          width: 180,
                          height: 160,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: DonutPainter(
                                  data: catData,
                                  colors: _categoryColors,
                                  animationValue: _controller.value,
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: topCategories.take(6).map((e) {
                              final color = _categoryColors[e.key] ?? Colors.white54;
                              final percent = totalExpense == 0 ? 0.0 : (e.value / totalExpense) * 100;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                                    SizedBox(width: 8),
                                    Expanded(child: Text(e.key, style: TextStyle(color: Colors.white70))),
                                    Text('${percent.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      ],
                    ),

                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.show_chart, color: Colors.white54),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Forecast: Reduce expenses by ${( _forecastPercent * 100 ).round()}%'),
                              Slider(
                                value: _forecastPercent,
                                min: 0,
                                max: 0.5,
                                divisions: 10,
                                label: '${(_forecastPercent * 100).round()}%',
                                onChanged: (v) {
                                  setState(() {
                                    _forecastPercent = v;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Projected', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(height: 6),
                            Text(_fmtCurrency(projectedBalance), style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            SizedBox(height: 14),

            Row(
              children: [
                Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text('${_transactions.length} items', style: TextStyle(color: Colors.white54)),
              ],
            ),
            SizedBox(height: 8),

            Expanded(
              child: _transactions.isEmpty
                  ? Center(child: Text('No transactions yet. Add one with +', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, i) {
                        final t = _transactions[i];
                        return Dismissible(
                          key: ValueKey(t.id),
                          background: Container(color: Colors.redAccent, padding: EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerLeft, child: Icon(Icons.delete, color: Colors.white)),
                          secondaryBackground: Container(color: Colors.redAccent, padding: EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.centerRight, child: Icon(Icons.delete, color: Colors.white)),
                          onDismissed: (_) => _removeTransaction(t.id),
                          child: TransactionCard(
                            transaction: t,
                            color: _categoryColors[t.category] ?? Colors.white24,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  SummaryCard({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF141519),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Icon(Icons.account_balance_wallet, color: accent)),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: Colors.white70)),
                SizedBox(height: 6),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            )
          ],
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  final TransactionItem transaction;
  final Color color;
  TransactionCard({required this.transaction, required this.color});

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}-${d.month}-${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Card(
        color: Color(0xFF0F1114),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color)),
          ),
          title: Text(transaction.title, style: TextStyle(color: Colors.white)),
          subtitle: Text('${transaction.category} • ${_formatDate(transaction.date)}', style: TextStyle(color: Colors.white54)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${isIncome ? '' : '-'}₹${transaction.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(color: isIncome ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
              if (transaction.note.isNotEmpty) SizedBox(height: 6),
              if (transaction.note.isNotEmpty) Text(transaction.note, style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final List<String> categories;
  final void Function(String title, String category, double amount, bool isIncome, String note) onAdd;
  AddTransactionSheet({required this.categories, required this.onAdd});

  @override
  _AddTransactionSheetState createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _category = '';
  double _amount = 0.0;
  bool _isIncome = false;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _category = widget.categories.isNotEmpty ? widget.categories.first : 'Other';
  }

  double? _parseAmount(String? s) {
    if (s == null) return null;
    final cleaned = s.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    return parsed;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    widget.onAdd(_title, _category, _amount, _isIncome, _note);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: BoxDecoration(color: Color(0xFF0C0D0F), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 12,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Add Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close))
                ],
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Title', filled: true, fillColor: Colors.white10),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
                onSaved: (v) => _title = v!.trim(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Amount (₹)', filled: true, fillColor: Colors.white10),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final parsed = _parseAmount(v);
                        if (parsed == null) return 'Enter valid amount';
                        return null;
                      },
                      onSaved: (v) => _amount = _parseAmount(v) ?? 0.0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    children: [
                      Text('Type', style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 6),
                      ToggleButtons(
                        isSelected: [_isIncome, !_isIncome],
                        onPressed: (idx) {
                          setState(() {
                            _isIncome = idx == 0;
                          });
                        },
                        children: [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Income')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Expense'))],
                      )
                    ],
                  )
                ],
              ),
              DropdownButtonFormField<String>(
                value: _category,
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
                decoration: InputDecoration(labelText: 'Category', filled: true, fillColor: Colors.white10),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Note (optional)', filled: true, fillColor: Colors.white10),
                onSaved: (v) => _note = v?.trim() ?? '',
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4DD0E1)),
                        child: Text('Add Transaction')),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final Map<String, Color> colors;
  final double animationValue;

  DonutPainter({required this.data, required this.colors, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) * 0.45;
    final innerRadius = outerRadius * 0.6;

    final rect = Rect.fromCircle(center: center, radius: outerRadius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = outerRadius - innerRadius..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;
    if (total <= 0.0001) {
      paint.color = Colors.white10;
      canvas.drawArc(rect, 0, 2 * pi * animationValue, false, paint);
      return;
    }

    for (var entry in data.entries) {
      final value = entry.value;
      final sweep = (value / total) * 2 * pi * animationValue;
      paint.shader = null;
      paint.color = colors[entry.key] ?? Colors.white24;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    final innerPaint = Paint()..color = Color(0xFF0B0C10);
    canvas.drawCircle(center, innerRadius - 2, innerPaint);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final totalText = '₹${(total).toStringAsFixed(0)}';
    tp.text = TextSpan(text: totalText, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.animationValue != animationValue;
}
