import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_history.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _billsRef {
    final uid = _userId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('bills');
  }

  Future<void> saveBill(BillHistory bill) async {
    final ref = _billsRef;
    if (ref == null) throw Exception('User not authenticated');

    await ref.doc(bill.id).set(bill.toJson());
  }

  Future<void> saveBillWithStats(BillHistory bill, int totalItems) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');

    final userDoc = _db.collection('users').doc(uid);
    final billDoc = userDoc.collection('bills').doc(bill.id);

    await _db.runTransaction((transaction) async {
      transaction.set(billDoc, bill.toJson());
      transaction.set(userDoc, {
        'totalRevenue': FieldValue.increment(bill.total),
        'totalItemsSold': FieldValue.increment(totalItems),
        'totalBills': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
  }

  Stream<Map<String, dynamic>?> getUserDataStream() {
    final uid = _userId;
    if (uid == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updateUpiId(String upiId) async {
    final uid = _userId;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'upiId': upiId,
    }, SetOptions(merge: true));
  }

  CollectionReference<Map<String, dynamic>>? get _productsRef {
    final uid = _userId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('products');
  }

  // Fetch product details by barcode ID
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final ref = _productsRef;
    if (ref == null) return null;
    final doc = await ref.doc(barcode).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Add a new product to the database
  Future<void> addProduct({
    required String barcode,
    required String name,
    required double mrp,
  }) async {
    final ref = _productsRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(barcode).set({
      'name': name,
      'mrp': mrp,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch all products for the current user
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    final ref = _productsRef;
    if (ref == null) return Stream.value([]);
    return ref.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include the barcode as id
        return data;
      }).toList();
    });
  }

  // Update an existing product
  Future<void> updateProduct({
    required String barcode,
    required String name,
    required double mrp,
  }) async {
    final ref = _productsRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(barcode).update({
      'name': name,
      'mrp': mrp,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a product
  Future<void> deleteProduct(String barcode) async {
    final ref = _productsRef;
    if (ref == null) throw Exception('User not authenticated');
    await ref.doc(barcode).delete();
  }

  Stream<List<BillHistory>> getBillsStream() {
    final ref = _billsRef;
    if (ref == null) return Stream.value([]);

    return ref.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BillHistory.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> deleteBill(String id) async {
    final ref = _billsRef;
    if (ref == null) return;

    await ref.doc(id).delete();
  }

  Future<void> clearAllBills() async {
    final ref = _billsRef;
    if (ref == null) return;

    final snapshot = await ref.get();
    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
