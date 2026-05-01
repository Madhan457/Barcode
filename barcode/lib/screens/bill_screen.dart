import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../models/bill_history.dart';
import '../services/firestore_service.dart';

class BillScreen extends StatelessWidget {
  const BillScreen({super.key});

  Future<void> _saveBillToHistory(List items, double total) async {
    final billNumber =
        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final bill = BillHistory(
      id: billNumber,
      date: DateTime.now(),
      items: items.cast(),
      total: total,
    );

    await FirestoreService().saveBill(bill);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final items = cartProvider.getCartSnapshot();

    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });
      return const SizedBox();
    }

    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
    final subtotal =
        items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final tax = subtotal * 0.05;
    final total = subtotal + tax;
    final billNumber =
        '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now = DateTime.now();
    final dateStr =
        '${now.day} ${_getMonthName(now.month)} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF1f2937)]
                : [const Color(0xFFecfdf5), const Color(0xFFdbeafe)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text('Back', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1f2937) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10b981), Color(0xFF2563eb)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Payment Success!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bill $billNumber',
                                  style: const TextStyle(
                                    color: Color(0xFF86efac),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Date
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Date & Time',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),

                                // Items Header
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Item',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text('Qty × Price',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text('Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const Divider(height: 24),

                                // Items List
                                ...items.map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${item.quantity} × ₹${item.price}',
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                          const SizedBox(width: 12),
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),

                                const Divider(height: 32, thickness: 2),

                                // Totals
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal'),
                                    Text('₹${subtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax (5%)'),
                                    Text('₹${tax.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '₹${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563eb),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Stats Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF374151)
                                        : const Color(0xFFf3f4f6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Items',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      Text(
                                        '$totalItems',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        Icons.print,
                                        'Print',
                                        const Color(0xFF3b82f6),
                                        () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Print dialog opened')),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildActionButton(
                                        Icons.download,
                                        'Save PDF',
                                        const Color(0xFF9333ea),
                                        () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Receipt saved as PDF')),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildActionButton(
                                        Icons.share,
                                        'Share',
                                        const Color(0xFF10b981),
                                        () => ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Sharing receipt')),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // New Bill Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await _saveBillToHistory(items, total);
                                      if (!context.mounted) return;
                                      cartProvider.clearCart();
                                      Navigator.pushReplacementNamed(
                                          context, '/main');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3b82f6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'New Bill',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
