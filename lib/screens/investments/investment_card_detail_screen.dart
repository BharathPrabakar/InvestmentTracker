import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_card_model.dart';
import '../../services/yahoo_finance_service.dart';

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
  double? _livePrice;
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    _fetchLivePrice();
  }

  Future<void> _fetchLivePrice() async {
    setState(() {
      _isLoadingPrice = true;
    });
    final price = await YahooFinanceService.fetchCurrentPrice(widget.card.symbol);
    if (mounted) {
      setState(() {
        _livePrice = price;
        _isLoadingPrice = false;
      });
    }
  }
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

  void _openEditTagsDialog() {
    final tagCtrl = TextEditingController();
    final currentTags = List<String>.from(widget.card.tags);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void addTag() {
            final text = tagCtrl.text.trim().replaceAll('#', '');
            if (text.isNotEmpty && !currentTags.contains(text)) {
              setDialogState(() {
                currentTags.add(text);
                tagCtrl.clear();
              });
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text('Edit Tags (${widget.card.symbol})', style: const TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagCtrl,
                          onSubmitted: (_) => addTag(),
                          decoration: const InputDecoration(
                            hintText: 'Add new tag...',
                            filled: true,
                            fillColor: Color(0xFF0F172A),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: addTag,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (currentTags.isEmpty)
                    const Text('No tags assigned.', style: TextStyle(color: Colors.white38, fontSize: 13))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentTags
                          .map(
                            (tag) => Chip(
                              backgroundColor: const Color(0xFF0F172A),
                              label: Text('#$tag', style: const TextStyle(color: Colors.white)),
                              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                              onDeleted: () {
                                setDialogState(() {
                                  currentTags.remove(tag);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                onPressed: () {
                  setState(() {
                    widget.card.tags
                      ..clear()
                      ..addAll(currentTags);
                  });
                  widget.onStateChanged();
                  Navigator.pop(ctx);
                },
                child: const Text('Save Tags', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEditTransactionModal(Transaction tx, int originalIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TransactionFormSheet(
        card: widget.card,
        initialTransaction: tx,
        onTransactionSaved: (updatedTx) {
          // Re-verify entire transaction history with updated transaction
          final candidateList = List<Transaction>.from(widget.card.transactions);
          candidateList[originalIndex] = updatedTx;

          final error = InvestmentCardModel.validateTransactions(candidateList);
          if (error != null) {
            showDialog(
              context: context,
              builder: (dCtx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                    SizedBox(width: 8),
                    Text('Invalid Edit', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                content: Text(error, style: const TextStyle(color: Colors.white70)),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    onPressed: () => Navigator.pop(dCtx),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return;
          }

          setState(() {
            widget.card.transactions[originalIndex] = updatedTx;
            // Complete zero-fault recalculation
            final recalculated = InvestmentCardModel.recalculateAllTransactions(widget.card.transactions);
            widget.card.transactions
              ..clear()
              ..addAll(recalculated);
          });
          widget.onStateChanged();
          Navigator.pop(ctx);
        },
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
                Navigator.pop(ctx);
                widget.onCardDeleted();
                Navigator.pop(context);
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
      builder: (ctx) => TransactionFormSheet(
        card: widget.card,
        onTransactionSaved: (tx) {
          final candidateList = List<Transaction>.from(widget.card.transactions)..add(tx);
          final validationError = InvestmentCardModel.validateTransactions(candidateList);

          if (validationError != null) {
            showDialog(
              context: context,
              builder: (dCtx) => AlertDialog(
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
                    onPressed: () => Navigator.pop(dCtx),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return;
          }

          setState(() {
            widget.card.transactions.add(tx);
            final recalculated = InvestmentCardModel.recalculateAllTransactions(widget.card.transactions);
            widget.card.transactions
              ..clear()
              ..addAll(recalculated);
          });
          widget.onStateChanged();
          Navigator.pop(ctx);
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
            icon: const Icon(Icons.label_outline, color: Color(0xFF10B981)),
            tooltip: 'Edit Tags',
            onPressed: _openEditTagsDialog,
          ),
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
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),

                // Live Market Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Current Market Price',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        if (_isLoadingPrice)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF10B981)),
                          )
                        else
                          InkWell(
                            onTap: _fetchLivePrice,
                            child: const Icon(Icons.refresh, size: 14, color: Color(0xFF10B981)),
                          ),
                      ],
                    ),
                    Text(
                      _livePrice != null
                          ? '₹${_livePrice!.toStringAsFixed(2)}'
                          : (widget.card.latestPrice > 0
                              ? '₹${widget.card.latestPrice.toStringAsFixed(2)} (Last)'
                              : 'N/A'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF334155)),
                const SizedBox(height: 12),

                // 4-Card Basic Details Grid inside card: Total Investment, Realized P/L, Unrealized P/L, Total Dividends
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Investment', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.card.totalInvested.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Realized P/L', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.card.realizedPnL >= 0 ? '+' : ''}₹${widget.card.realizedPnL.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: widget.card.realizedPnL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Unrealized P/L', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 4),
                        Builder(builder: (ctx) {
                          final priceToUse = _livePrice ?? widget.card.latestPrice;
                          final openQty = widget.card.totalQuantity;
                          final openVal = openQty * priceToUse;
                          final costBasis = openQty * widget.card.avgBuyPrice;
                          final uPnL = openQty > 0 ? (openVal - costBasis) : 0.0;
                          return Text(
                            '${uPnL >= 0 ? '+' : ''}₹${uPnL.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: uPnL >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          );
                        }),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Dividends', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.card.totalDividends.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shares: ${widget.card.totalQuantity % 1 == 0 ? widget.card.totalQuantity.toInt() : widget.card.totalQuantity}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Avg Buy Price: ₹${widget.card.avgBuyPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tags', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                if (widget.card.tags.isEmpty)
                  const Text('No tags assigned.', style: TextStyle(color: Colors.white30, fontSize: 12))
                else
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
                'Tap pencil to edit',
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
                    Expanded(
                      child: Column(
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
                    ),
                    Text(
                      '₹${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                      tooltip: 'Edit transaction',
                      onPressed: () => _openEditTransactionModal(tx, originalIndex),
                    ),
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

class TransactionFormSheet extends StatefulWidget {
  final InvestmentCardModel card;
  final Transaction? initialTransaction;
  final Function(Transaction) onTransactionSaved;

  const TransactionFormSheet({
    super.key,
    required this.card,
    this.initialTransaction,
    required this.onTransactionSaved,
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late TransactionType _type;
  late DateTime _date;
  late DateTime _exDividendDate;
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  double _autoEligibleQty = 0.0;

  @override
  void initState() {
    super.initState();
    final init = widget.initialTransaction;
    if (init != null) {
      _type = init.type;
      _date = init.date;
      _exDividendDate = init.exDividendDate ?? init.date;
      _priceCtrl.text = init.price.toStringAsFixed(2);
      _qtyCtrl.text = init.quantity % 1 == 0 ? init.quantity.toInt().toString() : init.quantity.toString();
      _amountCtrl.text = init.amount.toStringAsFixed(2);
      if (_type == TransactionType.dividend) {
        _recomputeDividendEligibility();
      }
    } else {
      _type = TransactionType.buy;
      _date = DateTime.now();
      _exDividendDate = DateTime.now();
      _recomputeDividendEligibility();
    }
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
      // Create list excluding the transaction being edited (if editing) to determine true prior holding
      final historyToEvaluate = widget.initialTransaction != null
          ? widget.card.transactions.where((t) => t.id != widget.initialTransaction!.id).toList()
          : widget.card.transactions;

      final eligible = InvestmentCardModel.getEligibleQuantityOnDate(
        historyToEvaluate,
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
              'No eligible stock holding found for ${widget.card.symbol} prior to ex-dividend date (${DateFormat('dd MMM yyyy').format(_exDividendDate)}). Shares purchased on or after ex-date are not eligible.',
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
      final tx = Transaction(
        id: widget.initialTransaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
        type: TransactionType.dividend,
        date: _date,
        price: price,
        quantity: _autoEligibleQty,
        amount: dividendAmount,
        exDividendDate: _exDividendDate,
      );

      widget.onTransactionSaved(tx);
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

    final tx = Transaction(
      id: widget.initialTransaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      date: _date,
      price: price,
      quantity: qty,
      amount: amount,
    );

    widget.onTransactionSaved(tx);
  }

  @override
  Widget build(BuildContext context) {
    final isDividend = _type == TransactionType.dividend;
    final isEditing = widget.initialTransaction != null;

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
                  isEditing
                      ? 'Edit Transaction (${widget.card.symbol})'
                      : 'Add Transaction (${widget.card.symbol})',
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
              const Text(
                'Ex-Dividend Date (Holding Cutoff - On Ex-Date is NOT eligible)',
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
                          'Eligible Shares (Held Before Ex-Date)',
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
                        '0 holding before ex-date',
                        style: TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

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
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Transaction',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
