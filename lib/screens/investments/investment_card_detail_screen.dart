import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/investment_card_model.dart';
import 'investments_screen.dart';

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
              Navigator.pop(ctx); // Close dialog
              widget.onCardDeleted();
              Navigator.pop(context); // Go back to investment list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Transaction?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this transaction entry?',
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
                widget.card.transactions.removeAt(index);
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
                          '\$${widget.card.totalInvested.toStringAsFixed(2)}',
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
                          '\$${widget.card.avgBuyPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
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
                'Swipe or tap bin to delete',
                style: TextStyle(fontSize: 11, color: Colors.white38),
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
            ...transactions.asMap().entries.map((entry) {
              final txIndex = widget.card.transactions.indexOf(entry.value);
              final tx = entry.value;
              final isBuy = tx.type == TransactionType.buy;
              final isSell = tx.type == TransactionType.sell;
              final dateStr = DateFormat('MMM dd, yyyy').format(tx.date);

              return Dismissible(
                key: Key(tx.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) {
                  setState(() {
                    widget.card.transactions.remove(tx);
                  });
                  widget.onStateChanged();
                },
                child: Container(
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
                            '${tx.quantity % 1 == 0 ? tx.quantity.toInt() : tx.quantity} shares @ \$${tx.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '\$${tx.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                        onPressed: () => _confirmDeleteTransaction(txIndex),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
