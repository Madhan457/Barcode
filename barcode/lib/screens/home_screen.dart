import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  CartItem? _currentProduct;
  AnimationController? _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanLineController?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // Show scanned code in Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scanned: $code'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final productData = await FirestoreService().getProductByBarcode(code);

      if (!mounted) return;

      if (productData != null) {
        setState(() {
          _currentProduct = CartItem(
            id: code,
            name: productData['name'] ?? 'Unknown',
            price: (productData['mrp'] ?? 0).toDouble(),
            quantity: 1,
          );
        });
      } else {
        _showAddProductDialog(code);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      // Small delay to prevent immediate re-scan
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  void _showAddProductDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text(
          'Barcode $barcode is not in our database. Would you like to add it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigation to an add product screen could go here
              Navigator.pop(context);
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF111827), const Color(0xFF1f2937)]
              : [const Color(0xFFf9fafb), const Color(0xFFdbeafe)],
        ),
      ),
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Scanner Box (With Camera Inside)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3b82f6), Color(0xFF9333ea)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3b82f6).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // The Real Camera
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleBarcode,
                    ),
                    // Overlay Box
                    _buildScannerOverlay(isDark),
                    // Bottom Label
                    Positioned(
                      bottom: 15,
                      left: 0,
                      right: 0,
                      child: Text(
                        _isProcessing
                            ? 'Processing...'
                            : 'Point Camera at Barcode',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Manual Barcode Input (The Gap)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1f2937) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFe5e7eb),
                  ),
                ),
                child: TextField(
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Or Enter Barcode Manually',
                    prefixIcon: Icon(Icons.edit, color: Color(0xFF3b82f6)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _handleBarcode(
                        BarcodeCapture(barcodes: [Barcode(rawValue: value)]),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Current Product Details
              if (_currentProduct != null)
                _buildScannedCard(isDark, cartProvider),
              const SizedBox(height: 16),

              // Cart Items
              if (cartProvider.items.isNotEmpty) ...[
                const Text(
                  'Cart Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...cartProvider.items.map(
                  (item) => _buildCartItem(item, cartProvider, isDark),
                ),
                const SizedBox(height: 120),
              ],
            ],
          ),

          // Bottom Summary
          if (cartProvider.items.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCartSummaryOverlay(isDark, cartProvider),
            ),
        ],
      ),
    );
  }

  Widget _buildCartSummaryOverlay(bool isDark, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items: ${cartProvider.totalItems}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ₹${cartProvider.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => cartProvider.clearCart(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                    ),
                    child: const Text('Finish Billing'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1f2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.quantity} x ₹${item.price}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          IconButton(
            onPressed: () => cartProvider.removeItem(item.id),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(bool isDark) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          AnimatedBuilder(
            animation: _scanLineController!,
            builder: (context, child) {
              return Positioned(
                top: 150 * _scanLineController!.value,
                left: 10,
                right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScannedCard(bool isDark, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF374151)
            : Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentProduct!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_currentProduct!.price}',
                      style: const TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      if (_currentProduct!.quantity > 1) {
                        _currentProduct!.quantity--;
                      }
                    }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${_currentProduct!.quantity}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _currentProduct!.quantity++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                cartProvider.addItem(_currentProduct!);
                setState(() => _currentProduct = null);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to cart')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
