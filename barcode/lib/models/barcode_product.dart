class BarcodeProduct {
  final String barcode;
  final String name;
  final double price;
  final String format;
  int quantity;

  BarcodeProduct({
    required this.barcode,
    required this.name,
    required this.price,
    required this.format,
    this.quantity = 1,
  });

  Map<String, Object?> toJson() => {
    'barcode': barcode,
    'name': name,
    'price': price,
    'format': format,
  };

  factory BarcodeProduct.fromJson(String barcode, Map<dynamic, dynamic> json) {
    final priceValue = json['price'];

    return BarcodeProduct(
      barcode: (json['barcode'] ?? barcode).toString(),
      name: (json['name'] ?? 'Unknown product').toString(),
      price: priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue?.toString() ?? '') ?? 0,
      format: (json['format'] ?? 'unknown').toString(),
    );
  }
}
