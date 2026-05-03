import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../models/bill_history.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/pdf_service.dart';

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  bool _isPaymentFinished = false;
  bool _isProcessing = false;
  BillHistory? _completedBill;

  Future<void> _completeBilling(
      List<dynamic> items, double total, int totalItems) async {
    setState(() => _isProcessing = true);
    try {
      final billNumber =
          '#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final bill = BillHistory(
        id: billNumber,
        date: DateTime.now(),
        items: items.cast(),
        total: total,
      );

      await FirestoreService().saveBillWithStats(bill, totalItems);
      setState(() {
        _isPaymentFinished = true;
        _isProcessing = false;
        _completedBill = bill;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        NotificationService.showTopNotification(
          context,
          'Error saving bill: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handlePrint(BuildContext context) async {
    if (_completedBill == null) return;

    try {
      final userData = await FirestoreService().getUserDataStream().first;
      final pdfBytes =
          await PdfService.generateBillPdf(_completedBill!, userData);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Bill_${_completedBill!.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showTopNotification(
          context,
          'Error generating PDF: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    if (_completedBill == null) return;

    try {
      final userData = await FirestoreService().getUserDataStream().first;
      final pdfBytes =
          await PdfService.generateBillPdf(_completedBill!, userData);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Bill_${_completedBill!.id}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Bill from Quick Bill - ${_completedBill!.id}',
        text: 'Sharing receipt for Bill ${_completedBill!.id}',
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showTopNotification(
          context,
          'Error sharing PDF: $e',
          isError: true,
        );
      }
    }
  }

  void _showPaymentQR(BuildContext context, double total, List<dynamic> items,
      int totalItems) async {
    final userData = await FirestoreService().getUserDataStream().first;
    final upiId = userData?['upiId'];

    if (upiId == null || upiId == 'Not Set') {
      if (!mounted) return;
      NotificationService.showTopNotification(
        context,
        'Please set your UPI ID in Profile first',
        isError: true,
      );
      return;
    }

    final upiUrl =
        'upi://pay?pa=$upiId&pn=Merchant&am=${total.toStringAsFixed(2)}&cu=INR';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner, color: Color(0xFF06B6D4), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan & Pay',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Merchant: ${userData?['name'] ?? 'Quick Bill Store'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: upiUrl,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1e293b),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            upiId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: upiId));
                                NotificationService.showTopNotification(context, 'UPI ID copied to clipboard');
                            },
                            child: const Icon(Icons.copy, size: 16, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF06B6D4)),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildUpiAppLogo('GPay', 'assets/images/gpay.png'),
                  const SizedBox(width: 20),
                  _buildUpiAppLogo('PhonePe', 'assets/images/phonepe.png'),
                  const SizedBox(width: 20),
                  _buildUpiAppLogo('Paytm', 'assets/images/paytm.png'),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _completeBilling(items, total, totalItems);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF10b981).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 12),
                      Text(
                        'Payment Received',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUpiAppLogo(String label, String assetPath) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final items = cartProvider.getCartSnapshot();

    if (items.isEmpty && !_isPaymentFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/main');
      });
      return const SizedBox();
    }

    final totalItems = items.fold(0, (sum, item) => sum + item.quantity);
    final subtotal =
        items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final total = subtotal;
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
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF84CC16),
                                  const Color(0xFF06B6D4)
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _isPaymentFinished
                                      ? Icons.check_circle
                                      : Icons.receipt_long,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isPaymentFinished
                                      ? 'Billing Finished!'
                                      : 'Bill Summary',
                                  style: const TextStyle(
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
                                         color: Color(0xFF06B6D4),
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

                                if (!_isPaymentFinished) ...[
                                  // Payment Buttons
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : () => _showPaymentQR(
                                              context, total, items, totalItems),
                                      icon: const Icon(Icons.qr_code),
                                      label: Text(
                                        _isProcessing
                                            ? 'Processing...'
                                            : 'Pay via UPI QR',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF06B6D4),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton.icon(
                                      onPressed: _isProcessing
                                          ? null
                                          : () => _completeBilling(
                                              items, total, totalItems),
                                      icon: const Icon(Icons.money),
                                      label: const Text(
                                        'Pay via Cash',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10b981),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 8,
                                        shadowColor: const Color(0xFF10b981).withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Payment Complete View
                                  const Text(
                                    'Payment Complete!',
                                    style: TextStyle(
                                        color: Color(0xFF10b981),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          Icons.print,
                                          'Print',
                                          const Color(0xFF3b82f6),
                                          () => _handlePrint(context),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildActionButton(
                                          Icons.share,
                                          'Share',
                                          const Color(0xFF10b981),
                                          () => _handleShare(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        cartProvider.clearCart();
                                        Navigator.pushReplacementNamed(
                                            context, '/main');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF10b981),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
