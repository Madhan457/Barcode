import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/barcode_product.dart';

class RealtimeProductService {
  RealtimeProductService({FirebaseDatabase? database})
      : _database = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: _databaseUrl,
            );

  static const String _databaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: 'https://barcode-scanner-f32fe-default-rtdb.firebaseio.com',
  );
  final FirebaseDatabase _database;

  DatabaseReference get _productsRef => _database.ref('products');

  Future<BarcodeProduct?> getProduct(String barcode) async {
    final snapshot = await _productsRef.child(_databaseKey(barcode)).get();
    if (!snapshot.exists || snapshot.value == null) {
      return null;
    }

    final value = snapshot.value;
    if (value is Map<dynamic, dynamic>) {
      return BarcodeProduct.fromJson(barcode, value);
    }

    throw const FormatException('Product data has an invalid format.');
  }

  Future<void> saveProduct(BarcodeProduct product) async {
    await _productsRef.child(_databaseKey(product.barcode)).set(product.toJson());
  }

  String _databaseKey(String barcode) {
    final hasInvalidKeyCharacter = RegExp(r'[.#$/\[\]]').hasMatch(barcode);
    if (!hasInvalidKeyCharacter) {
      return barcode;
    }

    return 'encoded_${base64Url.encode(utf8.encode(barcode))}';
  }
}
