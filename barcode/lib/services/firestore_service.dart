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

  // Fetch product details by barcode ID
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final doc = await _db.collection('products').doc(barcode).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Stream<List<BillHistory>> getBillsStream() {
    final ref = _billsRef;
    if (ref == null) return Stream.value([]);

    return ref.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BillHistory.fromJson(doc.data())).toList();
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
