import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_card_model.dart';

class InvestmentCardDetailScreen extends StatefulWidget {
  final InvestmentCardModel card;
  final VoidCallback onCardDeleted;
  final VoidCallback onStateChanged;

  const InvestmentCardDetailScreen({
    super.key,
    required this.card,
    required this.onCardDeleted,
    required this.onStateChanged,
  });

  @override
  State<InvestmentCardDetailScreen> createState() => _InvestmentCardDetailScreenState();
}

class _InvestmentCardDetailScreenState extends State<InvestmentCardDetailScreen> {
  void _confirmDeleteCard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Investment Card?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the investment card for ${widget.card.symbol}? All associated transactions will be removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCardDeleted();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _attemptDeleteTransaction(Transaction tx, int originalIndex) {
    final candidateList = List<Transaction>.from(widget.card.transactions);
    candidateList.removeAt(originalIndex);

    // Rule: If candidate list becomes empty, the card should not exist!
    if (candidateList.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Delete Last Transaction?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'A card cannot exist without any transactions. Deleting this last transaction will delete the entire investment card. Proceed?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                widget.onCardDeleted();
                Navigator.pop(context); // Exit detail screen
              },
              child: const Text('Delete Card', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Re-verify entire transaction history after deletion
    final error = InvestmentCardModel.validateTransactions(candidateList);
    if (error != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Cannot Delete Transaction', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(
            'Deleting this transaction breaks chronological integrity or dividend eligibility:\n\n$error',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm deletion and recalculate for zero fault
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Transaction?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this transaction entry? All dividend and portfolio values will be recalculated.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() {
                widget.card.transactions.removeAt(originalIndex);
                // Complete recalculation of entire history for no fault
                final recalculated = InvestmentCardModel.recalculateAllTransactions(widget.card.transactions);
                widget.card.transactions
                  ..clear()
                  ..addAll(recalculated);
              });
              widget.onStateChanged();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTransactionSheet(
        card: widget.card,
        onTransactionAdded: (tx) {
          setState(() {
            widget.card.transactions.add(tx);
            // Recalculate entire history for no fault
            final recalculated = InvestmentCardModel.recalculateAllTransactions(widget.card.transactions);
            widget.card.transactions
              ..clear()
              ..addAll(recalculated);
          });
          widget.onStateChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = widget.card.sortedTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.card.symbol} Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            tooltip: 'Delete Card',
            onPressed: _confirmDeleteCard,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        onPressed: _openAddTransactionModal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF0F172A),
                      child: Text(
                        widget.card.symbol.length > 3
                            ? widget.card.symbol.substring(0, 3)
                            : widget.card.symbol,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.card.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.card.companyName,
                            style: const TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Invested', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.card.totalInvested.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Total Shares', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.card.totalQuantity % 1 == 0 ? widget.card.totalQuantity.toInt() : widget.card.totalQuantity}',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Avg Price', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.card.avgBuyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.card.totalDividends > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Dividends Received', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        '₹${widget.card.totalDividends.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
                if (widget.card.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.card.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transactions Ledger Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions (${widget.card.transactions.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                'Date-wise ledger',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transactions List
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Text(
                'No transactions recorded for this stock.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          else
            ...transactions.map((tx) {
              final originalIndex = widget.card.transactions.indexOf(tx);
              final isBuy = tx.type == TransactionType.buy;
              final isSell = tx.type == TransactionType.sell;
              final isDividend = tx.type == TransactionType.dividend;
              final dateStr = DateFormat('MMM dd, yyyy').format(tx.date);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isBuy
                                ? const Color(0xFF10B981)
                                : (isSell ? const Color(0xFFEF4444) : const Color(0xFF6366F1)))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBuy
                              ? const Color(0xFF10B981)
                              : (isSell ? const Color(0xFFEF4444) : const Color(0xFF6366F1)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDividend
                              ? '${tx.quantity % 1 == 0 ? tx.quantity.toInt() : tx.quantity} eligible shares @ ₹${tx.price.toStringAsFixed(2)} DPS'
                              : '${tx.quantity % 1 == 0 ? tx.quantity.toInt() : tx.quantity} shares @ ₹${tx.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: Colors.white54),
                        ),
                        if (isDividend && tx.exDividendDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ex-Date: ${DateFormat('dd MMM yyyy').format(tx.exDividendDate!)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF6366F1)),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '₹${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                      tooltip: 'Delete transaction',
                      onPressed: () => _attemptDeleteTransaction(tx, originalIndex),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final InvestmentCardModel card;
  final Function(Transaction) onTransactionAdded;

  const AddTransactionSheet({super.key, required this.card, required this.onTransactionAdded});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  TransactionType _type = TransactionType.buy;
  DateTime _date = DateTime.now(); // For Trade: transaction date. For Dividend: payment date.
  DateTime _exDividendDate = DateTime.now(); // For Dividend: ex-dividend cutoff date.
  final TextEditingController _priceCtrl = TextEditingController(); // Buy/Sell price or DPS
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  double _autoEligibleQty = 0.0;

  @override
  void initState() {
    super.initState();
    _recomputeDividendEligibility();
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _recomputeDividendEligibility() {
    if (_type == TransactionType.dividend) {
      final eligible = InvestmentCardModel.getEligibleQuantityOnDate(
        widget.card.transactions,
        _exDividendDate,
      );
      setState(() {
        _autoEligibleQty = eligible;
        _qtyCtrl.text = eligible % 1 == 0 ? eligible.toInt().toString() : eligible.toString();
      });
      _calculateAmount();
    }
  }

  void _calculateAmount() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    if (_type == TransactionType.dividend) {
      if (price > 0 && _autoEligibleQty > 0) {
        _amountCtrl.text = (price * _autoEligibleQty).toStringAsFixed(2);
      }
    } else {
      final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
      if (price > 0 && qty > 0) {
        _amountCtrl.text = (price * qty).toStringAsFixed(2);
      }
    }
  }

  Future<void> _pickDate({required bool isExDate}) async {
    final initial = isExDate ? _exDividendDate : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isExDate) {
          _exDividendDate = picked;
          _recomputeDividendEligibility();
        } else {
          _date = picked;
        }
      });
    }
  }

  void _submit() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

    if (_type == TransactionType.dividend) {
      // Dividend validation: DPS > 0, eligible qty > 0, ex-date <= payment date
      if (price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid dividend per share (DPS)')),
        );
        return;
      }

      if (_autoEligibleQty <= 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Dividend Ineligible', style: TextStyle(color: Colors.white)),
            content: Text(
              'No eligible stock holding found for ${widget.card.symbol} on ex-dividend date (${DateFormat('dd MMM yyyy').format(_exDividendDate)}). Dividends cannot exist without active stock holdings on the ex-date.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }

      final dividendAmount = price * _autoEligibleQty;
      final candidateTx = Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.dividend,
        date: _date,
        price: price, // DPS
        quantity: _autoEligibleQty, // auto-calculated
        amount: dividendAmount, // auto-calculated
        exDividendDate: _exDividendDate,
      );

      widget.onTransactionAdded(candidateTx);
      Navigator.pop(context);
      return;
    }

    // Trade (BUY / SELL) validation
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? (price * qty);

    if (price <= 0 || qty <= 0 || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid transaction numbers')),
      );
      return;
    }

    final candidateTx = Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      date: _date,
      price: price,
      quantity: qty,
      amount: amount,
    );

    // Re-verify entire candidate history chronologically
    final candidateList = List<Transaction>.from(widget.card.transactions)..add(candidateTx);
    final validationError = InvestmentCardModel.validateTransactions(candidateList);

    if (validationError != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Transaction Error', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Text(validationError, style: const TextStyle(color: Colors.white70)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    widget.onTransactionAdded(candidateTx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDividend = _type == TransactionType.dividend;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Transaction (${widget.card.symbol})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Transaction Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.buy, label: Text('BUY')),
                ButtonSegment(value: TransactionType.sell, label: Text('SELL')),
                ButtonSegment(value: TransactionType.dividend, label: Text('DIVIDEND')),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() {
                  _type = set.first;
                });
                _recomputeDividendEligibility();
              },
            ),
            const SizedBox(height: 16),

            // DIVIDEND FLOW: Ex-Dividend Date + Payment Date + DPS + Auto Eligible Shares
            if (isDividend) ...[
              // Ex-Dividend Date selector
              const Text(
                'Ex-Dividend Date (Holding Cutoff)',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  alignment: Alignment.centerLeft,
                  side: const BorderSide(color: Color(0xFF334155)),
                  backgroundColor: const Color(0xFF0F172A),
                ),
                onPressed: () => _pickDate(isExDate: true),
                icon: const Icon(Icons.event_available, size: 16, color: Color(0xFF6366F1)),
                label: Text(
                  DateFormat('dd MMM yyyy').format(_exDividendDate),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              // Payment Date selector
              const Text(
                'Payment Date',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  alignment: Alignment.centerLeft,
                  side: const BorderSide(color: Color(0xFF334155)),
                  backgroundColor: const Color(0xFF0F172A),
                ),
                onPressed: () => _pickDate(isExDate: false),
                icon: const Icon(Icons.payment, size: 16, color: Colors.white70),
                label: Text(
                  DateFormat('dd MMM yyyy').format(_date),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              // Dividend Per Share (DPS)
              TextField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculateAmount(),
                decoration: const InputDecoration(
                  labelText: 'Dividend Per Share - DPS (₹)',
                  hintText: 'e.g. 10.50',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Automatically Calculated Eligible Quantity Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _autoEligibleQty > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Eligible Shares on Ex-Date',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_autoEligibleQty % 1 == 0 ? _autoEligibleQty.toInt() : _autoEligibleQty} Shares',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _autoEligibleQty > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    if (_autoEligibleQty <= 0)
                      const Text(
                        '0 holding on ex-date',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Automatically Calculated Total Dividend Payout
              TextField(
                controller: _amountCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Total Dividend Payout (₹) (DPS × Eligible Shares)',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              // TRADE FLOW: BUY / SELL
              // Date picker
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  alignment: Alignment.centerLeft,
                  side: const BorderSide(color: Color(0xFF334155)),
                  backgroundColor: const Color(0xFF0F172A),
                ),
                onPressed: () => _pickDate(isExDate: false),
                icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                label: Text(
                  DateFormat('dd MMM yyyy').format(_date),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),

              // Price & Quantity
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateAmount(),
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateAmount(),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        filled: true,
                        fillColor: Color(0xFF0F172A),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Amount
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Total Transaction Amount (₹)',
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _submit,
                child: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
