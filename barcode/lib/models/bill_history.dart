import 'cart_item.dart';

class BillHistory {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double total;

  BillHistory({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'total': total,
      };

  factory BillHistory.fromJson(Map<String, dynamic> json) => BillHistory(
        id: json['id'],
        date: DateTime.parse(json['date']),
        items: (json['items'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList(),
        total: json['total'].toDouble(),
      );
}
